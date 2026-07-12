use rand::Rng;
use crate::engine::types::*;
use crate::engine::params::GameParams;

/// Process weekly training for a team.
/// Boosts player attributes based on training_focus and training_intensity.
pub fn process_training(team: &mut Team, params: &GameParams) -> f32 {
    let intensity = params.training_boost_for(&team.training_intensity);
    let mut total_boost = 0.0;
    let mut trained_count = 0u32;

    for player in team.players.iter_mut() {
        if player.injury_days > 0 {
            continue; // injured players don't train
        }

        let attrs = &mut player.attributes;
        let boost = intensity * 0.01; // scale intensity to attribute points

        match team.training_focus {
            TrainingFocus::Shooting => {
                attrs.three_pt   = (attrs.three_pt   + params.training_shooting_three * boost).min(99.0);
                attrs.mid_range  = (attrs.mid_range  + params.training_shooting_mid   * boost).min(99.0);
                attrs.free_throw = (attrs.free_throw + params.training_shooting_mid   * boost * 0.5).min(99.0);
            }
            TrainingFocus::Defense => {
                attrs.perimeter_def     = (attrs.perimeter_def     + params.training_defense_perim    * boost).min(99.0);
                attrs.interior_def      = (attrs.interior_def      + params.training_defense_interior * boost).min(99.0);
                attrs.steal             = (attrs.steal             + params.training_defense_perim    * boost * 0.5).min(99.0);
                attrs.block             = (attrs.block             + params.training_defense_interior * boost * 0.5).min(99.0);
            }
            TrainingFocus::Playmaking => {
                attrs.passing      = (attrs.passing      + params.training_playmaking_pass   * boost).min(99.0);
                attrs.ball_handle  = (attrs.ball_handle  + params.training_playmaking_handle * boost).min(99.0);
                attrs.basketball_iq = (attrs.basketball_iq + params.training_playmaking_pass * boost * 0.3).min(99.0);
            }
            TrainingFocus::Physical => {
                attrs.stamina = (attrs.stamina + params.training_physical_stamina * boost).min(99.0);
                attrs.speed   = (attrs.speed   + params.training_physical_speed   * boost).min(99.0);
                attrs.jumping = (attrs.jumping + params.training_physical_speed   * boost * 0.5).min(99.0);
                attrs.strength = (attrs.strength + params.training_physical_stamina * boost * 0.3).min(99.0);
            }
            TrainingFocus::Balanced => {
                attrs.three_pt    = (attrs.three_pt   + params.training_balanced_all * boost).min(99.0);
                attrs.mid_range   = (attrs.mid_range  + params.training_balanced_all * boost).min(99.0);
                attrs.perimeter_def = (attrs.perimeter_def + params.training_balanced_all * boost).min(99.0);
                attrs.passing     = (attrs.passing     + params.training_balanced_all * boost).min(99.0);
                attrs.stamina     = (attrs.stamina     + params.training_balanced_all * boost).min(99.0);
            }
        }

        // Track total boost for this player (sum of all changed attrs)
        total_boost += boost;
        trained_count += 1;

        // Stamina cost of training
        player.attributes.stamina = (player.attributes.stamina - params.stamina_training_fatigue * intensity).max(params.stamina_min);
    }

    if trained_count > 0 {
        total_boost / trained_count as f32
    } else {
        0.0
    }
}

/// Update morale after a game for the entire team.
pub fn update_morale_after_game(team: &mut Team, won: bool, params: &GameParams) {
    for player in team.players.iter_mut() {
        if won {
            player.morale = (player.morale + params.morale_win_bonus).min(params.morale_max);
        } else {
            player.morale = (player.morale - params.morale_loss_penalty).max(params.morale_min);
        }
    }
}

/// Weekly morale decay towards natural target.
pub fn weekly_morale_decay(team: &mut Team, params: &GameParams) {
    for player in team.players.iter_mut() {
        if player.morale > params.morale_natural_target {
            player.morale = (player.morale - params.morale_decay_per_week).max(params.morale_natural_target);
        } else if player.morale < params.morale_natural_target {
            player.morale = (player.morale + params.morale_decay_per_week).min(params.morale_natural_target);
        }
    }
}

/// Reduce stamina after a game.
pub fn stamina_after_game(team: &mut Team, params: &GameParams) {
    for player in team.players.iter_mut() {
        if player.injury_days > 0 { continue; }
        player.attributes.stamina = (player.attributes.stamina - params.stamina_game_fatigue).max(params.stamina_min);
    }
}

/// Weekly stamina recovery.
pub fn weekly_stamina_recovery(team: &mut Team, params: &GameParams) {
    for player in team.players.iter_mut() {
        if player.injury_days > 0 { continue; }
        player.attributes.stamina = (player.attributes.stamina + params.stamina_base_recovery).min(params.stamina_max);
    }
}

/// Check for injuries after a game.
/// Returns a vec of (player_id, days_out) for newly injured players.
pub fn check_injuries(team: &mut Team, params: &GameParams) -> Vec<(u32, u8)> {
    let mut rng = rand::thread_rng();
    let mut injuries = Vec::new();

    for player in team.players.iter_mut() {
        if player.injury_days > 0 {
            player.injury_days = player.injury_days.saturating_sub(7); // heal 7 days per week
            continue;
        }

        // Check if stamina is low enough to risk injury
        if player.attributes.stamina < params.injury_stamina_threshold {
            if rng.gen_bool(params.injury_probability) {
                let days = rng.gen_range(params.injury_min_days..=params.injury_max_days);
                player.injury_days = days;
                injuries.push((player.id, days));
            }
        }
    }

    injuries
}

/// Process all weekly team systems at once (training + recovery + morale decay + injuries).
/// Called at the end of each week.
pub fn process_weekly_team_systems(
    league: &mut League,
    params: &GameParams,
) -> Vec<(u32, String, u8)> {
    let mut all_injuries = Vec::new();

    for team in league.teams.iter_mut() {
        // 1. Stamina recovery
        weekly_stamina_recovery(team, params);

        // 2. Morale decay towards natural target
        weekly_morale_decay(team, params);

        // 3. Training (boost attributes)
        process_training(team, params);

        // 4. Injury check
        let injuries = check_injuries(team, params);
        for (pid, days) in &injuries {
            // Find player name for logging
            let pname = team.players.iter()
                .find(|p| p.id == *pid)
                .map(|p| format!("{} {}", p.first_name, p.last_name))
                .unwrap_or_else(|| format!("Player#{}", pid));
            all_injuries.push((team.id, pname, *days));
        }
    }

    all_injuries
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_test_team(id: u32) -> Team {
        let mut used = std::collections::HashSet::new();
        let mut team = Team::generate(id, "Test", "City", "TST", 70.0, &mut used);
        // Set all players morale to 50 for predictable tests
        for p in team.players.iter_mut() {
            p.morale = 50.0;
            p.attributes.stamina = 80.0;
        }
        team.training_intensity = "ALTA".to_string();
        team.training_focus = TrainingFocus::Shooting;
        team
    }

    #[test]
    fn test_training_boosts_shooting() {
        let mut team = make_test_team(1);
        let params = GameParams::default();

        let three_before = team.players[0].attributes.three_pt;
        let mid_before = team.players[0].attributes.mid_range;

        process_training(&mut team, &params);

        // Shooting should have improved
        assert!(team.players[0].attributes.three_pt > three_before);
        assert!(team.players[0].attributes.mid_range > mid_before);
    }

    #[test]
    fn test_morale_win_loss() {
        let mut team = make_test_team(1);
        let params = GameParams::default();

        update_morale_after_game(&mut team, true, &params);
        assert!(team.players[0].morale > 50.0);

        update_morale_after_game(&mut team, false, &params);
        update_morale_after_game(&mut team, false, &params);
        // Should be back to ~50 or lower
        assert!(team.players[0].morale <= 50.0 + params.morale_loss_penalty);
    }

    #[test]
    fn test_stamina_game_and_recovery() {
        let mut team = make_test_team(1);
        let params = GameParams::default();

        let before = team.players[0].attributes.stamina;
        stamina_after_game(&mut team, &params);
        assert!(team.players[0].attributes.stamina < before);

        weekly_stamina_recovery(&mut team, &params);
        assert!(team.players[0].attributes.stamina > before - params.stamina_game_fatigue);
    }

    #[test]
    fn test_injury_at_low_stamina() {
        let mut team = make_test_team(1);
        let params = GameParams::default();

        // Set stamina very low
        for p in team.players.iter_mut() {
            p.attributes.stamina = 5.0;
        }

        // Multiple attempts to increase chance
        let mut total_injuries = 0;
        for _ in 0..100 {
            let mut clone = team.clone();
            let injuries = check_injuries(&mut clone, &params);
            total_injuries += injuries.len();
        }

        // At least some injuries should have occurred
        assert!(total_injuries > 0, "Expected at least one injury in 100 trials at low stamina");
    }

    #[test]
    fn test_weekly_systems_full_cycle() {
        let mut league = {
            let t1 = make_test_team(1);
            let t2 = make_test_team(2);
            League {
                teams: vec![t1, t2],
                schedule: Vec::new(),
                current_week: 1,
                season: 2025,
                playoffs_active: false,
                playoff_series: Vec::new(),
                events: Vec::new(),
            }
        };
        let params = GameParams::default();

        let injuries = process_weekly_team_systems(&mut league, &params);

        // Training should have improved attributes
        assert!(league.teams[0].players[0].attributes.three_pt > 50.0);

        // Morale should be moving towards natural target
        for p in &league.teams[0].players {
            assert!(p.morale >= params.morale_min && p.morale <= params.morale_max);
        }

        // injuries is just informational
        println!("Injuries this week: {:?}", injuries);
    }
}
