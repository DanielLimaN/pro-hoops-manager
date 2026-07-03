use glam::Vec2;
use rand::Rng;
use serde_json::{json, Value};
use crate::engine::decisions;
use crate::engine::shot_resolver;
use crate::engine::types::*;
use crate::engine::clock::*;
use crate::engine::movement::{self, MovementSystem, init_player_positions};
use crate::engine::collision_resolver;
use crate::engine::logging::SimLogger;

const HALF_LENGTH: f32 = 15.525;
const HALF_WIDTH: f32 = 7.62;
const RIM_Z: f32 = 14.325;

pub struct MatchSimulator {
    pub home_team: Team,
    pub away_team: Team,
    pub home_score: u16,
    pub away_score: u16,
    pub clock: GameClock,
    pub ball_handler: Option<PlayerId>,
    pub possession_team: TeamId,
    pub tick_count: u64,
    pub events: Vec<MatchEvent>,
    pub is_over: bool,
    pub last_action: Option<ActionType>,
    pub movement_sys: MovementSystem,
    pub active_play: ActivePlay,
    pub logger: Option<SimLogger>,
    pub ball_trajectory: Option<BallTrajectory>,
    pub trajectory_start_tick: u64,
    pub possession_phase: PossessionPhase,
    pub phase_start_tick: u64,
    pub rebound_receiver: Option<PlayerId>,
    pub loose_ball_ticks: u32,
    pub last_landing_pos: Vec2,
    pub pending_free_throws: Option<(PlayerId, u8)>,
    pub home_fouls_quarter: u8,
    pub away_fouls_quarter: u8,
    pub pending_inbound_pos: Option<Vec2>,
    pub store_events: bool,
}

fn process_agent_ticks(
    team: &mut Team, opponent: &Team, ball_handler_id: Option<PlayerId>,
    ball_pos: Vec2, shot_clock: u8, is_offense: bool, basket_dir: f32, phase: PossessionPhase,
    shooter_id: Option<PlayerId>,
) {
    let tactics = TacticalModifiers::from_tactic(&team.tactic);
    let starters_ids: Vec<PlayerId> = team.starters().iter().map(|p| p.id).collect();
    let mut new_intents = Vec::new();

    for player in team.players.iter() {
        if !starters_ids.contains(&player.id) {
            continue;
        }
        let can_evaluate = match player.intent {
            PlayerIntent::Idle | PlayerIntent::Move { .. } | PlayerIntent::Defend { .. } => true,
            _ => false,
        };
        if can_evaluate {
            let intent = if is_offense {
                if Some(player.id) == ball_handler_id && phase == PossessionPhase::Execution {
                    decisions::evaluate_on_ball_intent(
                        player, &team.players, 0.5, &tactics, shot_clock, basket_dir)
                } else {
                    decisions::evaluate_off_ball_intent(
                        player, ball_pos, basket_dir, shot_clock, phase, shooter_id)
                }
            } else {
                let matchup = opponent.players.iter().find(|p| p.position == player.position);
                decisions::evaluate_defensive_intent(
                    player, matchup, ball_pos, ball_handler_id, basket_dir, phase, &team.players, &team.tactic.defensive)
            };
            new_intents.push((player.id, intent));
        }
    }

    for (id, intent) in new_intents {
        if let Some(p) = team.players.iter_mut().find(|p| p.id == id) {
            p.intent = intent;
        }
    }
}

impl MatchSimulator {
    pub fn new(mut home_team: Team, mut away_team: Team) -> Self {
        let possession = home_team.id;
        let tactic = home_team.tactic.clone();
        // Initialize positions for jump ball manually
        for (team, is_home) in [(&mut home_team, true), (&mut away_team, false)] {
            let basket_dir = if is_home { 1.0 } else { -1.0 };
            for p in team.players.iter_mut() {
                let pos = if is_home {
                    match p.position {
                        Position::C => glam::Vec2::new(0.0, 0.5),
                        Position::PF => glam::Vec2::new(-2.0, 1.5),
                        Position::SF => glam::Vec2::new(2.0, 1.5),
                        Position::SG => glam::Vec2::new(2.0, -1.5),
                        Position::PG => glam::Vec2::new(-2.0, -1.5),
                    }
                } else {
                    match p.position {
                        Position::C => glam::Vec2::new(0.0, -0.5),
                        Position::PF => glam::Vec2::new(-2.0, 2.0),
                        Position::SF => glam::Vec2::new(2.0, 2.0),
                        Position::SG => glam::Vec2::new(2.0, -2.0),
                        Position::PG => glam::Vec2::new(-2.0, -2.0),
                    }
                };
                p.current_position = pos;
                p.target_position = pos;
            }
        }
        let movement_sys = MovementSystem::new();
        let initial_tactic = home_team.tactic.offensive.clone();
        Self {
            home_team, away_team, home_score: 0, away_score: 0,
            clock: GameClock::new(), ball_handler: None, possession_team: possession,
            tick_count: 0, events: Vec::new(), is_over: false, last_action: None,
            movement_sys, active_play: ActivePlay::new(initial_tactic), logger: None,
            ball_trajectory: None, trajectory_start_tick: 0,
            possession_phase: PossessionPhase::JumpBall, phase_start_tick: 0,
            rebound_receiver: None, loose_ball_ticks: 0,
            last_landing_pos: Vec2::ZERO,
            pending_free_throws: None,
            home_fouls_quarter: 0,
            away_fouls_quarter: 0,
            pending_inbound_pos: None,
            store_events: true,
        }
    }

    pub fn start_logging(&mut self, log_path: &str, cal_path: &str) {
        self.logger = Some(SimLogger::new(log_path, cal_path));
    }

    pub fn tick(&mut self) -> Option<MatchEvent> {
        if self.is_over { return None; }

        if self.tick_count % 1000 == 0 {
            println!("TICK: {}, phase: {:?}", self.tick_count, self.possession_phase);
        }

        if let Some((shooter_id, count)) = self.pending_free_throws {
            if self.tick_count % 50 == 0 {
                let is_home = self.home_team.players.iter().any(|p| p.id == shooter_id);
                let shooter = if is_home {
                    self.home_team.players.iter().find(|p| p.id == shooter_id).unwrap().clone()
                } else {
                    self.away_team.players.iter().find(|p| p.id == shooter_id).unwrap().clone()
                };
                
                let mut rng = rand::thread_rng();
                let ft_skill = shooter.attributes.free_throw;
                let prob = (ft_skill / 100.0) * 0.95;
                let made = rng.gen::<f32>() < prob;
                
                let result = if made { ShotResult::Made } else { ShotResult::Missed };
                let action = ActionType::FreeThrow { player: shooter_id, result: result.clone() };
                
                let mut text = format!("{} cobra o lance livre...", shooter.last_name);
                if made { text.push_str(" ACERTO!"); } else { text.push_str(" ERRO!"); }
                
                let basket_dir = if is_home { 1.0 } else { -1.0 };
                let ft_pos = Vec2::new(0.0, basket_dir * (RIM_Z - 4.225));
                let hoop_z = basket_dir * RIM_Z;
                self.ball_trajectory = Some(BallTrajectory {
                    start_x: ft_pos.x, start_y: 2.0, start_z: ft_pos.y,
                    apex_x: 0.0, apex_y: 4.5, apex_z: (ft_pos.y + hoop_z) / 2.0,
                    end_x: 0.0, end_y: 3.05, end_z: hoop_z,
                    progress: 0.0, speed: 6.0,
                });
                self.trajectory_start_tick = self.tick_count;

                self.apply_action(action.clone(), is_home);
                self.last_action = Some(action.clone());
                
                let event = self.create_event(action, text);
                self.events.push(event.clone());
                
                let new_count = count - 1;
                if new_count == 0 {
                    self.pending_free_throws = None;
                    if made {
                        self.possession_team = if is_home { self.away_team.id } else { self.home_team.id };
                        self.possession_phase = PossessionPhase::Inbound;
                        self.set_inbounder();
                    } else {
                        self.possession_phase = PossessionPhase::ReboundContest;
                        self.phase_start_tick = self.tick_count;
                        let basket_dir = if is_home { 1.0 } else { -1.0 };
                        self.last_landing_pos = Vec2::new(0.0, basket_dir * 14.325);
                        self.ball_trajectory = Some(BallTrajectory {
                            start_x: 0.0, start_y: 3.05, start_z: basket_dir * 14.325,
                            apex_x: 0.0, apex_y: 1.6, apex_z: basket_dir * 14.325,
                            end_x: 0.0, end_y: 0.2, end_z: basket_dir * 14.325,
                            progress: 0.0, speed: 8.0,
                        });
                        self.trajectory_start_tick = self.tick_count;
                    }
                } else {
                    self.pending_free_throws = Some((shooter_id, new_count));
                }
                self.tick_count += 1;
                return Some(event);
            }
            self.tick_count += 1;
            let positions = self.movement_sys.to_player_positions(&self.home_team, &self.away_team, self.possession_team, self.ball_handler);
            let ball = self.compute_ball_for_idle_tick(&positions);
            let event = MatchEvent {
                tick: self.tick_count, action: ActionType::Tick,
                score: ScoreSnapshot {
                    home: self.home_score, away: self.away_score,
                    quarter: match self.clock.quarter { 1=>"1Q".to_string(), 2=>"2Q".to_string(), 3=>"3Q".to_string(), 4=>"4Q".to_string(), n=>format!("OT{}",n-4) },
                    clock_seconds: self.clock.total_seconds, shot_clock: self.clock.shot_clock,
                    home_fouls: self.home_fouls_quarter, away_fouls: self.away_fouls_quarter,
                },
                positions, ball, text: String::new(),
            };
            self.events.push(event.clone());
            return Some(event);
        }

        self.tick_count += 1;

        if let Some(ref traj) = self.ball_trajectory {
            let elapsed = self.tick_count.saturating_sub(self.trajectory_start_tick);
            let total_ticks = self.trajectory_ticks(traj).max(1);
            if (elapsed as f32 / total_ticks as f32) >= 1.0 {
                self.last_landing_pos = Vec2::new(traj.end_x, traj.end_z);
                self.ball_trajectory = None;
            }
        }

        let mut rng = rand::thread_rng();
        self.advance_phase(&mut rng);
        let phase_event_text = self.phase_event_text();

        let mut clock_result = TickResult::Continue;
        if self.tick_count % 5 == 0 {
            clock_result = self.clock.tick(2);
        }

        match clock_result {
            TickResult::QuarterEnd => {
                println!("Fim do quarto! Placar: {} - {}", self.home_score, self.away_score);
                if !self.clock.advance_quarter() {
                    if self.home_score == self.away_score {
                        self.clock.overtime();
                        println!("OVERTIME! Score is {} - {}", self.home_score, self.away_score);
                        let event = self.create_event(ActionType::QuarterEnd,
                            format!("Fim do {}o quarto! Placar: {} x {}. PRORROGACAO!",
                                self.clock.quarter - 1, self.home_score, self.away_score));
                        self.store_trajectory(&event);
                        self.events.push(event.clone());
                        return Some(event);
                    } else {
                        self.is_over = true;
                        let event = self.create_event(ActionType::GameEnd,
                            format!("FIM DE JOGO! {} {} x {} {}",
                                self.home_team.city, self.home_score, self.away_score, self.away_team.city));
                        self.store_trajectory(&event);
                        self.events.push(event.clone());
                        if let Some(ref l) = self.logger {
                            l.write_calibration_baseline(json!({
                                "home": {"name": self.home_team.name, "score": self.home_score},
                                "away": {"name": self.away_team.name, "score": self.away_score},
                                "total_ticks": self.tick_count,
                            }));
                        }
                        return Some(event);
                    }
                }
                self.reset_possession();
                self.home_fouls_quarter = 0;
                self.away_fouls_quarter = 0;
                let q = self.clock.quarter;
                let event = self.create_event(ActionType::QuarterEnd, format!("Inicio do {}o quarto!", q));
                self.store_trajectory(&event);
                self.events.push(event.clone());
                return Some(event);
            }
             TickResult::ShotClockViolation => {
                 let action = ActionType::Turnover {
                     player: self.ball_handler.unwrap_or(0),
                     reason: "Violacao de 24 segundos!".to_string(),
                 };
                 self.turnover("Violacao de 24 segundos!");
                 let text = "Violacao de 24 segundos!".to_string();
                 let event = self.create_event(action, text);
                 self.events.push(event.clone());
                 return Some(event);
            }
            _ => {}
        }
        let skip_movement = self.possession_phase == PossessionPhase::JumpBall
            || (self.possession_phase == PossessionPhase::Inbound && self.ball_handler.is_some())
            || self.is_over;

        let ball_pos = if let Some(ref traj) = self.ball_trajectory {
            let elapsed = self.tick_count.saturating_sub(self.trajectory_start_tick);
            let total_ticks = self.trajectory_ticks(traj).max(1);
            let progress = (elapsed as f32 / total_ticks as f32).min(1.0);
            Vec2::new(
                traj.start_x + (traj.end_x - traj.start_x) * progress,
                traj.start_z + (traj.end_z - traj.start_z) * progress
            )
        } else if let Some(handler_id) = self.ball_handler {
            self.home_team.players.iter().chain(self.away_team.players.iter())
                .find(|p| p.id == handler_id)
                .map(|p| p.current_position)
                .unwrap_or(self.last_landing_pos)
        } else {
            self.last_landing_pos
        };

        if !skip_movement {
            let home_basket_dir = 1.0;
            let away_basket_dir = -1.0;
            let shooter_id = if self.possession_phase == PossessionPhase::Inbound {
                self.rebound_receiver
            } else if let Some(ActionType::Shot { player, .. }) = &self.last_action {
                Some(*player)
            } else {
                None
            };

            if self.possession_team == self.home_team.id {
                process_agent_ticks(&mut self.home_team, &self.away_team, self.ball_handler, ball_pos, self.clock.shot_clock, true, home_basket_dir, self.possession_phase, shooter_id);
                process_agent_ticks(&mut self.away_team, &self.home_team, self.ball_handler, ball_pos, self.clock.shot_clock, false, -home_basket_dir, self.possession_phase, shooter_id);

                if self.possession_phase == PossessionPhase::Execution {
                    crate::engine::playbook::apply_playbook_tactics(&mut self.active_play, &mut self.home_team, self.ball_handler, home_basket_dir);
                    crate::engine::playbook::mirror_defensive_targets(&mut self.away_team, &self.home_team, home_basket_dir, self.ball_handler);
                }
            } else {
                process_agent_ticks(&mut self.away_team, &self.home_team, self.ball_handler, ball_pos, self.clock.shot_clock, true, away_basket_dir, self.possession_phase, shooter_id);
                process_agent_ticks(&mut self.home_team, &self.away_team, self.ball_handler, ball_pos, self.clock.shot_clock, false, -away_basket_dir, self.possession_phase, shooter_id);

                if self.possession_phase == PossessionPhase::Execution {
                    crate::engine::playbook::apply_playbook_tactics(&mut self.active_play, &mut self.away_team, self.ball_handler, away_basket_dir);
                    crate::engine::playbook::mirror_defensive_targets(&mut self.home_team, &self.away_team, away_basket_dir, self.ball_handler);
                }
            }

            if let Some(ref mut l) = self.logger {
                let targets: Vec<Value> = self.home_team.players.iter().take(5).chain(self.away_team.players.iter().take(5)).map(|p| json!({
                    "id": p.id, "pos": p.position, "target": {"x": p.target_position.x, "y": p.target_position.y}
                })).collect();
                l.log(self.tick_count, "playbook", &format!("{:?} stage:{:?}", self.active_play.tactic, self.active_play.stage), json!({"targets": targets}));
            }

            self.movement_sys.update_positions(&mut self.home_team, &mut self.away_team, self.possession_team, self.ball_handler, 0.25);

            if let Some(ref mut l) = self.logger {
                let poss: Vec<Value> = self.home_team.players.iter().take(5).chain(self.away_team.players.iter().take(5)).map(|p| json!({
                    "id": p.id, "pos": p.position, "current": {"x": p.current_position.x, "y": p.current_position.y}
                })).collect();
                l.log(self.tick_count, "movement", "positions updated", json!({"players": poss}));
            }

            if let Some(collision_action) = collision_resolver::detect_and_resolve_collisions(
                &mut self.home_team, &mut self.away_team, self.ball_handler, &mut rng,
            ) {
                self.apply_action(collision_action.clone(), true);
                self.last_action = Some(collision_action.clone());
                let text = match &collision_action {
                    ActionType::OffensiveFoul { offender, defender } =>
                        format!("FALTA DE ATAQUE! Jogador {} derrubou {}!", offender, defender),
                    ActionType::IllegalScreen { screen_setter, defender } =>
                        format!("BLOQUEIO ILEGAL! {} derrubou {}!", screen_setter, defender),
                    ActionType::Foul { defender, offender, shooting, .. } =>
                        if *shooting {
                            format!("FALTA NO ARREMESSO! {} vai para a linha de lance livre!", offender)
                        } else {
                            format!("FALTA DE DEFESA! Falta comum em {}.", offender)
                        },
                    _ => String::new(),
                };
                if let Some(ref mut l) = self.logger {
                    l.log(self.tick_count, "collision", &text, json!({"action": format!("{:?}", collision_action)}));
                }
                let event = self.create_event(collision_action, text);
                self.store_trajectory(&event);
                self.events.push(event.clone());
                return Some(event);
            }
        }

        // Process player intents (movement target alignment and active intent tick decrement)
        // for BOTH teams on EVERY tick, regardless of possession phase.
        let home_team_id = self.home_team.id;
        for team in [&mut self.home_team, &mut self.away_team] {
            let basket_dir = if team.id == home_team_id { 1.0 } else { -1.0 };
            for player in team.players.iter_mut() {
                match &mut player.intent {
                    PlayerIntent::Move { target_pos } => {
                        player.target_position = *target_pos;
                    }
                    PlayerIntent::Drive { ticks_left } => {
                        if *ticks_left > 0 {
                            *ticks_left -= 1;
                        }
                        player.target_position = Vec2::new(0.0, basket_dir * 14.325);
                    }
                    PlayerIntent::Shoot { ticks_left, .. }
                    | PlayerIntent::Pass { ticks_left, .. }
                    | PlayerIntent::Block { ticks_left, .. }
                    | PlayerIntent::BoxOut { ticks_left, .. }
                    | PlayerIntent::Rebound { ticks_left, .. } => {
                        if *ticks_left > 0 {
                            *ticks_left -= 1;
                        } else {
                            // If a defensive or rebound phase intent has timed out, reset to Idle
                            match player.intent {
                                PlayerIntent::Block { .. }
                                | PlayerIntent::BoxOut { .. }
                                | PlayerIntent::Rebound { .. } => {
                                    player.intent = PlayerIntent::Idle;
                                }
                                _ => {}
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        if self.possession_phase == PossessionPhase::Execution {
            if self.ball_handler.is_none() {
                self.ball_handler = self.find_pg_or_first_starter(self.possession_team);
            }

            let mut executed_action = None;
            let mut event_text = String::new();

            let is_home_possession = self.possession_team == self.home_team.id;
            let (offense_team, defense_team) = if is_home_possession {
                (&mut self.home_team, &self.away_team)
            } else {
                (&mut self.away_team, &self.home_team)
            };

            for player in offense_team.players.iter_mut() {
                let mut shoot_action_pending = None;

                match &mut player.intent {
                    PlayerIntent::Shoot { shot_type, ticks_left, distance } => {
                        if *ticks_left == 0 {
                            shoot_action_pending = Some((shot_type.clone(), *distance));
                        }
                    }
                    PlayerIntent::Pass { target, ticks_left } => {
                        if *ticks_left == 0 {
                            executed_action = Some(ActionType::Pass {
                                from: player.id, to: *target,
                                start_pos: [player.current_position.x, player.current_position.y],
                                target_pos: [0.0, 0.0], air_time_ms: 1000, pass_type: PassType::Chest,
                            });
                            event_text = format!("{} passa a bola.", player.last_name);
                            player.intent = PlayerIntent::Idle;
                        }
                    }
                    PlayerIntent::Drive { ticks_left } => {
                        if *ticks_left == 0 {
                            let basket_dir = if is_home_possession { 1.0 } else { -1.0 };
                            let hoop_pos = Vec2::new(0.0, basket_dir * 14.325);
                            let dist_to_hoop = player.current_position.distance(hoop_pos);
                            if dist_to_hoop < 3.5 {
                                let use_dunk = player.attributes.dunk > 70.0 && player.attributes.dunk >= player.attributes.layup;
                                player.intent = PlayerIntent::Shoot {
                                    shot_type: if use_dunk { ShotType::Dunk } else { ShotType::Layup },
                                    ticks_left: 5, distance: dist_to_hoop,
                                };
                            } else {
                                player.intent = PlayerIntent::Idle;
                            }
                        }
                    }
                    _ => {}
                }

                if let Some((shot_type, _intent_distance)) = shoot_action_pending {
                    let closest_defender = defense_team.players.iter()
                        .min_by(|a, b| {
                            let dist_a = a.current_position.distance(player.current_position);
                            let dist_b = b.current_position.distance(player.current_position);
                            dist_a.partial_cmp(&dist_b).unwrap_or(std::cmp::Ordering::Equal)
                        });
                    let defender_distance = closest_defender.map_or(10.0, |d| d.current_position.distance(player.current_position));

                    let basket_dir = if is_home_possession { 1.0 } else { -1.0 };
                    let hoop_pos = Vec2::new(0.0, basket_dir * RIM_Z);
                    let actual_distance = player.current_position.distance(hoop_pos);

                    let ctx = shot_resolver::ShotContext {
                        shooter: player.clone(), defender: closest_defender.cloned(),
                        shot_type: shot_type.clone(), distance: actual_distance, is_clutch: false, defender_distance,
                    };
                    let (result, result_text) = shot_resolver::resolve_shot(&ctx);

                    executed_action = Some(ActionType::Shot { player: player.id, shot_type, result, distance: actual_distance });
                    event_text = format!("{} arremessa! {}", player.last_name, result_text);
                    player.intent = PlayerIntent::Idle;
                }
            }

            if let Some(action) = executed_action {
                let is_home = self.possession_team == self.home_team.id;
                self.apply_action(action.clone(), is_home);
                self.last_action = Some(action.clone());
                if let Some(ref mut l) = self.logger {
                    l.log(self.tick_count, "execution", &event_text, json!({"action": format!("{:?}", action)}));
                }
                let event = self.create_event(action, event_text);
                self.store_trajectory(&event);
                if self.store_events {
                    self.events.push(event.clone());
                }
                return Some(event);
            }
        }

        let positions = self.movement_sys.to_player_positions(
            &self.home_team, &self.away_team, self.possession_team, self.ball_handler);
        let ball = self.compute_ball_for_phase(&positions);
        let event = MatchEvent {
            tick: self.tick_count,
            action: ActionType::Tick,
            score: ScoreSnapshot {
                home: self.home_score, away: self.away_score,
                quarter: match self.clock.quarter {
                    1 => "1Q".to_string(), 2 => "2Q".to_string(), 3 => "3Q".to_string(), 4 => "4Q".to_string(),
                    n => format!("OT{}", n - 4),
                },
                clock_seconds: self.clock.total_seconds, shot_clock: self.clock.shot_clock,
                home_fouls: self.home_fouls_quarter, away_fouls: self.away_fouls_quarter,
            },
            positions: positions.clone(), ball: ball.clone(), text: phase_event_text,
        };
        if let Some(ref mut l) = self.logger {
            let poss: Vec<Value> = positions.iter().map(|p| json!({"id": p.player_id, "x": p.x, "z": p.z})).collect();
            l.log(self.tick_count, "idle", "no action", json!({"positions": poss, "ball": {"x": ball.x, "z": ball.z, "carrier": ball.carrier_id}}));
        }
        if self.store_events || !matches!(event.action, ActionType::Tick) {
            self.events.push(event.clone());
        }
        Some(event)
    }

    fn apply_action(&mut self, action: ActionType, is_home: bool) {
        if let Some(ref mut l) = self.logger {
            l.log(self.tick_count, "apply_action", &format!("{:?}", action), json!({"is_home": is_home}));
        }
        match action {
            ActionType::Pass { to, .. } => {
                self.ball_handler = Some(to);
                for player in self.home_team.players.iter_mut().chain(self.away_team.players.iter_mut()) {
                    if player.id == to { player.intent = PlayerIntent::Idle; break; }
                }
            }
            ActionType::Shot { .. } => {
                self.ball_handler = None;
                self.clock.reset_shot_clock();
                self.possession_phase = PossessionPhase::ShotInAir;
            }
            ActionType::FreeThrow { ref result, .. } => {
                if *result == ShotResult::Made {
                    if is_home { self.home_score += 1; } else { self.away_score += 1; }
                }
                self.clock.reset_shot_clock();
            }
            ActionType::Steal { defender, .. } => { self.turnover("bola perdida"); self.ball_handler = Some(defender); }
            ActionType::Turnover { ref reason, .. } => { self.turnover(reason); }
            ActionType::Rebound { player, offensive } => {
                self.ball_handler = Some(player);
                if offensive { self.clock.reset_shot_clock_offensive(); } else { self.clock.reset_shot_clock(); }
            }
            ActionType::OffensiveFoul { .. } | ActionType::IllegalScreen { .. } => {
                self.turnover("falta/falta de ataque"); self.ball_handler = None;
            }
            ActionType::Foul { shooting, offender, .. } => {
                let is_home = self.home_team.players.iter().any(|p| p.id == offender);
                let foul_count = if is_home { 
                    self.away_fouls_quarter += 1;
                    self.away_fouls_quarter
                } else {
                    self.home_fouls_quarter += 1;
                    self.home_fouls_quarter
                };
                let in_penalty = foul_count > 4;

                if shooting || in_penalty {
                    let num_shots = if shooting { 2 } else { 2 };
                    self.pending_free_throws = Some((offender, num_shots));
                    self.ball_handler = None;
                    self.arrange_for_free_throw(offender, is_home);
                } else {
                    self.possession_team = if is_home { self.home_team.id } else { self.away_team.id };
                    self.clock.reset_shot_clock();
                    self.reset_playbook();
                    self.reset_intents();
                    self.possession_phase = PossessionPhase::Inbound;
                    self.phase_start_tick = self.tick_count;
                    self.set_inbounder();
                }
            }
            _ => {}
        }
    }

    fn set_inbounder(&mut self) {
        let is_home = self.possession_team == self.home_team.id;
        let inbounder_id = {
            let team = if is_home { &self.home_team } else { &self.away_team };
            let starters = team.starters();
            starters.iter().find(|p| p.position == Position::C)
                .or_else(|| starters.iter().find(|p| p.position == Position::PF))
                .or_else(|| starters.first()).map(|p| p.id).unwrap()
        };
        self.ball_handler = Some(inbounder_id);
        let basket_dir = if is_home { 1.0 } else { -1.0 };
        let inbound_z = -basket_dir * (HALF_LENGTH + 0.5);
        let team_mut = if is_home { &mut self.home_team } else { &mut self.away_team };
        if let Some(player) = team_mut.players.iter_mut().find(|p| p.id == inbounder_id) {
            player.current_position.x = 0.0; player.current_position.y = inbound_z;
        }
    }

    fn reset_intents(&mut self) {
        for player in self.home_team.players.iter_mut() { player.intent = PlayerIntent::Idle; }
        for player in self.away_team.players.iter_mut() { player.intent = PlayerIntent::Idle; }
    }

    fn turnover(&mut self, reason: &str) {
        if let Some(ref mut l) = self.logger {
            l.log(self.tick_count, "turnover", reason, json!({"prev_possession": self.possession_team}));
        }
        
        // Find infraction pos before changing possession
        let infraction_pos = self.ball_handler
            .and_then(|id| {
                self.home_team.players.iter().chain(self.away_team.players.iter()).find(|p| p.id == id).map(|p| p.current_position)
            })
            .unwrap_or(self.last_landing_pos);

        self.possession_team = if self.possession_team == self.home_team.id { self.away_team.id } else { self.home_team.id };
        self.clock.reset_shot_clock();
        self.reset_playbook();
        self.reset_intents();

        if reason == "Violacao de 8 segundos" || reason == "Voltou a bola pra defesa" {
            self.possession_phase = PossessionPhase::Inbound;
            self.pending_inbound_pos = Some(Vec2::new(7.5, 0.0));
            self.ball_handler = None;
            self.set_inbounder();
        } else if reason == "cesta convertida" {
            self.pending_inbound_pos = None;
            self.possession_phase = PossessionPhase::ShotInAir;
            self.ball_handler = None;
        } else if reason == "falta/falta de ataque" || reason == "Violacao de 24 segundos!" || reason == "Turnover" {
            // Find nearest out of bounds spot
            let mut best_pos = Vec2::ZERO;
            let mut min_dist = f32::MAX;
            
            // Edges: x = 7.62, x = -7.62, y = 14.325, y = -14.325
            let d_right = 7.62 - infraction_pos.x;
            if d_right < min_dist { min_dist = d_right; best_pos = Vec2::new(7.62, infraction_pos.y); }
            
            let d_left = infraction_pos.x - (-7.62);
            if d_left < min_dist { min_dist = d_left; best_pos = Vec2::new(-7.62, infraction_pos.y); }
            
            let d_top = 14.325 - infraction_pos.y;
            if d_top < min_dist { min_dist = d_top; best_pos = Vec2::new(infraction_pos.x, 14.325); }
            
            let d_bottom = infraction_pos.y - (-14.325);
            if d_bottom < min_dist { min_dist = d_bottom; best_pos = Vec2::new(infraction_pos.x, -14.325); }

            self.pending_inbound_pos = Some(best_pos);
            self.possession_phase = PossessionPhase::Inbound;
            self.ball_handler = None;
            self.set_inbounder();
        } else if reason == "bola perdida" || reason == "rebote defensivo" || reason == "perda de bola" {
            self.possession_phase = PossessionPhase::BringUp;
            self.ball_handler = self.find_pg_or_first_starter(self.possession_team);
        } else {
            self.possession_phase = PossessionPhase::BringUp;
            self.ball_handler = self.find_pg_or_first_starter(self.possession_team);
        }
        self.phase_start_tick = self.tick_count;
    }

    fn reset_playbook(&mut self) {
        let t = if self.possession_team == self.home_team.id {
            &self.home_team.tactic.offensive
        } else {
            &self.away_team.tactic.offensive
        };
        self.active_play = ActivePlay::new(t.clone());
    }

    fn reset_possession(&mut self) {
        if self.clock.quarter % 2 == 1 { self.possession_team = self.home_team.id; }
        else { self.possession_team = self.away_team.id; }
        self.possession_phase = PossessionPhase::Inbound;
        self.phase_start_tick = self.tick_count;
        self.set_inbounder();
        self.reset_playbook();
    }

    fn store_trajectory(&mut self, event: &MatchEvent) {
        self.ball_trajectory = event.ball.trajectory.clone();
        if self.ball_trajectory.is_some() { self.trajectory_start_tick = self.tick_count; }
    }

    fn compute_ball_for_idle_tick(&self, positions: &[PlayerPosition]) -> BallState {
        if let Some(ref traj) = self.ball_trajectory {
            let elapsed = self.tick_count - self.trajectory_start_tick;
            let total_ticks = self.trajectory_ticks(traj).max(1);
            let t = (elapsed as f32 / total_ticks as f32).min(1.0);
            if t < 1.0 {
                let x = traj.start_x + (traj.end_x - traj.start_x) * t;
                let z = traj.start_z + (traj.end_z - traj.start_z) * t;
                
                // Bezier curve for y
                let control_y = 2.0 * traj.apex_y - 0.5 * traj.start_y - 0.5 * traj.end_y;
                let u = 1.0 - t;
                let y = u * u * traj.start_y + 2.0 * u * t * control_y + t * t * traj.end_y;
                
                return BallState { x, y, z, holder: None, carrier_id: None, trajectory: None };
            }
        }
        let (x, z, y) = self.ball_handler.and_then(|id| positions.iter().find(|p| p.player_id == id))
            .map_or((self.last_landing_pos.x, self.last_landing_pos.y, 0.2), |p| (p.x, p.z, 1.0));
        BallState { x, y, z, holder: self.ball_handler, carrier_id: self.ball_handler, trajectory: None }
    }

    fn trajectory_ticks(&self, traj: &BallTrajectory) -> u32 {
        let dx = traj.end_x - traj.start_x;
        let dz = traj.end_z - traj.start_z;
        let dist = (dx * dx + dz * dz).sqrt();
        (dist / traj.speed).ceil().max(2.0) as u32
    }

    fn get_team(&self, team_id: TeamId) -> &Team {
        if team_id == self.home_team.id { &self.home_team } else { &self.away_team }
    }

    fn find_pg_or_first_starter(&self, team_id: TeamId) -> Option<PlayerId> {
        let team = self.get_team(team_id);
        team.players.iter()
            .find(|p| p.position == Position::PG && team.starters().iter().any(|s| s.id == p.id))
            .map(|p| p.id)
            .or_else(|| team.starters().first().map(|s| s.id))
    }

    fn arrange_for_free_throw(&mut self, shooter_id: PlayerId, is_home: bool) {
        let basket_dir = if is_home { 1.0 } else { -1.0 };
        let hoop_z = basket_dir * RIM_Z;
        let ft_z = basket_dir * (RIM_Z - 4.225);
        let ft_pos = Vec2::new(0.0, ft_z);

        // Put shooter at the line
        let team_mut = if is_home { &mut self.home_team } else { &mut self.away_team };
        if let Some(shooter) = team_mut.players.iter_mut().find(|p| p.id == shooter_id) {
            shooter.current_position = ft_pos;
            shooter.target_position = ft_pos;
        }

        // Put others in rebound lane or behind 3pt line
        let lane_x = 2.5;
        
        // Offensive players (2 on lane, 2 behind 3pt)
        let mut off_lane_idx = 0;
        let off_team = if is_home { &mut self.home_team } else { &mut self.away_team };
        for p in off_team.players.iter_mut().filter(|p| p.id != shooter_id) {
            if off_lane_idx < 2 {
                let x = if off_lane_idx == 0 { -lane_x } else { lane_x };
                let z = hoop_z - basket_dir * 1.5;
                p.current_position = Vec2::new(x, z);
                p.target_position = Vec2::new(x, z);
                off_lane_idx += 1;
            } else {
                let x = if off_lane_idx == 2 { -3.0 } else { 3.0 };
                let z = ft_z - basket_dir * 3.0;
                p.current_position = Vec2::new(x, z);
                p.target_position = Vec2::new(x, z);
                off_lane_idx += 1;
            }
        }

        // Defensive players (3 on lane, 1 behind 3pt)
        let mut def_lane_idx = 0;
        let def_team = if is_home { &mut self.away_team } else { &mut self.home_team };
        for p in def_team.players.iter_mut() {
            if def_lane_idx < 4 {
                let x = if def_lane_idx % 2 == 0 { -lane_x } else { lane_x };
                let z = hoop_z - basket_dir * (if def_lane_idx < 2 { 0.5 } else { 2.5 });
                p.current_position = Vec2::new(x, z);
                p.target_position = Vec2::new(x, z);
                def_lane_idx += 1;
            } else {
                let z = ft_z - basket_dir * 4.0;
                p.current_position = Vec2::new(0.0, z);
                p.target_position = Vec2::new(0.0, z);
                def_lane_idx += 1;
            }
        }
        
        self.last_landing_pos = ft_pos;
    }

    fn advance_phase(&mut self, rng: &mut impl Rng) {
        let elapsed = self.tick_count - self.phase_start_tick;
        match self.possession_phase {
            PossessionPhase::JumpBall => {
                if elapsed >= 20 {
                    let home_wins = rng.gen::<bool>();
                    let winning_team = if home_wins { self.home_team.id } else { self.away_team.id };
                    self.possession_team = winning_team;
                    
                    let winner_pg = self.find_pg_or_first_starter(winning_team);
                    self.ball_handler = winner_pg;
                    
                    self.possession_phase = PossessionPhase::BringUp;
                    self.phase_start_tick = self.tick_count;
                    self.reset_playbook();
                    self.reset_intents();

                    let team_ref = if home_wins { &self.home_team } else { &self.away_team };
                    let rx = team_ref.players.iter().find(|p| Some(p.id) == winner_pg).map_or(0.0, |p| p.current_position.x);
                    let rz = team_ref.players.iter().find(|p| Some(p.id) == winner_pg).map_or(0.0, |p| p.current_position.y); // using y as z

                    self.ball_trajectory = Some(BallTrajectory {
                        start_x: 0.0, start_y: 1.0, start_z: 0.0,
                        apex_x: 0.0, apex_y: 8.0, apex_z: 0.0,
                        end_x: rx, end_y: 1.0, end_z: rz,
                        progress: 0.0, speed: 3.5,
                    });
                    self.trajectory_start_tick = self.tick_count;
                }
            }
            PossessionPhase::ShotInAir => {
                if self.ball_trajectory.is_none() {
                    if let Some(ActionType::Shot { result, .. }) = &self.last_action {
                        if *result == ShotResult::Missed || *result == ShotResult::Blocked {
                            self.possession_phase = PossessionPhase::ReboundContest;
                            self.phase_start_tick = self.tick_count;
                            return;
                        } else if *result == ShotResult::Made {
                            let scoring_team = self.possession_team;
                            
                            // ADD POINTS HERE
                            if let Some(ActionType::Shot { shot_type, .. }) = &self.last_action {
                                let points = match shot_type {
                                    ShotType::ThreePointer => 3,
                                    ShotType::TwoPointer | ShotType::Layup | ShotType::Dunk => 2,
                                    ShotType::FreeThrow => 1,
                                };
                                if scoring_team == self.home_team.id {
                                    self.home_score += points;
                                } else {
                                    self.away_score += points;
                                }
                            }
                            if let Some(ref mut l) = self.logger {
                                l.log(self.tick_count, "turnover", "cesta convertida", serde_json::json!({"prev_possession": scoring_team}));
                            }
                            self.reset_playbook();
                            self.reset_intents();

                            self.possession_team = if scoring_team == self.home_team.id { self.away_team.id } else { self.home_team.id };
                            self.clock.reset_shot_clock();

                            let basket_dir = if scoring_team == self.home_team.id { 1.0 } else { -1.0 };
                            let hoop_z = basket_dir * RIM_Z;
                            self.last_landing_pos = Vec2::new(0.0, hoop_z);

                            self.ball_trajectory = Some(BallTrajectory {
                                start_x: 0.0, start_y: 3.05, start_z: hoop_z,
                                apex_x: 0.0, apex_y: 1.6, apex_z: hoop_z,
                                end_x: 0.0, end_y: 0.2, end_z: hoop_z,
                                progress: 0.0, speed: 8.0,
                            });
                            self.trajectory_start_tick = self.tick_count;

                            let is_home = self.possession_team == self.home_team.id;
                            let inbounder_id = {
                                let team = if is_home { &self.home_team } else { &self.away_team };
                                let starters = team.starters();
                                starters.iter().find(|p| p.position == Position::C)
                                    .or_else(|| starters.iter().find(|p| p.position == Position::PF))
                                    .or_else(|| starters.first()).map(|p| p.id).unwrap()
                            };

                            self.rebound_receiver = Some(inbounder_id);
                            self.ball_handler = None;

                            self.possession_phase = PossessionPhase::Inbound;
                            self.phase_start_tick = self.tick_count;
                            return;
                        }
                    }
                    self.possession_phase = PossessionPhase::Inbound;
                    self.phase_start_tick = self.tick_count;
                    self.set_inbounder();
                }
            }

            PossessionPhase::ReboundContest => {
                let mut starters = Vec::new();
                for team in [&self.home_team, &self.away_team] {
                    let is_home = team.id == self.home_team.id;
                    for player in team.starters() {
                        starters.push((player.id, player.current_position, is_home, team.id));
                    }
                }

                if let Some(receiver_id) = self.rebound_receiver {
                    if self.ball_trajectory.is_none() {
                        self.ball_handler = Some(receiver_id);
                        self.rebound_receiver = None;
                        
                        let is_backcourt = {
                            let handler_opt = self.home_team.players.iter().chain(self.away_team.players.iter()).find(|p| p.id == receiver_id);
                            if let Some(handler) = handler_opt {
                                let basket_dir = if self.possession_team == self.home_team.id { 1.0 } else { -1.0 };
                                handler.current_position.y * basket_dir < 0.0
                            } else {
                                false
                            }
                        };
                        
                        self.possession_phase = if is_backcourt { PossessionPhase::BringUp } else { PossessionPhase::Execution };
                        self.phase_start_tick = self.tick_count;
                        self.reset_intents();
                        self.reset_playbook();
                    }
                    return;
                }

                let ball_2d = if let Some(ref traj) = self.ball_trajectory {
                    let elapsed = self.tick_count.saturating_sub(self.trajectory_start_tick);
                    let total_ticks = self.trajectory_ticks(traj).max(1);
                    let t = (elapsed as f32 / total_ticks as f32).min(1.0);
                    let (bx, bz) = if t < 0.5 {
                        let t2 = t * 2.0;
                        (traj.start_x + (traj.apex_x - traj.start_x) * t2, traj.start_z + (traj.apex_z - traj.start_z) * t2)
                    } else {
                        let t2 = (t - 0.5) * 2.0;
                        (traj.apex_x + (traj.end_x - traj.apex_x) * t2, traj.apex_z + (traj.end_z - traj.apex_z) * t2)
                    };
                    Vec2::new(bx, bz)
                } else {
                    self.last_landing_pos
                };

                let mut closest_player = None;
                let mut min_dist = f32::MAX;
                for &(pid, pos, is_home, tid) in &starters {
                    let dist = pos.distance(ball_2d);
                    if dist < min_dist {
                        min_dist = dist;
                        closest_player = Some((pid, is_home, tid, pos));
                    }
                }

                if min_dist < 1.2 {
                    if let Some((rebounder_id, _is_home, team_id, pos)) = closest_player {
                        let is_defensive = team_id != self.possession_team;
                        if is_defensive {
                            self.possession_team = team_id;
                            self.clock.reset_shot_clock();
                        } else {
                            self.clock.reset_shot_clock_offensive();
                        }

                        self.rebound_receiver = Some(rebounder_id);
                        self.ball_trajectory = Some(BallTrajectory {
                            start_x: ball_2d.x, start_y: if self.ball_trajectory.is_some() { 1.5 } else { 0.2 }, start_z: ball_2d.y,
                            apex_x: (ball_2d.x + pos.x) / 2.0, apex_y: 1.4, apex_z: (ball_2d.y + pos.y) / 2.0,
                            end_x: pos.x, end_y: 1.0, end_z: pos.y, progress: 0.0, speed: 6.0,
                        });
                        self.trajectory_start_tick = self.tick_count;

                        let text = if is_defensive { "Rebote defensivo!".to_string() } else { "Rebote ofensivo!".to_string() };
                        let action = ActionType::Rebound { player: rebounder_id, offensive: !is_defensive };
                        if let Some(ref mut l) = self.logger {
                            l.log(self.tick_count, "apply_action", &format!("{:?}", action), json!({}));
                        }
                        let event = self.create_event(action.clone(), text);
                        self.events.push(event);
                        self.last_action = Some(action);
                        return;
                    }
                }

                if self.ball_trajectory.is_none() {
                    if self.loose_ball_ticks < 2 {
                        self.loose_ball_ticks += 1;
                        let bounce_height = if self.loose_ball_ticks == 1 { 1.2 } else { 0.6 };
                        let angle = rng.gen_range(0.0..std::f32::consts::TAU);
                        let bounce_dist = rng.gen_range(0.4..1.0);
                        let start_x = self.last_landing_pos.x;
                        let start_z = self.last_landing_pos.y;
                        let end_x = (start_x + angle.cos() * bounce_dist).clamp(-HALF_WIDTH, HALF_WIDTH);
                        let end_z = (start_z + angle.sin() * bounce_dist).clamp(-HALF_LENGTH, HALF_LENGTH);

                        self.ball_trajectory = Some(BallTrajectory {
                            start_x, start_y: 0.2, start_z,
                            apex_x: (start_x + end_x) / 2.0, apex_y: bounce_height, apex_z: (start_z + end_z) / 2.0,
                            end_x, end_y: 0.2, end_z, progress: 0.0, speed: 4.0,
                        });
                        self.trajectory_start_tick = self.tick_count;
                    }
                }
            }

            PossessionPhase::Inbound => {
                if self.ball_handler.is_none() {
                    if let Some(inbounder_id) = self.rebound_receiver {
                        let is_home = self.possession_team == self.home_team.id;
                        
                        // Calculate current ball 2D position
                        let ball_2d = if let Some(ref traj) = self.ball_trajectory {
                            let elapsed = self.tick_count.saturating_sub(self.trajectory_start_tick);
                            let total_ticks = self.trajectory_ticks(traj).max(1);
                            let t = (elapsed as f32 / total_ticks as f32).min(1.0);
                            let (bx, bz) = if t < 0.5 {
                                let t2 = t * 2.0;
                                (traj.start_x + (traj.apex_x - traj.start_x) * t2, traj.start_z + (traj.apex_z - traj.start_z) * t2)
                            } else {
                                let t2 = (t - 0.5) * 2.0;
                                (traj.apex_x + (traj.end_x - traj.apex_x) * t2, traj.apex_z + (traj.end_z - traj.apex_z) * t2)
                            };
                            Vec2::new(bx, bz)
                        } else {
                            self.last_landing_pos
                        };

                        let team_mut = if is_home { &mut self.home_team } else { &mut self.away_team };
                        if let Some(player) = team_mut.players.iter_mut().find(|p| p.id == inbounder_id) {
                            let dist = player.current_position.distance(ball_2d);
                            if dist < 1.2 {
                                self.ball_handler = Some(inbounder_id);
                                self.rebound_receiver = None;
                                self.ball_trajectory = None;

                                let basket_dir = if is_home { 1.0 } else { -1.0 };
                                if let Some(pos) = self.pending_inbound_pos {
                                    player.current_position.x = pos.x;
                                    player.current_position.y = pos.y;
                                } else {
                                    let inbound_z = -basket_dir * (HALF_LENGTH + 0.5);
                                    player.current_position.x = 0.0;
                                    player.current_position.y = inbound_z;
                                }

                                self.phase_start_tick = self.tick_count; // Reset timer for inbound pass
                            }
                        }
                    }
                    return;
                }

                if elapsed >= 3 {
                    let pg_id = self.find_pg_or_first_starter(self.possession_team);
                    if let (Some(passer_id), Some(target_id)) = (self.ball_handler, pg_id) {
                        let basket_dir = if self.possession_team == self.home_team.id { 1.0 } else { -1.0 };
                        let start_pos = if let Some(pos) = self.pending_inbound_pos { [pos.x, pos.y] } else { [0.0, -basket_dir * HALF_LENGTH] };
                        let target_pos = self.home_team.players.iter().chain(self.away_team.players.iter())
                            .find(|p| p.id == target_id).map_or([0.0, 0.0], |p| [p.current_position.x, p.current_position.y]);
                        let dx = target_pos[0] - start_pos[0];
                        let dz = target_pos[1] - start_pos[1];
                        let dist = (dx * dx + dz * dz).sqrt().max(1.0);
                        let air_time_ms = (dist / 12.0 * 1000.0) as u32;
                        let pass_action = ActionType::Pass { from: passer_id, to: target_id, start_pos, target_pos, air_time_ms, pass_type: PassType::Chest };
                        self.apply_action(pass_action.clone(), self.possession_team == self.home_team.id);
                        self.last_action = Some(pass_action.clone());
                        let text = "Reposicao de bola".to_string();
                        let event = self.create_event(pass_action, text);
                        self.store_trajectory(&event);
                        self.events.push(event);
                    }
                    self.possession_phase = PossessionPhase::BringUp;
                    self.phase_start_tick = self.tick_count;
                }
            }

            PossessionPhase::BringUp => {
                let mut crossed_half_court = false;
                if let Some(handler_id) = self.ball_handler {
                    let home_id = self.home_team.id;
                    let handler_opt = self.home_team.players.iter()
                        .chain(self.away_team.players.iter())
                        .find(|p| p.id == handler_id);
                    if let Some(handler) = handler_opt {
                        let basket_dir = if self.possession_team == home_id { 1.0 } else { -1.0 };
                        if handler.current_position.y * basket_dir >= 0.0 {
                            crossed_half_court = true;
                        }
                    }
                }
                if self.clock.shot_clock <= 15 && !crossed_half_court && self.clock.is_running {
                    let action = ActionType::Turnover { player: self.ball_handler.unwrap_or(0), reason: "Violacao de 8 segundos".to_string() };
                    self.apply_action(action.clone(), self.possession_team == self.home_team.id);
                    let event = self.create_event(action, "Violacao de 8 Segundos!".to_string());
                    self.store_trajectory(&event);
                    self.events.push(event);
                    return;
                }

                if crossed_half_court || elapsed >= 40 {
                    self.possession_phase = PossessionPhase::Execution;
                    self.phase_start_tick = self.tick_count;
                }
            }
            PossessionPhase::Execution => {
                if let Some(handler_id) = self.ball_handler {
                    let home_id = self.home_team.id;
                    let handler_opt = self.home_team.players.iter()
                        .chain(self.away_team.players.iter())
                        .find(|p| p.id == handler_id);
                    if let Some(handler) = handler_opt {
                        let basket_dir = if self.possession_team == home_id { 1.0 } else { -1.0 };
                        if handler.current_position.y * basket_dir < -0.5 {
                            let action = ActionType::Turnover { player: handler_id, reason: "Voltou a bola pra defesa".to_string() };
                            self.apply_action(action.clone(), self.possession_team == self.home_team.id);
                            let event = self.create_event(action, "Violacao de Quadra (Backcourt)!".to_string());
                            self.store_trajectory(&event);
                            self.events.push(event);
                            return;
                        }
                    }
                }
            }
        }
    }

    fn phase_event_text(&self) -> String {
        match self.possession_phase {
            PossessionPhase::JumpBall => "Bola ao alto!".to_string(),
            PossessionPhase::ShotInAir => String::new(),
            PossessionPhase::Inbound => "Reposicao de bola".to_string(),
            PossessionPhase::BringUp => "Armando jogada".to_string(),
            PossessionPhase::Execution => String::new(),
            PossessionPhase::ReboundContest => String::new(),
        }
    }

    fn compute_ball_for_phase(&self, positions: &[PlayerPosition]) -> BallState {
        match self.possession_phase {
            PossessionPhase::JumpBall => {
                BallState { x: 0.0, y: 1.0, z: 0.0, holder: None, carrier_id: None, trajectory: None }
            }
            PossessionPhase::Inbound => {
                let basket_dir = if self.possession_team == self.home_team.id { 1.0 } else { -1.0 };
                let (ix, iz) = self.ball_handler.and_then(|id| positions.iter().find(|p| p.player_id == id))
                    .map_or((0.0, -basket_dir * HALF_LENGTH), |p| (p.x, p.z));
                BallState { x: ix, y: 1.0, z: iz, holder: self.ball_handler, carrier_id: self.ball_handler, trajectory: None }
            }
            PossessionPhase::ShotInAir | PossessionPhase::BringUp | PossessionPhase::Execution | PossessionPhase::ReboundContest => {
                self.compute_ball_for_idle_tick(positions)
            }
        }
    }

    fn create_event(&self, action: ActionType, text: String) -> MatchEvent {
        let q = match self.clock.quarter {
            1 => "1Q".to_string(), 2 => "2Q".to_string(), 3 => "3Q".to_string(), 4 => "4Q".to_string(),
            n => format!("OT{}", n - 4),
        };
        let positions = self.movement_sys.to_player_positions(
            &self.home_team, &self.away_team, self.possession_team, self.ball_handler);
        let mut ball = movement::calculate_ball_state(
            &self.home_team, &self.away_team, self.possession_team, self.ball_handler,
            &positions, &action, self.tick_count);
        if ball.trajectory.is_none() { ball = self.compute_ball_for_phase(&positions); }

        MatchEvent {
            tick: self.tick_count, action,
            score: ScoreSnapshot {
                home: self.home_score, away: self.away_score, quarter: q,
                clock_seconds: self.clock.total_seconds, shot_clock: self.clock.shot_clock,
                home_fouls: self.home_fouls_quarter, away_fouls: self.away_fouls_quarter,
            },
            positions, ball, text,
        }
    }

    pub fn simulate_full(&mut self) -> Vec<MatchEvent> {
        while !self.is_over { self.tick(); }
        self.events.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn check_score_pace() {
        let home = Team::generate(1, "Lakers", "Los Angeles", "LAL", 80.0);
        let away = Team::generate(2, "Celtics", "Boston", "BOS", 78.0);
        let mut sim = MatchSimulator::new(home, away);
        sim.simulate_full();
        println!("FINAL: {} {} x {} {} ({} ticks)", sim.home_team.city, sim.home_score, sim.away_score, sim.away_team.city, sim.tick_count);
        assert!(sim.home_score > 0 || sim.away_score > 0);
    }

    #[test]
    fn generate_calibration_baseline() {
        let cal_dir = "target/calibration";
        fs::create_dir_all(cal_dir).ok();
        let home = Team::generate(1, "Lakers", "Los Angeles", "LAL", 80.0);
        let away = Team::generate(2, "Celtics", "Boston", "BOS", 78.0);
        let mut sim = MatchSimulator::new(home, away);
        sim.start_logging(&format!("{}/match.simlog", cal_dir), &format!("{}/match.calibration.json", cal_dir));
        sim.simulate_full();
        assert!(sim.is_over);
        assert!(std::path::Path::new(&format!("{}/match.simlog", cal_dir)).exists());
        assert!(std::path::Path::new(&format!("{}/match.calibration.json", cal_dir)).exists());
    }
}
