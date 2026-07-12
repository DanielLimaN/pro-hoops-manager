use godot::prelude::*;
use std::sync::Mutex;
use std::sync::atomic::AtomicU32;
use std::sync::atomic::Ordering::Relaxed;
use rand::Rng;
use crate::engine::*;
use crate::state::GameState;
use crate::bridge::convert::*;
use crate::worker::{SimCommand, SimulationWorker};

#[derive(GodotClass)]
#[class(base=RefCounted)]
pub struct BasketballEngine {
    state: Mutex<GameState>,
    simulator: Mutex<Option<MatchSimulator>>,
    pending_games: Vec<usize>,
    pending_idx: usize,
    worker: Mutex<Option<SimulationWorker>>,
    txn_id_counter: AtomicU32,

    base: Base<RefCounted>,
}

#[godot_api]
impl BasketballEngine {
    #[signal]
    fn match_tick(event: VarDictionary);
    
    #[signal]
    fn stats_updated(data: VarDictionary);

    #[signal]
    fn day_advanced(current_date: GString);

    #[func]
    fn new_game(&self, coach_name: GString, team_id: i64, focus: GString) -> VarDictionary {
        let mut rng = rand::thread_rng();
        let team_names = vec![
            ("São Paulo", "Dragões", "SPD"),
            ("Rio de Janeiro", "Fênix", "RJF"),
            ("Belo Horizonte", "Trovões", "BHT"),
            ("Curitiba", "Lobos", "CWB"),
            ("Porto Alegre", "Águias", "POA"),
            ("Brasília", "Jaguars", "BSB"),
            ("Salvador", "Tubarões", "SSA"),
            ("Recife", "Corsários", "REC"),
            ("Fortaleza", "Leões", "FOR"),
            ("Manaus", "Guerreiros", "MAO"),
            ("Goiânia", "Cangurus", "GYN"),
            ("Florianópolis", "Tsunamis", "FLN"),
        ];

        let mut used_names = std::collections::HashSet::new();
        let all_focuses = [TrainingFocus::Shooting, TrainingFocus::Defense, TrainingFocus::Playmaking, TrainingFocus::Physical, TrainingFocus::Balanced];
        let teams: Vec<Team> = team_names.iter().enumerate().map(|(i, (city, name, abbr))| {
            let rating = rng.gen_range(50.0..95.0);
            let mut team = Team::generate(i as u32 + 1, name, city, abbr, rating, &mut used_names);
            team.training_focus = all_focuses[rng.gen_range(0..all_focuses.len())].clone();
            team
        }).collect();

        let mut schedule = Vec::new();
        let mut game_id = 1;
        let num_teams = teams.len();
        
        // Double round-robin: 22 weeks (turno e returno)
        let mut team_indices: Vec<usize> = (0..num_teams).collect();
        for week in 1..=22 {
            let is_return = week > 11;
            for i in 0..(num_teams / 2) {
                let t1 = team_indices[i];
                let t2 = team_indices[num_teams - 1 - i];
                
                // Return leg swaps home/away
                let (home_idx, away_idx) = if is_return {
                    if week % 2 == 0 { (t2, t1) } else { (t1, t2) }
                } else {
                    if week % 2 == 0 { (t1, t2) } else { (t2, t1) }
                };
                
                schedule.push(ScheduledGame {
                    id: game_id,
                    home_team: teams[home_idx].id,
                    away_team: teams[away_idx].id,
                    week: week as u16,
                    played: false,
                    is_playoff: false,
                    home_score: None,
                    away_score: None,
                });
                game_id += 1;
            }
            // Rotate all elements except the first one
            let last = team_indices.pop().unwrap();
            team_indices.insert(1, last);
        }

        let mut league = League {
            teams, schedule, current_week: 1, season: 2025,
            playoffs_active: false, playoff_series: Vec::new(),
            events: Vec::new(),
        };
        
        let coach = crate::engine::manager::CoachProfile {
            id: 1,
            team_id: team_id as u32,
            name: coach_name.to_string(),
            focus: focus.to_string(),
            reputation: 50,
        };
        
        let staff = vec![
            crate::engine::manager::Staff { id: 1, team_id: team_id as u32, name: "Carlos Silva".to_string(), role: "Assistant Coach".to_string(), skill_level: 65 },
            crate::engine::manager::Staff { id: 2, team_id: team_id as u32, name: "Roberto Santos".to_string(), role: "Physio".to_string(), skill_level: 70 },
            crate::engine::manager::Staff { id: 3, team_id: team_id as u32, name: "Ana Costa".to_string(), role: "Scout".to_string(), skill_level: 75 },
        ];
        
        let mut inbox = vec![
            crate::engine::manager::InboxMessage {
                id: 1,
                coach_id: 1,
                sender_name: "Board of Directors".to_string(),
                sender_role: "Chairman".to_string(),
                subject: "Welcome to the Club".to_string(),
                body: format!("Welcome aboard, {}! We are thrilled to have you as our new Head Coach. Our expectations for this season are to reach the playoffs. You have a budget of $120M. Good luck!", coach_name.to_string()),
                read: false,
                date_received: "2025-10-01".to_string(),
                action_required: false,
            }
        ];

        // ── Generate sponsors for all teams ──
        for team in league.teams.iter_mut() {
            let default_params = crate::engine::params::GameParams::default();
            crate::engine::finance::generate_sponsors(team, &default_params, &self.txn_id_counter);
        }

        let mut game = self.state.lock().unwrap();
        game.league = Some(league.clone());
        game.user_team_id = Some(team_id as u32);
        game.coach = Some(coach);
        game.staff = staff;
        game.inbox = inbox;

        league_to_dict(&league)
    }

    #[func]
    fn start_match(&self, home_id: i64, away_id: i64) {
        let game = self.state.lock().unwrap();
        let league = match game.league.as_ref() {
            Some(l) => l,
            None => { godot_error!("No league started"); return; }
        };

        let home = match league.teams.iter().find(|t| t.id == home_id as u32) {
            Some(t) => t.clone(),
            None => { godot_error!("Home team not found"); return; }
        };
        let away = match league.teams.iter().find(|t| t.id == away_id as u32) {
            Some(t) => t.clone(),
            None => { godot_error!("Away team not found"); return; }
        };

        let mut sim = MatchSimulator::new(home, away);
        std::fs::create_dir_all("logs").ok();
        sim.start_logging("logs/match.simlog", "logs/match.calibration.json");
        let mut match_sim = self.simulator.lock().unwrap();
        *match_sim = Some(sim);
    }

    #[func]
    fn sim_tick(&self) -> VarDictionary {
        let event = {
            let mut match_sim = self.simulator.lock().unwrap();
            let sim = match match_sim.as_mut() {
                Some(s) => s,
                None => {
                    godot_error!("No match in progress");
                    return VarDictionary::new();
                }
            };
            sim.tick()
        };

        match event {
            Some(evt) => event_to_dict(&evt),
            None => VarDictionary::new()
        }
    }

    fn simulate_game(
        schedule_idx: usize,
        league: &mut League,
        player_stats_delta: &mut std::collections::HashMap<u32, PlayerStats>,
    ) {
        let g = &league.schedule[schedule_idx];
        let home_id = g.home_team;
        let away_id = g.away_team;

        let home_team = league.teams.iter().find(|t| t.id == home_id).cloned().unwrap();
        let away_team = league.teams.iter().find(|t| t.id == away_id).cloned().unwrap();

        let mut sim = MatchSimulator::new(home_team.clone(), away_team.clone());
        sim.store_events = false;
        let events = sim.simulate_full();

        let final_home = sim.home_score;
        let final_away = sim.away_score;

        for p in home_team.players.iter().chain(away_team.players.iter()) {
            player_stats_delta.entry(p.id).or_default().games_played += 1;
        }

        let mut last_passer: Option<u32> = None;
        for evt in events {
            match evt.action {
                ActionType::Pass { from, .. } => { last_passer = Some(from); },
                ActionType::Shot { player, shot_type, result, .. } => {
                    let stats = player_stats_delta.entry(player).or_default();
                    if result == ShotResult::Made {
                        if shot_type == ShotType::ThreePointer { stats.points += 3.0; } else { stats.points += 2.0; }
                        if let Some(passer) = last_passer {
                            if passer != player { player_stats_delta.entry(passer).or_default().assists += 1.0; }
                        }
                    }
                    last_passer = None;
                },
                ActionType::Rebound { player, .. } => { player_stats_delta.entry(player).or_default().rebounds += 1.0; last_passer = None; },
                ActionType::Steal { defender, .. } => { player_stats_delta.entry(defender).or_default().steals += 1.0; last_passer = None; },
                ActionType::Block { defender, .. } => { player_stats_delta.entry(defender).or_default().blocks += 1.0; },
                ActionType::Turnover { player, .. } => { player_stats_delta.entry(player).or_default().turnovers += 1.0; last_passer = None; },
                ActionType::FreeThrow { player, result } => {
                    if result == ShotResult::Made { player_stats_delta.entry(player).or_default().points += 1.0; }
                    last_passer = None;
                },
                _ => {}
            }
        }

        let schedule_game = &mut league.schedule[schedule_idx];
        schedule_game.played = true;
        schedule_game.home_score = Some(final_home);
        schedule_game.away_score = Some(final_away);

        let (home_win, away_win) = if final_home > final_away { (1, 0) } else { (0, 1) };
        for team in league.teams.iter_mut() {
            if team.id == home_id {
                team.wins += home_win;
                team.losses += away_win;
            } else if team.id == away_id {
                team.wins += away_win;
                team.losses += home_win;
            }
            for p in team.players.iter_mut() {
                if let Some(delta) = player_stats_delta.get(&p.id) {
                    p.stats_season.games_played += delta.games_played;
                    p.stats_season.points += delta.points;
                    p.stats_season.rebounds += delta.rebounds;
                    p.stats_season.assists += delta.assists;
                    p.stats_season.steals += delta.steals;
                    p.stats_season.blocks += delta.blocks;
                    p.stats_season.turnovers += delta.turnovers;
                }
            }
        }
    }

    fn generate_playoffs(league: &mut League) {
        league.playoffs_active = true;

        // Rank teams by wins (descending)
        let mut ranked: Vec<u32> = league.teams.iter().map(|t| t.id).collect();
        ranked.sort_by(|a, b| {
            let ta = league.teams.iter().find(|t| t.id == *a).unwrap();
            let tb = league.teams.iter().find(|t| t.id == *b).unwrap();
            tb.wins.cmp(&ta.wins)
        });

        let mut game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;

        // Standard bracket: 1v8, 4v5, 2v7, 3v6
        let matchups: [(usize, usize); 4] = [(0, 7), (3, 4), (1, 6), (2, 5)];

        for (i, &(hi, lo)) in matchups.iter().enumerate() {
            let higher = ranked[hi];
            let lower = ranked[lo];

            league.schedule.push(ScheduledGame {
                id: game_id,
                home_team: higher,
                away_team: lower,
                week: 23,
                played: false,
                is_playoff: true,
                home_score: None,
                away_score: None,
            });
            game_id += 1;

            league.playoff_series.push(PlayoffSeries {
                round: PlayoffRound::Quarterfinals,
                series_id: i as u32,
                higher_seed: higher,
                lower_seed: lower,
                higher_seed_wins: 0,
                lower_seed_wins: 0,
                completed: false,
                winner: None,
            });
        }
    }

    fn generate_semifinals(league: &mut League) {
        if league.playoff_series.iter().any(|s| s.round == PlayoffRound::Semifinals) {
            return;
        }

        let mut game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;

        let w_a1 = league.playoff_series[0].winner.unwrap();
        let w_a2 = league.playoff_series[1].winner.unwrap();
        let (home_a, away_a) = if w_a1 < w_a2 { (w_a1, w_a2) } else { (w_a2, w_a1) };

        league.schedule.push(ScheduledGame {
            id: game_id,
            home_team: home_a,
            away_team: away_a,
            week: 24,
            played: false,
            is_playoff: true,
            home_score: None,
            away_score: None,
        });
        game_id += 1;

        league.playoff_series.push(PlayoffSeries {
            round: PlayoffRound::Semifinals,
            series_id: 4,
            higher_seed: home_a,
            lower_seed: away_a,
            higher_seed_wins: 0,
            lower_seed_wins: 0,
            completed: false,
            winner: None,
        });

        let w_b1 = league.playoff_series[2].winner.unwrap();
        let w_b2 = league.playoff_series[3].winner.unwrap();
        let (home_b, away_b) = if w_b1 < w_b2 { (w_b1, w_b2) } else { (w_b2, w_b1) };

        league.schedule.push(ScheduledGame {
            id: game_id,
            home_team: home_b,
            away_team: away_b,
            week: 24,
            played: false,
            is_playoff: true,
            home_score: None,
            away_score: None,
        });

        league.playoff_series.push(PlayoffSeries {
            round: PlayoffRound::Semifinals,
            series_id: 5,
            higher_seed: home_b,
            lower_seed: away_b,
            higher_seed_wins: 0,
            lower_seed_wins: 0,
            completed: false,
            winner: None,
        });
    }

    fn generate_finals(league: &mut League) {
        if league.playoff_series.iter().any(|s| s.round == PlayoffRound::Finals) {
            return;
        }

        let game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;

        let w1 = league.playoff_series[4].winner.unwrap();
        let w2 = league.playoff_series[5].winner.unwrap();
        let (home, away) = if w1 < w2 { (w1, w2) } else { (w2, w1) };

        league.schedule.push(ScheduledGame {
            id: game_id,
            home_team: home,
            away_team: away,
            week: 25,
            played: false,
            is_playoff: true,
            home_score: None,
            away_score: None,
        });

        league.playoff_series.push(PlayoffSeries {
            round: PlayoffRound::Finals,
            series_id: 6,
            higher_seed: home,
            lower_seed: away,
            higher_seed_wins: 0,
            lower_seed_wins: 0,
            completed: false,
            winner: None,
        });
    }

    fn resolve_playoff_round(league: &mut League, week: u16) {
        for series in league.playoff_series.iter_mut() {
            if series.completed { continue; }
            let series_week: u16 = match series.round {
                PlayoffRound::Quarterfinals => 23,
                PlayoffRound::Semifinals => 24,
                PlayoffRound::Finals => 25,
            };
            if series_week != week { continue; }

            for g in &league.schedule {
                if g.week != week || !g.played { continue; }
                // Check if this game belongs to this series
                let involved = (g.home_team == series.higher_seed && g.away_team == series.lower_seed)
                    || (g.home_team == series.lower_seed && g.away_team == series.higher_seed);
                if !involved { continue; }

                let is_higher_home = g.home_team == series.higher_seed;
                let (higher_score, lower_score) = if is_higher_home {
                    (g.home_score, g.away_score)
                } else {
                    (g.away_score, g.home_score)
                };
                if let (Some(hs), Some(ls)) = (higher_score, lower_score) {
                    series.winner = Some(if hs > ls { series.higher_seed } else { series.lower_seed });
                    series.completed = true;
                }
                break;
            }
        }
    }

    #[func]
    fn sim_week(&mut self) -> bool {
        let (params, user_id) = {
            let g = self.state.lock().unwrap();
            (g.params.clone(), g.user_team_id.unwrap_or(0))
        };
        let mut game = self.state.lock().unwrap();
        let league = match game.league.as_mut() {
            Some(l) => l,
            None => return false,
        };

        let current_week = league.current_week;

        // Playoff setup & round generation
        if current_week >= 23 && !league.playoffs_active {
            Self::generate_playoffs(league);
        }
        if league.playoffs_active {
            if current_week == 24 { Self::generate_semifinals(league); }
            if current_week == 25 { Self::generate_finals(league); }
        }

        // Collect unplayed games for this week
        let mut games_to_sim: Vec<usize> = Vec::new();
        for (i, g) in league.schedule.iter().enumerate() {
            if g.week == current_week && !g.played {
                games_to_sim.push(i);
            }
        }

        if games_to_sim.is_empty() {
            league.current_week += 1;
            let next_week = league.current_week;
            drop(game);
            self.base_mut().emit_signal("day_advanced", &[
                GString::from(&format!("Week {}", next_week)).to_variant()
            ]);
            return false;
        }

        // Simulate all games for this week
        let mut all_deltas: std::collections::HashMap<u32, PlayerStats> = std::collections::HashMap::new();
        for &idx in &games_to_sim {
            Self::simulate_game(idx, league, &mut all_deltas);

            // Post-game: morale + stamina for both teams
            let sg_clone = league.schedule[idx].clone();
            if let (Some(hs), Some(aw)) = (sg_clone.home_score, sg_clone.away_score) {
                // Home team
                if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg_clone.home_team) {
                    crate::engine::systems::update_morale_after_game(team, hs > aw, &params);
                    crate::engine::systems::stamina_after_game(team, &params);
                }
                // Away team
                if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg_clone.away_team) {
                    crate::engine::systems::update_morale_after_game(team, aw > hs, &params);
                    crate::engine::systems::stamina_after_game(team, &params);
                }
                // Game finances
                crate::engine::finance::process_game_finances(
                    league, &sg_clone, hs, aw, &params, &self.txn_id_counter,
                );
            }
        }

        // Process weekly finances for all teams
        crate::engine::finance::process_weekly_finances(
            league, &params, &self.txn_id_counter,
        );

        // Process weekly team systems (training, recovery, morale decay, injuries)
        let injuries = crate::engine::systems::process_weekly_team_systems(league, &params);
        if !injuries.is_empty() {
            godot_print!("[Systems] Week {} injuries: {:?}", current_week, injuries);
        }

        league.current_week += 1;
        let next_week = league.current_week;

        // Resolve playoff bracket after simulation
        if league.playoffs_active {
            Self::resolve_playoff_round(league, current_week);
        }

        // Build stats dict with financial data
        let dict = Self::make_stats_dict(league, user_id);
        drop(game);
        self.base_mut().emit_signal("stats_updated", &[dict.to_variant()]);
        self.base_mut().emit_signal("day_advanced", &[
            GString::from(&format!("Week {}", next_week)).to_variant()
        ]);

        true
    }

    #[func]
    fn sim_next_game(&mut self) -> bool {
        let (params, user_id) = {
            let g = self.state.lock().unwrap();
            (g.params.clone(), g.user_team_id.unwrap_or(0))
        };
        let mut game = self.state.lock().unwrap();
        let league = match game.league.as_mut() {
            Some(l) => l,
            None => return false,
        };

        // If no pending games, populate for current week
        if self.pending_idx >= self.pending_games.len() {
            let current_week = league.current_week;

            // Playoff setup & round generation
            if current_week >= 23 && !league.playoffs_active {
                Self::generate_playoffs(league);
            }
            if league.playoffs_active {
                if current_week == 24 { Self::generate_semifinals(league); }
                if current_week == 25 { Self::generate_finals(league); }
            }

            // Collect unplayed games for current week
            self.pending_games.clear();
            for (i, g) in league.schedule.iter().enumerate() {
                if g.week == current_week && !g.played {
                    self.pending_games.push(i);
                }
            }

            if self.pending_games.is_empty() {
                // No games this week — advance to next
                league.current_week += 1;
                let next_week = league.current_week;
                drop(game);
                self.base_mut().emit_signal("day_advanced", &[
                    GString::from(&format!("Week {}", next_week)).to_variant()
                ]);
                return false;
            }

            self.pending_idx = 0;
        }

        // Simulate the next pending game
        let idx = self.pending_games[self.pending_idx];
        self.pending_idx += 1;
        let is_last = self.pending_idx >= self.pending_games.len();

        let mut all_deltas: std::collections::HashMap<u32, PlayerStats> = std::collections::HashMap::new();
        Self::simulate_game(idx, league, &mut all_deltas);

        // Post-game: morale + stamina + finances (clone sg to avoid borrow conflict)
        let sg = league.schedule[idx].clone();
        if let (Some(hs), Some(aw)) = (sg.home_score, sg.away_score) {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg.home_team) {
                crate::engine::systems::update_morale_after_game(team, hs > aw, &params);
                crate::engine::systems::stamina_after_game(team, &params);
            }
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg.away_team) {
                crate::engine::systems::update_morale_after_game(team, aw > hs, &params);
                crate::engine::systems::stamina_after_game(team, &params);
            }
            crate::engine::finance::process_game_finances(
                league, &sg, hs, aw, &params, &self.txn_id_counter,
            );
        };

        if is_last {
            // Process weekly finances for all teams
            crate::engine::finance::process_weekly_finances(
                league, &params, &self.txn_id_counter,
            );

            // Process weekly team systems (training, recovery, morale decay, injuries)
            let current_week = league.current_week;
            let injuries = crate::engine::systems::process_weekly_team_systems(league, &params);
            if !injuries.is_empty() {
                godot_print!("[Systems] Week {} injuries: {:?}", current_week, injuries);
            }

            let prev_week = league.current_week;
            league.current_week += 1;

            if league.playoffs_active {
                Self::resolve_playoff_round(league, prev_week);
            }

            let next_week = league.current_week;
            let stats = Self::make_stats_dict(league, user_id);
            drop(game);

            self.base_mut().emit_signal("stats_updated", &[stats.to_variant()]);
            self.base_mut().emit_signal("day_advanced", &[
                GString::from(&format!("Week {}", next_week)).to_variant()
            ]);
        } else {
            drop(game);
        }

        true
    }

    fn make_stats_dict(league: &League, user_id: u32) -> VarDictionary {
        let mut d = VarDictionary::new();
        if let Some(team) = league.teams.iter().find(|t| t.id == user_id) {
            d.set("wins", team.wins as i64);
            d.set("losses", team.losses as i64);
            d.set("budget", team.finances.budget);
            d.set("salary_cap", team.finances.salary_cap);
            d.set("total_salary", team.finances.total_salary);
            d.set("weekly_revenue", team.finances.weekly_revenue);
            d.set("weekly_expenses", team.finances.weekly_expenses);
            let avg_morale: f64 = if team.players.is_empty() { 100.0 } else {
                team.players.iter().map(|p| p.morale as f64).sum::<f64>() / team.players.len() as f64
            };
            d.set("morale", (avg_morale * 100.0).round() / 100.0);
            let avg_stamina: f64 = if team.players.is_empty() { 100.0 } else {
                team.players.iter().map(|p| p.attributes.stamina as f64).sum::<f64>() / team.players.len() as f64
            };
            d.set("energy", (avg_stamina * 100.0).round() / 100.0);
        } else {
            d.set("wins", 0i64);
            d.set("losses", 0i64);
            d.set("budget", 0f64);
            d.set("salary_cap", 0f64);
            d.set("total_salary", 0f64);
            d.set("weekly_revenue", 0f64);
            d.set("weekly_expenses", 0f64);
            d.set("morale", 100.0);
            d.set("energy", 100.0);
        }
        d
    }

    fn make_match_event(sg: &ScheduledGame, user_id: u32, league: &League) -> VarDictionary {
        let is_home = sg.home_team == user_id;
        let opp_id = if is_home { sg.away_team } else { sg.home_team };
        let opp_name: &str = league.teams.iter()
            .find(|t| t.id == opp_id)
            .map(|t| t.abbreviation.as_str())
            .unwrap_or("OPP");
        let h_score = sg.home_score.unwrap_or(0);
        let a_score = sg.away_score.unwrap_or(0);
        let won = (is_home && h_score > a_score) || (!is_home && a_score > h_score);
        let us_score = if is_home { h_score } else { a_score };
        let them_score = if is_home { a_score } else { h_score };

        let mut d = VarDictionary::new();
        d.set("event_type", "match_result");
        let title = if won { format!("Vitória sobre {}", opp_name) } else { format!("Derrota para {}", opp_name) };
        d.set("title", &GString::from(&title));
        let location = if is_home { "em casa" } else { "fora de casa" };
        let body = format!("{} {} por {} a {} contra {}", if won { "Seu time venceu" } else { "Seu time perdeu" }, location, us_score, them_score, opp_name);
        d.set("body", &GString::from(&body));
        d.set("severity", "info");
        d.set("sender_role", "Departamento de Imprensa");
        d.set("sender_name", "Imprensa do Clube");
        d
    }

    #[func]
    fn sim_day(&mut self) -> VarDictionary {
        let (params, user_id) = {
            let g = self.state.lock().unwrap();
            (g.params.clone(), g.user_team_id.unwrap_or(0))
        };
        let mut game = self.state.lock().unwrap();
        let league = match game.league.as_mut() {
            Some(l) => l,
            None => {
                drop(game);
                let mut d = VarDictionary::new();
                d.set("status", &GString::from("ERROR"));
                return d;
            }
        };

        // Pending games setup
        if self.pending_idx >= self.pending_games.len() {
            let current_week = league.current_week;

            if current_week >= 23 && !league.playoffs_active {
                Self::generate_playoffs(league);
            }
            if league.playoffs_active {
                if current_week == 24 { Self::generate_semifinals(league); }
                if current_week == 25 { Self::generate_finals(league); }
            }

            self.pending_games.clear();
            for (i, g) in league.schedule.iter().enumerate() {
                if g.week == current_week && !g.played {
                    self.pending_games.push(i);
                }
            }

            if self.pending_games.is_empty() {
                league.current_week += 1;
                let stats = Self::make_stats_dict(league, user_id);
                drop(game);
                let mut d = VarDictionary::new();
                d.set("events", &VarArray::new());
                d.set("stats", &stats);
                d.set("status", &GString::from("COMPLETED"));
                return d;
            }

            self.pending_idx = 0;
        }

        // Simulate the next pending game
        let idx = self.pending_games[self.pending_idx];
        self.pending_idx += 1;
        let is_last = self.pending_idx >= self.pending_games.len();

        let mut all_deltas: std::collections::HashMap<u32, PlayerStats> = std::collections::HashMap::new();
        Self::simulate_game(idx, league, &mut all_deltas);

        // Post-game: morale + stamina + finances (clone sg to avoid borrow conflict)
        let sg = league.schedule[idx].clone();
        if let (Some(hs), Some(aw)) = (sg.home_score, sg.away_score) {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg.home_team) {
                crate::engine::systems::update_morale_after_game(team, hs > aw, &params);
                crate::engine::systems::stamina_after_game(team, &params);
            }
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == sg.away_team) {
                crate::engine::systems::update_morale_after_game(team, aw > hs, &params);
                crate::engine::systems::stamina_after_game(team, &params);
            }
            crate::engine::finance::process_game_finances(
                league, &sg, hs, aw, &params, &self.txn_id_counter,
            );
        }

        // Build match event if user's team played
        let mut events = VarArray::new();
        if sg.home_team == user_id || sg.away_team == user_id {
            events.push(&Self::make_match_event(&sg, user_id, league));
        }

        if is_last {
            // Process weekly finances for all teams
            crate::engine::finance::process_weekly_finances(
                league, &params, &self.txn_id_counter,
            );

            // Process weekly team systems (training, recovery, morale decay, injuries)
            let current_week = league.current_week;
            let injuries = crate::engine::systems::process_weekly_team_systems(league, &params);
            if !injuries.is_empty() {
                godot_print!("[Systems] Week {} injuries: {:?}", current_week, injuries);
            }

            let prev_week = league.current_week;
            league.current_week += 1;
            if league.playoffs_active {
                Self::resolve_playoff_round(league, prev_week);
            }
        }

        let stats = Self::make_stats_dict(league, user_id);
        drop(game);

        let mut d = VarDictionary::new();
        d.set("events", &events);
        d.set("stats", &stats);
        d.set("status", &GString::from("COMPLETED"));
        d
    }

    #[func]
    fn get_team(&self, team_id: i64) -> VarDictionary {
        let game = self.state.lock().unwrap();
        let league = match game.league.as_ref() {
            Some(l) => l,
            None => {
                godot_error!("No league");
                return VarDictionary::new();
            }
        };
        match league.teams.iter().find(|t| t.id == team_id as u32) {
            Some(t) => team_to_dict(t),
            None => {
                godot_error!("Team not found");
                VarDictionary::new()
            }
        }
    }

    #[func]
    fn get_finances(&self, team_id: i64) -> VarDictionary {
        let game = self.state.lock().unwrap();
        let league = match game.league.as_ref() {
            Some(l) => l,
            None => {
                godot_error!("No league");
                return VarDictionary::new();
            }
        };
        match league.teams.iter().find(|t| t.id == team_id as u32) {
            Some(t) => {
                let mut d = VarDictionary::new();
                d.set("budget", t.finances.budget);
                d.set("total_salary", t.finances.total_salary);
                d.set("salary_cap", t.finances.salary_cap);
                d.set("projected_revenue", t.finances.projected_revenue);
                d.set("projected_expenses", t.finances.projected_expenses);
                d.set("weekly_revenue", t.finances.weekly_revenue);
                d.set("weekly_expenses", t.finances.weekly_expenses);
                d.set("budget_remaining", t.finances.salary_cap - t.finances.total_salary);
                d.set("cap_usage_pct", if t.finances.salary_cap > 0.0 {
                    (t.finances.total_salary / t.finances.salary_cap * 100.0 * 100.0).round() / 100.0
                } else { 0.0 });

                // Recent transactions (last 20)
                let mut txns = VarArray::new();
                for txn in t.transactions.iter().rev().take(20) {
                    let mut td = VarDictionary::new();
                    td.set("amount", txn.amount);
                    td.set("category", &GString::from(&txn.category));
                    td.set("description", &GString::from(&txn.description));
                    td.set("week", txn.week as i64);
                    td.set("season", txn.season as i64);
                    txns.push(&td);
                }
                d.set("transactions", &txns);

                // Sponsors
                let mut sp_arr = VarArray::new();
                for sp in &t.sponsors {
                    let mut sd = VarDictionary::new();
                    sd.set("name", &GString::from(&sp.name));
                    sd.set("amount_per_year", sp.amount_per_year);
                    sd.set("years_remaining", sp.years_remaining as i64);
                    sd.set("category", &GString::from(&sp.category));
                    sp_arr.push(&sd);
                }
                d.set("sponsors", &sp_arr);

                // Player salaries breakdown
                let mut salaries = VarArray::new();
                for p in &t.players {
                    let mut pd = VarDictionary::new();
                    pd.set("name", &GString::from(&format!("{} {}", p.first_name, p.last_name)));
                    pd.set("salary", p.salary as i64);
                    let pos_str = format!("{:?}", p.position);
                    pd.set("position", &GString::from(pos_str.as_str()));
                    salaries.push(&pd);
                }
                d.set("player_salaries", &salaries);

                d
            }
            None => {
                godot_error!("Team not found");
                VarDictionary::new()
            }
        }
    }

    #[func]
    fn get_league(&self) -> VarDictionary {
        let game = self.state.lock().unwrap();
        match game.league.as_ref() {
            Some(l) => league_to_dict(l),
            None => {
                godot_error!("No league");
                VarDictionary::new()
            }
        }
    }

    #[func]
    fn get_schedule(&self) -> VarArray {
        let game = self.state.lock().unwrap();
        match game.league.as_ref() {
            Some(l) => schedule_to_arr(&l.schedule),
            None => VarArray::new(),
        }
    }

    #[func]
    fn get_inbox(&self) -> VarArray {
        let game = self.state.lock().unwrap();
        let mut arr = VarArray::new();
        for msg in &game.inbox {
            let mut dict = VarDictionary::new();
            dict.set("id", msg.id as i64);
            dict.set("sender_name", &GString::from(&msg.sender_name));
            dict.set("sender_role", &GString::from(&msg.sender_role));
            dict.set("subject", &GString::from(&msg.subject));
            dict.set("body", &GString::from(&msg.body));
            dict.set("read", msg.read);
            dict.set("date_received", &GString::from(&msg.date_received));
            arr.push(&dict);
        }
        arr
    }

    #[func]
    fn get_staff(&self) -> VarArray {
        let game = self.state.lock().unwrap();
        let mut arr = VarArray::new();
        for s in &game.staff {
            let mut dict = VarDictionary::new();
            dict.set("id", s.id as i64);
            dict.set("name", &GString::from(&s.name));
            dict.set("role", &GString::from(&s.role));
            dict.set("skill_level", s.skill_level as i64);
            arr.push(&dict);
        }
        arr
    }

    #[func]
    fn get_coach(&self) -> VarDictionary {
        let game = self.state.lock().unwrap();
        let mut dict = VarDictionary::new();
        if let Some(ref coach) = game.coach {
            dict.set("name", &GString::from(&coach.name));
            dict.set("focus", &GString::from(&coach.focus));
            dict.set("reputation", coach.reputation as i64);
        }
        dict
    }

    #[func]
    fn set_tactic(&self, team_id: i64, tactic_dict: VarDictionary) {
        let tactic = tactic_from_dict(&tactic_dict);
        let mut game = self.state.lock().unwrap();
        if let Some(ref mut league) = game.league {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == team_id as u32) {
                team.tactic = tactic;
            }
        }
    }

    #[func]
    fn set_rotation_order(&self, team_id: i64, player_ids: VarArray) {
        let mut game = self.state.lock().unwrap();
        if let Some(ref mut league) = game.league {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == team_id as u32) {
                team.rotation_order = (0..player_ids.len()).map(|i| {
                    player_ids.get(i).and_then(|v| v.try_to::<i64>().ok()).unwrap_or(0) as u32
                }).collect();
                godot_print!("[Engine] rotation_order set for team {}: {:?}", team_id, team.rotation_order);
            }
        }
    }

    #[func]
    fn get_rotation_order(&self, team_id: i64) -> VarArray {
        let game = self.state.lock().unwrap();
        let mut arr = VarArray::new();
        if let Some(ref league) = game.league {
            if let Some(team) = league.teams.iter().find(|t| t.id == team_id as u32) {
                // If rotation_order is empty, return the auto-computed starter IDs
                let ids = if team.rotation_order.is_empty() {
                    team.starters().iter().map(|p| p.id).collect::<Vec<_>>()
                } else {
                    team.rotation_order.clone()
                };
                for pid in ids {
                    arr.push(pid as i64);
                }
            }
        }
        arr
    }

    #[func]
    fn get_user_team_id(&self) -> i64 {
        let game = self.state.lock().unwrap();
        game.user_team_id.unwrap_or(1) as i64
    }

    #[func]
    fn set_user_team_id(&self, team_id: i64) {
        let mut game = self.state.lock().unwrap();
        game.user_team_id = Some(team_id as u32);
    }

    #[func]
    fn set_training_focus(&self, focus: GString) {
        let focus_str = focus.to_string();
        let parsed = match focus_str.as_str() {
            "Shooting"   => TrainingFocus::Shooting,
            "Defense"    => TrainingFocus::Defense,
            "Playmaking" => TrainingFocus::Playmaking,
            "Physical"   => TrainingFocus::Physical,
            _            => TrainingFocus::Balanced,
        };
        let mut game = self.state.lock().unwrap();
        let user_id = game.user_team_id.unwrap_or(0);
        if let Some(ref mut league) = game.league {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == user_id) {
                team.training_focus = parsed;
                godot_print!("[Engine] training_focus set to {} for team {}", focus_str, team.id);
            }
        }
    }

    #[func]
    fn get_training_focus(&self) -> GString {
        let game = self.state.lock().unwrap();
        if let Some(ref league) = game.league {
            if let Some(team) = league.teams.iter().find(|t| t.id == game.user_team_id.unwrap_or(0)) {
                let s = match team.training_focus {
                    TrainingFocus::Shooting   => "Shooting",
                    TrainingFocus::Defense    => "Defense",
                    TrainingFocus::Playmaking => "Playmaking",
                    TrainingFocus::Physical   => "Physical",
                    TrainingFocus::Balanced   => "Balanced",
                };
                return GString::from(s);
            }
        }
        GString::from("Balanced")
    }

    #[func]
    fn set_training_intensity(&self, intensity: GString) {
        let intensity_str = intensity.to_string();
        let parsed = match intensity_str.as_str() {
            "BAIXA" | "LOW" => "BAIXA",
            "ALTA" | "HIGH" => "ALTA",
            _ => "MÉDIA",
        };
        let mut game = self.state.lock().unwrap();
        let user_id = game.user_team_id.unwrap_or(0);
        if let Some(ref mut league) = game.league {
            if let Some(team) = league.teams.iter_mut().find(|t| t.id == user_id) {
                team.training_intensity = parsed.to_string();
                godot_print!("[Engine] training_intensity set to {} for team {}", parsed, team.id);
            }
        }
    }

    #[func]
    fn get_training_intensity(&self) -> GString {
        let game = self.state.lock().unwrap();
        if let Some(ref league) = game.league {
            if let Some(team) = league.teams.iter().find(|t| t.id == game.user_team_id.unwrap_or(0)) {
                return GString::from(team.training_intensity.as_str());
            }
        }
        GString::from("MÉDIA")
    }

    #[func]
    fn get_training_status(&self, team_id: i64) -> VarDictionary {
        let game = self.state.lock().unwrap();
        let league = match game.league.as_ref() {
            Some(l) => l,
            None => return VarDictionary::new(),
        };
        match league.teams.iter().find(|t| t.id == team_id as u32) {
            Some(team) => {
                let mut d = VarDictionary::new();
                d.set("focus", &GString::from(match team.training_focus {
                    TrainingFocus::Shooting => "Shooting",
                    TrainingFocus::Defense => "Defense",
                    TrainingFocus::Playmaking => "Playmaking",
                    TrainingFocus::Physical => "Physical",
                    TrainingFocus::Balanced => "Balanced",
                }));
                d.set("intensity", &GString::from(team.training_intensity.as_str()));

                // Player training info
                let mut players_arr = VarArray::new();
                for p in &team.players {
                    let mut pd = VarDictionary::new();
                    pd.set("id", p.id as i64);
                    let name_str = format!("{} {}", p.first_name, p.last_name);
                    pd.set("name", &GString::from(name_str.as_str()));
                    let pos_str = format!("{:?}", p.position);
                    pd.set("position", &GString::from(pos_str.as_str()));
                    pd.set("morale", p.morale as f64);
                    pd.set("stamina", p.attributes.stamina as f64);
                    pd.set("overall", p.attributes.overall() as f64);
                    pd.set("injury_days", p.injury_days as i64);
                    let injury_str = if p.injury_days > 0 { format!("Lesionado ({} dias)", p.injury_days) } else { "Saudável".to_string() };
                    pd.set("injury_status", &GString::from(injury_str.as_str()));
                    // Attribute breakdown for training focus
                    let (attr_value, attr_name) = match team.training_focus {
                        TrainingFocus::Shooting => (p.attributes.three_pt, "three_pt"),
                        TrainingFocus::Defense => (p.attributes.perimeter_def, "perimeter_def"),
                        TrainingFocus::Playmaking => (p.attributes.passing, "passing"),
                        TrainingFocus::Physical => (p.attributes.stamina, "stamina"),
                        TrainingFocus::Balanced => (p.attributes.overall(), "overall"),
                    };
                    pd.set("focus_attr", attr_value as f64);
                    pd.set("focus_attr_name", &GString::from(attr_name));
                    players_arr.push(&pd);
                }
                d.set("players", &players_arr);

                d
            }
            None => VarDictionary::new()
        }
    }

    #[func]
    fn submit_interview_answer(&self, answer_id: GString, target_id: i64) -> VarDictionary {
        let mut game = self.state.lock().unwrap();
        let user_id = game.user_team_id.unwrap_or(0);
        let mut message = String::new();
        match answer_id.to_string().as_str() {
            "PRAISE_TEAM" => {
                if let Some(ref mut league) = game.league {
                    if let Some(team) = league.teams.iter_mut().find(|t| t.id == user_id) {
                        for p in team.players.iter_mut() {
                            p.morale = (p.morale + 5.0).min(100.0);
                        }
                        message = "Você elogiou o time. A moral do elenco aumentou em +5!".into();
                        godot_print!("[Morale] PRAISE_TEAM: team {} morale +5", user_id);
                    }
                }
            }
            "CRITICIZE_PLAYER" => {
                let tid = target_id as u32;
                let mut found = false;
                if let Some(ref mut league) = game.league {
                    for team in league.teams.iter_mut() {
                        for p in team.players.iter_mut() {
                            if p.id == tid {
                                p.morale = (p.morale - 20.0).max(0.0);
                                message = format!("Você criticou {} {}. A moral dele caiu -20!", p.first_name, p.last_name);
                                godot_print!("[Morale] CRITICIZE_PLAYER: player {} morale -20", tid);
                                found = true;
                            }
                        }
                        if found { break; }
                    }
                }
                if !found {
                    message = "Jogador não encontrado.".into();
                }
            }
            _ => {
                message = "Você deu uma resposta profissional. Nenhum efeito na moral.".into();
            }
        }
        let mut dict = VarDictionary::new();
        dict.set("message", &GString::from(message.as_str()));
        dict
    }

    #[func]
    fn get_events(&self) -> VarArray {
        let game = self.state.lock().unwrap();
        match game.league.as_ref() {
            Some(l) => {
                godot_print!("[Engine] get_events returning {} events", l.events.len());
                events_to_arr(&l.events)
            },
            None => {
                godot_print!("[Engine] get_events: NO LEAGUE");
                VarArray::new()
            },
        }
    }

    #[func]
    fn set_events(&self, events: VarArray) {
        godot_print!("[Engine] set_events called with {} items", events.len());
        let mut game = self.state.lock().unwrap();
        if let Some(ref mut league) = game.league {
            let converted = events_from_arr(&events);
            godot_print!("[Engine] events_from_arr converted {} / {} events", converted.len(), events.len());
            league.events = converted;
        } else {
            godot_print!("[Engine] set_events: NO LEAGUE!");
        }
    }

    #[func]
    fn complete_event(&self, event_id: i64) {
        let mut game = self.state.lock().unwrap();
        if let Some(ref mut league) = game.league {
            for evt in league.events.iter_mut() {
                if evt.id == event_id as u32 {
                    evt.is_completed = true;
                    break;
                }
            }
        }
    }

    #[func]
    fn advance_season(&self) -> VarDictionary {
        let (user_id, params) = {
            let game = self.state.lock().unwrap();
            (game.user_team_id.unwrap_or(0), game.params.clone())
        };
        let mut game = self.state.lock().unwrap();
        let league = match game.league.as_mut() {
            Some(l) => l,
            None => return VarDictionary::new(),
        };

        let mut rng = rand::thread_rng();

        // ── A) Archive season stats → career, reset season stats, age, physical decline ──
        for team in league.teams.iter_mut() {
            for player in team.players.iter_mut() {
                player.stats_career.games_played += player.stats_season.games_played;
                player.stats_career.points          += player.stats_season.points;
                player.stats_career.rebounds        += player.stats_season.rebounds;
                player.stats_career.assists         += player.stats_season.assists;
                player.stats_career.steals          += player.stats_season.steals;
                player.stats_career.blocks          += player.stats_season.blocks;
                player.stats_career.turnovers       += player.stats_season.turnovers;
                player.stats_season = PlayerStats::default();

                player.age = player.age.saturating_add(1);

                if player.age >= 31 {
                    let penalty = rng.gen_range(1.0..=3.0);
                    player.attributes.speed   = (player.attributes.speed   - penalty).max(20.0);
                    player.attributes.stamina = (player.attributes.stamina - penalty).max(20.0);
                    player.attributes.jumping = (player.attributes.jumping - penalty).max(20.0);
                }
            }
        }

        // ── B) Retirements + Regens ──

        let mut used_names: std::collections::HashSet<String> = league.teams.iter()
            .flat_map(|t| t.players.iter())
            .map(|p| format!("{} {}", p.first_name, p.last_name))
            .collect();

        let mut next_id: u32 = league.teams.iter()
            .flat_map(|t| t.players.iter())
            .map(|p| p.id).max().unwrap_or(0) + 1;

        for team in league.teams.iter_mut() {
            let mut retiring: Vec<usize> = Vec::new();
            for (i, p) in team.players.iter().enumerate() {
                if p.age >= 38 || (p.age >= 35 && rng.gen_bool(0.5)) {
                    retiring.push(i);
                }
            }
            for idx in retiring.into_iter().rev() {
                team.players.swap_remove(idx);
            }

            while team.players.len() < 15 {
                let pos = Position::list()[rng.gen_range(0..5)].clone();
                let overall = rng.gen_range(50.0..95.0);
                let mut rookie = crate::engine::player::generate_player(
                    next_id, pos, overall, &mut used_names,
                );
                rookie.age = 19;
                rookie.salary = rng.gen_range(500_000..2_000_000);
                team.players.push(rookie);
                next_id += 1;
            }
        }

        // ── C) Season prizes ──
        crate::engine::finance::process_season_prizes(
            league, &params, &self.txn_id_counter,
        );

        // ── D) Season metadata ──
        league.season = league.season.saturating_add(1);
        league.current_week = 1;
        league.playoffs_active = false;
        league.playoff_series.clear();
        league.events.clear();

        for team in league.teams.iter_mut() {
            team.wins = 0;
            team.losses = 0;
            team.transactions.clear();
            // Regenerate sponsors
            crate::engine::finance::generate_sponsors(
                team, &params, &self.txn_id_counter,
            );
        }

        // ── E) Assign new focus + intensity for non-user teams for the new season ──
        let all_focuses = [TrainingFocus::Shooting, TrainingFocus::Defense, TrainingFocus::Playmaking, TrainingFocus::Physical, TrainingFocus::Balanced];
        for team in league.teams.iter_mut() {
            // Clear injuries and reset stamina/morale baseline
            for p in team.players.iter_mut() {
                p.injury_days = 0;
                p.morale = 50.0;
                p.attributes.stamina = 80.0;
            }
            if team.id != user_id {
                team.training_focus = all_focuses[rng.gen_range(0..all_focuses.len())].clone();
                team.training_intensity = "MÉDIA".to_string();
            }
        }

        // ── F) Fresh double round‑robin schedule ──
        league.schedule.clear();
        let mut game_id: u32 = 1;
        let num = league.teams.len();
        let mut indices: Vec<usize> = (0..num).collect();
        for week in 1..=22 {
            let is_return = week > 11;
            for i in 0..(num / 2) {
                let t1 = indices[i];
                let t2 = indices[num - 1 - i];
                let (home, away) = if is_return {
                    if week % 2 == 0 { (t2, t1) } else { (t1, t2) }
                } else {
                    if week % 2 == 0 { (t1, t2) } else { (t2, t1) }
                };
                league.schedule.push(ScheduledGame {
                    id: game_id,
                    home_team: league.teams[home].id,
                    away_team: league.teams[away].id,
                    week: week as u16,
                    played: false,
                    is_playoff: false,
                    home_score: None,
                    away_score: None,
                });
                game_id += 1;
            }
            let last = indices.pop().unwrap();
            indices.insert(1, last);
        }

        let result = league_to_dict(league);

        // ── G) Tiny reputation bump for surviving a season ──
        if let Some(ref mut c) = game.coach {
            c.reputation = (c.reputation + 2).min(100);
        }

        result
    }

    #[func]
    fn save_game(&self, path: GString) -> bool {
        let game = self.state.lock().unwrap();
        let db_path = path.to_string();
        match crate::db::init_db(&db_path) {
            Ok(conn) => {
                match crate::db::save_game_state(&conn, &game) {
                    Ok(()) => {
                        godot_print!("[Engine] save_game: success, {} events saved", game.league.as_ref().map_or(0, |l| l.events.len()));
                        true
                    }
                    Err(e) => {
                        godot_print!("[Engine] save_game: save_game_state error: {}", e);
                        false
                    }
                }
            }
            Err(e) => {
                godot_print!("[Engine] save_game: init_db error: {}", e);
                false
            }
        }
    }

    #[func]
    fn load_game(&self, path: GString) -> VarDictionary {
        match crate::db::init_db(&path.to_string()) {
            Ok(conn) => {
                if let Ok(Some(loaded)) = crate::db::load_game_state(&conn) {
                    let mut game = self.state.lock().unwrap();
                    *game = loaded;
                    match game.league.as_ref() {
                        Some(l) => league_to_dict(l),
                        None => VarDictionary::new(),
                    }
                } else {
                    VarDictionary::new()
                }
            }
            Err(_) => VarDictionary::new(),
        }
    }

    #[func]
    fn is_match_over(&self) -> bool {
        let match_sim = self.simulator.lock().unwrap();
        match_sim.as_ref().map_or(false, |s| s.is_over)
    }

    #[func]
    fn get_match_score(&self) -> VarDictionary {
        let match_sim = self.simulator.lock().unwrap();
        let mut d = VarDictionary::new();
        if let Some(sim) = match_sim.as_ref() {
            d.set("home", sim.home_score as i64);
            d.set("away", sim.away_score as i64);
            d.set("quarter", sim.clock.quarter as i64);
            let clk = sim.clock.format_clock();
            d.set("clock", &GString::from(&clk));
            d.set("shot_clock", sim.clock.shot_clock as i64);
        }
        d
    }

    // ── Worker Thread API ──

    #[func]
    fn start_worker(&self) -> bool {
        let mut worker_lock = self.worker.lock().unwrap();
        if worker_lock.is_some() {
            godot_warn!("[BasketballEngine] Worker already running");
            return false;
        }
        let state = self.state.lock().unwrap().clone();
        let worker = SimulationWorker::new(state);
        *worker_lock = Some(worker);
        godot_print!("[BasketballEngine] Worker thread spawned");
        true
    }

    fn sim_event_to_dict(event: &crate::worker::SimEvent) -> VarDictionary {
        use godot::prelude::Variant;
        use serde_json::Value;

        fn val_to_variant(val: &Value) -> Variant {
            match val {
                Value::Null => ().to_variant(),
                Value::Bool(b) => b.to_variant(),
                Value::Number(n) => {
                    if let Some(i) = n.as_i64() { return i.to_variant(); }
                    if let Some(f) = n.as_f64() { return f.to_variant(); }
                    ().to_variant()
                }
                Value::String(s) => GString::from(s.as_str()).to_variant(),
                Value::Array(arr) => {
                    let mut va = VarArray::new();
                    for item in arr { va.push(&val_to_variant(item)); }
                    va.to_variant()
                }
                Value::Object(map) => {
                    let mut d = VarDictionary::new();
                    for (k, v) in map {
                        d.set(&GString::from(k.as_str()), &val_to_variant(v));
                    }
                    d.to_variant()
                }
            }
        }

        let mut d = VarDictionary::new();
        d.set("kind", &GString::from(event.kind_str()));
        for (k, v) in &event.data {
            d.set(&GString::from(k.as_str()), &val_to_variant(v));
        }
        d
    }

    #[func]
    fn poll_worker_events(&self) -> VarArray {
        let mut worker_lock = self.worker.lock().unwrap();
        let worker = match worker_lock.as_mut() {
            Some(w) => w,
            None => return VarArray::new(),
        };
        let events = worker.drain_events();
        let mut arr = VarArray::new();
        for event in events {
            arr.push(&Self::sim_event_to_dict(&event));
        }
        arr
    }

    #[func]
    fn send_worker_command(&self, command: GString) {
        let worker_lock = self.worker.lock().unwrap();
        let worker = match worker_lock.as_ref() {
            Some(w) => w,
            None => return,
        };
        let cmd = match command.to_string().as_str() {
            "cancel" => SimCommand::Cancel,
            "shutdown" => SimCommand::Shutdown,
            _ => return,
        };
        worker.send_command(cmd);
    }

    #[func]
    fn simulate_to_week(&self, target_week: i64) {
        let worker_lock = self.worker.lock().unwrap();
        let worker = match worker_lock.as_ref() {
            Some(w) => w,
            None => return,
        };
        worker.send_command(SimCommand::SimulateToWeek {
            target_week: target_week as u16,
        });
    }

    #[func]
    fn is_worker_alive(&self) -> bool {
        let worker_lock = self.worker.lock().unwrap();
        worker_lock.as_ref().map_or(false, |w| w.is_alive())
    }

    // ── Game Params (configuração) ──

    #[func]
    fn get_game_params(&self) -> VarDictionary {
        let game = self.state.lock().unwrap();
        let dict = game.params.to_dict();
        let mut vd = VarDictionary::new();
        for (k, v) in &dict {
            let val = match v {
                serde_json::Value::Number(n) => {
                    if let Some(f) = n.as_f64() { f.to_variant() }
                    else if let Some(i) = n.as_i64() { i.to_variant() }
                    else { ().to_variant() }
                }
                serde_json::Value::Bool(b) => b.to_variant(),
                serde_json::Value::String(s) => GString::from(s.as_str()).to_variant(),
                _ => ().to_variant(),
            };
            vd.set(&GString::from(k.as_str()), &val);
        }
        vd
    }

    #[func]
    fn set_game_param(&self, key: GString, value: Variant) -> bool {
        let key_str = key.to_string();
        let json_val = Self::variant_to_json_value(&value);
        let mut game = self.state.lock().unwrap();
        let ok = game.params.set_from_json(&key_str, json_val);
        if ok {
            godot_print!("[Engine] GameParam '{}' updated", key_str);
        } else {
            godot_warn!("[Engine] Unknown GameParam key: '{}'", key_str);
        }
        ok
    }

    fn variant_to_json_value(v: &Variant) -> serde_json::Value {
        use godot::prelude::VariantType;
        match v.get_type() {
            VariantType::FLOAT => serde_json::json!(v.to::<f64>()),
            VariantType::INT => serde_json::json!(v.to::<i64>()),
            VariantType::BOOL => serde_json::json!(v.to::<bool>()),
            VariantType::STRING => serde_json::json!(v.to::<GString>().to_string()),
            _ => serde_json::Value::Null,
        }
    }

    // ── Worker Breakpoint & Match Recording ──

    #[func]
    fn sync_worker_state(&self) -> bool {
        let worker_lock = self.worker.lock().unwrap();
        let worker = match worker_lock.as_ref() {
            Some(w) => w,
            None => return false,
        };
        let ws = match worker.get_working_state() {
            Some(s) => s,
            None => return false,
        };
        let mut game = self.state.lock().unwrap();
        *game = ws;
        godot_print!("[BasketballEngine] Worker state synced to main thread");
        true
    }

    #[func]
    fn resume_worker(&self, simulate_match: bool) {
        let worker_lock = self.worker.lock().unwrap();
        let worker = match worker_lock.as_ref() {
            Some(w) => w,
            None => return,
        };
        worker.send_command(SimCommand::Resume { simulate_match });
        godot_print!("[BasketballEngine] Worker resumed (simulate={})", simulate_match);
    }

    #[func]
    fn record_match_result(&self, home_id: i64, away_id: i64, home_score: i64, away_score: i64) -> bool {
        let mut game = self.state.lock().unwrap();
        let league = match game.league.as_mut() {
            Some(l) => l,
            None => return false,
        };

        let home = home_id as u32;
        let away = away_id as u32;
        let h_s = home_score as u16;
        let a_s = away_score as u16;
        let mut found_week: u16 = 0;
        let mut found = false;

        for sg in league.schedule.iter_mut() {
            if sg.home_team == home && sg.away_team == away && !sg.played {
                sg.played = true;
                sg.home_score = Some(h_s);
                sg.away_score = Some(a_s);
                found_week = sg.week;
                found = true;
                break;
            }
        }

        if !found {
            godot_warn!("[BasketballEngine] No unplayed game found for {} vs {}", home_id, away_id);
            return false;
        }

        for team in league.teams.iter_mut() {
            if team.id == home {
                if home_score > away_score { team.wins += 1; } else { team.losses += 1; }
            }
            if team.id == away {
                if away_score > home_score { team.wins += 1; } else { team.losses += 1; }
            }
        }

        if league.playoffs_active {
            Self::resolve_playoff_round(league, found_week);
        }

        godot_print!("[BasketballEngine] Match result recorded: {} {} x {} {}", home_id, home_score, away_score, away_id);
        true
    }

    #[func]
    fn stop_worker(&self) {
        let mut worker_lock = self.worker.lock().unwrap();
        if let Some(worker) = worker_lock.take() {
            worker.shutdown();
            godot_print!("[BasketballEngine] Worker thread stopped");
        }
    }
}

#[godot_api]
impl IRefCounted for BasketballEngine {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            state: Mutex::new(GameState::default()),
            simulator: Mutex::new(None),
            pending_games: Vec::new(),
            pending_idx: 0,
            worker: Mutex::new(None),
            txn_id_counter: AtomicU32::new(10_000), // start high to avoid ID conflicts
            base,
        }
    }
}
