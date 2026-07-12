use rand::Rng;
use crate::engine::types::*;
use crate::engine::params::GameParams;

/// Unique ID counter for transactions (global, for the league).
pub type TransactionIdGen = std::sync::atomic::AtomicU32;

/// Process recurring weekly finances for all teams in the league.
/// Called at the end of each week (after games are played).
pub fn process_weekly_finances(
    league: &mut League,
    params: &GameParams,
    txn_id_gen: &TransactionIdGen,
) {
    for team in league.teams.iter_mut() {
        // ── Salaries (52 weeks) ──
        let weekly_salary = team.finances.total_salary / 52.0;
        add_transaction(team, txn_id_gen, -weekly_salary, "SALARY",
            &format!("Salário semanal (${:.0}/ano)", team.finances.total_salary));

        // ── Staff cost ──
        add_transaction(team, txn_id_gen, -params.weekly_staff_cost, "STAFF",
            "Custo semanal da comissão técnica");

        // ── Travel cost (away games) ──
        // Estimate based on number of away games this week
        let away_games_this_week: u32 = league.schedule.iter()
            .filter(|g| g.week == league.current_week && g.away_team == team.id && !g.played)
            .count() as u32;
        if away_games_this_week > 0 {
            let travel = away_games_this_week as f64 * params.travel_cost_per_game;
            add_transaction(team, txn_id_gen, -travel, "TRAVEL",
                &format!("Custo de viagem ({} jogo(s) fora)", away_games_this_week));
        }

        // ── TV rights (weekly portion) ──
        let weekly_tv = params.tv_rights_monthly / 4.0;
        add_transaction(team, txn_id_gen, weekly_tv, "TV_RIGHTS",
            "Direitos de transmissão (semanal)");

        // ── Merchandising (weekly portion) ──
        let weekly_merch = params.merchandising_base_monthly / 4.0;
        add_transaction(team, txn_id_gen, weekly_merch, "MERCHANDISING",
            "Merchandising (semanal)");

        // ── Sponsor income (weekly portion) ──
        for sponsor in &team.sponsors.clone() {
            let weekly_sponsor = sponsor.amount_per_year / 52.0;
            add_transaction(team, txn_id_gen, weekly_sponsor, "SPONSOR",
                &format!("Patrocínio: {}", sponsor.name));
        }

        // ── Recalculate projected totals ──
        let weeks_remaining = (22u16 - league.current_week).max(1) as f64;
        team.finances.projected_revenue = weekly_tv * weeks_remaining
            + weekly_merch * weeks_remaining
            + team.sponsors.iter().map(|s| s.amount_per_year / 52.0 * weeks_remaining).sum::<f64>()
            + team.wins as f64 * 300_000.0; // ticket bonus for wins

        team.finances.projected_expenses = (weekly_salary + params.weekly_staff_cost) * weeks_remaining
            + params.travel_cost_per_game * (22 - league.current_week) as f64;

        // ── Weekly summary ──
        team.finances.total_salary = team.players.iter().map(|p| p.salary as f64).sum();
        team.finances.weekly_revenue = weekly_tv + weekly_merch
            + team.sponsors.iter().map(|s| s.amount_per_year / 52.0).sum::<f64>();
        team.finances.weekly_expenses = weekly_salary + params.weekly_staff_cost
            + away_games_this_week as f64 * params.travel_cost_per_game;
    }
}

/// Process financial impact of a single game for the home team.
/// Called after each game is simulated.
pub fn process_game_finances(
    league: &mut League,
    game: &ScheduledGame,
    home_score: u16,
    away_score: u16,
    params: &GameParams,
    txn_id_gen: &TransactionIdGen,
) {
    // Home team ticket revenue
    let home_team = league.teams.iter_mut().find(|t| t.id == game.home_team);
    if let Some(home) = home_team {
        let attendance = params.attendance_base as f64
            + (params.attendance_variance as f64 * 0.5) // average attendance
            + (home.chemistry as f64 * params.ticket_price_per_chem);
        let attendance = attendance.clamp(3000.0, 25_000.0) as u32;

        let ticket_revenue = attendance as f64 * params.ticket_base_price;
        add_transaction(home, txn_id_gen, ticket_revenue, "TICKET",
            &format!("Bilheteria ({} torcedores, {:.0} vs {})",
                attendance, home_score, game.away_team));

        // Win bonus (home team wins = more fans = more merch next week)
        if home_score > away_score {
            let win_bonus = ticket_revenue * 0.1;
            add_transaction(home, txn_id_gen, win_bonus, "TICKET",
                "Bônus de vitória (bilheteria +10%)");
        }
    }

    // Away team travel cost
    let away_team = league.teams.iter_mut().find(|t| t.id == game.away_team);
    if let Some(away) = away_team {
        add_transaction(away, txn_id_gen, -params.travel_cost_per_game, "TRAVEL",
            &format!("Viagem para {} ({:.0} x {})", game.home_team, away_score, home_score));
    }
}

/// Process end-of-season prize money.
pub fn process_season_prizes(
    league: &mut League,
    params: &GameParams,
    txn_id_gen: &TransactionIdGen,
) {
    if league.playoff_series.is_empty() {
        return;
    }

    // Find the champion (last completed series = finals)
    if let Some(finals) = league.playoff_series.iter().find(|s| s.round == PlayoffRound::Finals) {
        if let Some(winner) = finals.winner {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == winner) {
                add_transaction(team, txn_id_gen, params.prize_pool_winner, "PRIZE",
                    "Prêmio de campeão da temporada");
            }
            // Runner-up is the other team in the finals
            let runner_up = if winner == finals.higher_seed { finals.lower_seed } else { finals.higher_seed };
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == runner_up) {
                add_transaction(team, txn_id_gen, params.prize_pool_runner_up, "PRIZE",
                    "Vice-campeão da temporada");
            }
        }
    }
}

/// Generate initial sponsors for a team at the start of a new game/season.
pub fn generate_sponsors(
    team: &mut Team,
    params: &GameParams,
    txn_id_gen: &TransactionIdGen,
) {
    let mut rng = rand::thread_rng();
    let count = rng.gen_range(params.sponsor_min_count..=params.sponsor_max_count);

    let sponsor_names = [
        ("FlyEM", "Airlines"),
        ("TechBank", "Finance"),
        ("SportMax", "Sportswear"),
        ("CidadePrev", "Insurance"),
        ("MegaEnergy", "Energy"),
        ("SuperFit", "Fitness"),
        ("DriveOn", "Automotive"),
        ("FoodZilla", "Food"),
        ("GameTech", "Technology"),
        ("VidaSaúde", "Healthcare"),
    ];

    for i in 0..count {
        let idx = rng.gen_range(0..sponsor_names.len());
        let (name, category) = sponsor_names[idx];
        let years = rng.gen_range(params.sponsor_years_min..=params.sponsor_years_max);
        let amount = rng.gen_range(1_000_000.0..8_000_000.0) * years as f64;

        let sponsor_id = txn_id_gen.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        team.sponsors.push(Sponsor {
            id: sponsor_id,
            team_id: team.id,
            name: name.to_string(),
            amount_per_year: amount / years as f64,
            years_remaining: years,
            total_years: years,
            category: category.to_string(),
        });

        // Record the sponsorship as income
        add_transaction(team, txn_id_gen, amount, "SPONSOR",
            &format!("Patrocínio: {} ({}) - {} anos", name, category, years));
    }
}

// ── Helpers ──

fn add_transaction(
    team: &mut Team,
    id_gen: &TransactionIdGen,
    amount: f64,
    category: &str,
    description: &str,
) {
    let txn_id = id_gen.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    team.finances.budget += amount;
    team.transactions.push(Transaction {
        id: txn_id,
        team_id: team.id,
        amount,
        category: category.to_string(),
        description: description.to_string(),
        week: 0, // will be set by caller
        season: 0,
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::AtomicU32;

    fn make_test_team(id: u32) -> Team {
        let mut used = std::collections::HashSet::new();
        let mut team = Team::generate(id, "Test", "City", "TST", 70.0, &mut used);
        team.finances.budget = 100_000_000.0;
        team.finances.total_salary = team.players.iter().map(|p| p.salary as f64).sum();
        team
    }

    fn make_test_league() -> League {
        let t1 = make_test_team(1);
        let t2 = make_test_team(2);
        League {
            teams: vec![t1, t2],
            schedule: vec![ScheduledGame {
                id: 1, home_team: 1, away_team: 2,
                week: 1, played: false, is_playoff: false,
                home_score: None, away_score: None,
            }],
            current_week: 1,
            season: 2025,
            playoffs_active: false,
            playoff_series: Vec::new(),
            events: Vec::new(),
        }
    }

    #[test]
    fn test_weekly_finances_reduces_budget() {
        let mut league = make_test_league();
        let params = GameParams::default();
        let txn_gen = AtomicU32::new(1000);

        let initial_budget = league.teams[0].finances.budget;
        process_weekly_finances(&mut league, &params, &txn_gen);

        // Budget should have changed (expenses deducted, income added)
        assert!(league.teams[0].finances.budget != initial_budget);
        assert!(league.teams[0].finances.weekly_revenue > 0.0);
        assert!(league.teams[0].finances.weekly_expenses > 0.0);
        assert!(league.teams[0].transactions.len() > 2);
    }

    #[test]
    fn test_game_finances_ticket_revenue() {
        let mut league = make_test_league();
        let params = GameParams::default();
        let txn_gen = AtomicU32::new(1000);

        let game = ScheduledGame {
            id: 1, home_team: 1, away_team: 2,
            week: 1, played: true, is_playoff: false,
            home_score: Some(100), away_score: Some(90),
        };

        let budget_before = league.teams[0].finances.budget;
        process_game_finances(&mut league, &game, 100, 90, &params, &txn_gen);

        // Home team should have ticket revenue
        assert!(league.teams[0].finances.budget > budget_before);
        // Away team should have travel cost
        assert!(league.teams[1].finances.budget < 100_000_000.0);
    }

    #[test]
    fn test_generate_sponsors() {
        let mut team = make_test_team(1);
        let params = GameParams::default();
        let txn_gen = AtomicU32::new(1000);

        generate_sponsors(&mut team, &params, &txn_gen);

        assert!(team.sponsors.len() >= params.sponsor_min_count as usize);
        assert!(team.sponsors.len() <= params.sponsor_max_count as usize);
        assert!(team.transactions.len() >= params.sponsor_min_count as usize);
    }

    #[test]
    fn test_season_prizes() {
        let mut league = make_test_league();
        let params = GameParams::default();
        let txn_gen = AtomicU32::new(1000);

        league.playoff_series.push(PlayoffSeries {
            round: PlayoffRound::Finals,
            series_id: 0,
            higher_seed: 1,
            lower_seed: 2,
            higher_seed_wins: 0,
            lower_seed_wins: 0,
            completed: true,
            winner: Some(1),
        });

        let budget_before = league.teams[0].finances.budget;
        process_season_prizes(&mut league, &params, &txn_gen);

        assert!(league.teams[0].finances.budget > budget_before);
    }
}
