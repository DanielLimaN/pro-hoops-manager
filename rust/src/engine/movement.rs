use rand::Rng;
use glam::Vec2;
use crate::engine::types::*;

const HALF_LENGTH: f32 = 15.525;
const HALF_WIDTH: f32 = 7.62;
const RIM_Z: f32 = 14.325;
const SEPARATION_PADDING: f32 = 0.15;

pub struct MovementSystem;

impl MovementSystem {
    pub fn new() -> Self { Self }

    pub fn update_positions(
        &mut self, home_team: &mut Team, away_team: &mut Team,
        possession_team: TeamId, _ball_handler: Option<PlayerId>, dt: f32,
    ) {
        let home_ids: Vec<PlayerId> = home_team.starters().iter().map(|p| p.id).collect();
        let away_ids: Vec<PlayerId> = away_team.starters().iter().map(|p| p.id).collect();

        let home_is_defense = possession_team != home_team.id;
        let away_is_defense = possession_team != away_team.id;

        move_starter_group(&mut home_team.players, &home_ids, dt, home_is_defense);
        move_starter_group(&mut away_team.players, &away_ids, dt, away_is_defense);
        separate_across_teams(&mut home_team.players, &mut away_team.players, &home_ids, &away_ids);
    }

    pub fn to_player_positions(
        &self, home_team: &Team, away_team: &Team,
        possession_team: TeamId, _ball_handler: Option<PlayerId>,
    ) -> Vec<PlayerPosition> {
        let mut positions = Vec::with_capacity(10);
        for team in [home_team, away_team] {
            let is_off = team.id == possession_team;
            for i in 0..5 {
                let p = &team.starters()[i];
                let pos = p.current_position;
                
                let jump_y = match p.intent {
                    PlayerIntent::Shoot { ticks_left, .. } => {
                        let t = ticks_left.min(10) as f32;
                        (t * (10.0 - t)).max(0.0) * 0.04
                    }
                    PlayerIntent::Block { ticks_left, .. } => {
                        let t = ticks_left.min(5) as f32;
                        (t * (5.0 - t)).max(0.0) * 0.3
                    }
                    _ => 0.0,
                };
                let mut angle = p.angle;
                if p.velocity.length_squared() > 0.1 {
                    angle = p.velocity.y.atan2(p.velocity.x);
                } else if let PlayerIntent::Pass { target, .. } = p.intent {
                    // Find target in either team
                    let target_pos = home_team.players.iter()
                        .chain(away_team.players.iter())
                        .find(|tp| tp.id == target)
                        .map(|tp| tp.current_position);
                    if let Some(tpos) = target_pos {
                        let dir = tpos - p.current_position;
                        if dir.length_squared() > 0.001 {
                            angle = dir.y.atan2(dir.x);
                        }
                    }
                } else if let PlayerIntent::Shoot { .. } = p.intent {
                    let basket_dir = if team.id == home_team.id { 1.0 } else { -1.0 };
                    let hoop_pos = glam::Vec2::new(0.0, basket_dir * RIM_Z);
                    let dir = hoop_pos - p.current_position;
                    if dir.length_squared() > 0.001 {
                        angle = dir.y.atan2(dir.x);
                    }
                }

                positions.push(PlayerPosition {
                    player_id: p.id, x: pos.x, z: pos.y, y: jump_y, angle,
                    animation: if is_off { "offense".to_string() } else { "defense".to_string() },
                });
            }
        }
        positions
    }
}

fn clamp_to_court(pos: &mut Vec2) {
    pos.x = pos.x.clamp(-HALF_WIDTH, HALF_WIDTH);
    pos.y = pos.y.clamp(-HALF_LENGTH, HALF_LENGTH);
}
fn move_starter_group(players: &mut [Player], starter_ids: &[PlayerId], dt: f32, is_defense: bool) {
    for &pid in starter_ids {
        if let Some(player) = players.iter_mut().find(|p| p.id == pid) {
            match player.intent {
                PlayerIntent::Shoot { .. } | PlayerIntent::Pass { .. } => {
                    player.velocity = Vec2::ZERO;
                    player.locomotion_state = LocomotionState::Idle;
                    continue;
                }
                _ => {}
            }
            let current = player.current_position;
            let mut target = player.target_position;
            clamp_to_court(&mut target);
            let dist = current.distance(target);
            if dist < 0.1 {
                player.velocity = player.velocity.lerp(Vec2::ZERO, 0.2);
                update_locomotion(player, player.velocity, is_defense);
                continue;
            }
            let max_speed = player.attributes.speed / 100.0 * 8.0;
            let desired_speed = if dist < 2.0 { max_speed * (dist / 2.0) } else { max_speed };
            let desired_vel = (target - current).normalize_or_zero() * desired_speed;
            let steering = desired_vel - player.velocity;
            let max_force = player.attributes.strength / 100.0 * 15.0;
            let steering = steering.clamp_length_max(max_force);
            let mass = player.attributes.weight_kg / 100.0;
            let acceleration = steering / mass;
            player.velocity = (player.velocity + acceleration * dt).clamp_length_max(max_speed);
            player.current_position = current + player.velocity * dt;
            clamp_to_court(&mut player.current_position);
            update_locomotion(player, player.velocity, is_defense);
        }
    }
}

fn separate_across_teams(
    home_players: &mut [Player], away_players: &mut [Player],
    home_ids: &[PlayerId], away_ids: &[PlayerId],
) {
    for &hid in home_ids {
        let (h_pos, h_radius, _) = match home_players.iter().find(|p| p.id == hid) {
            Some(p) => (p.current_position, p.radius, p.velocity),
            None => continue,
        };
        for &aid in away_ids {
            let (a_pos, a_radius, _) = match away_players.iter().find(|p| p.id == aid) {
                Some(p) => (p.current_position, p.radius, p.velocity),
                None => continue,
            };
            let dist = h_pos.distance(a_pos);
            let min_dist = h_radius + a_radius + SEPARATION_PADDING;
            if dist >= min_dist || dist < 0.001 { continue; }
            let overlap = min_dist - dist;
            let dir = (a_pos - h_pos).normalize_or_zero();
            let push_force = dir * overlap * 0.8;
            if let Some(hp) = home_players.iter_mut().find(|p| p.id == hid) {
                hp.current_position -= push_force * 0.5;
                clamp_to_court(&mut hp.current_position);
                hp.velocity = hp.velocity - dir * hp.velocity.dot(dir) * 0.5;
            }
            if let Some(ap) = away_players.iter_mut().find(|p| p.id == aid) {
                ap.current_position += push_force * 0.5;
                clamp_to_court(&mut ap.current_position);
                ap.velocity = ap.velocity - dir * ap.velocity.dot(dir) * 0.5;
            }
        }
    }
}

fn position_index(pos: &Position) -> usize {
    match pos {
        Position::PG => 0,
        Position::SG => 1,
        Position::SF => 2,
        Position::PF => 3,
        Position::C => 4,
    }
}

fn init_team_positions(team: &mut Team, off_starter_ids: &[PlayerId], off_formation: &[(f32, f32); 5], tactic: &TacticConfig, dir: f32) {
    let def_f = defensive_formation(&tactic.defensive, off_formation);
    let starters_data: Vec<(PlayerId, Position)> = team.starters().iter().map(|p| (p.id, p.position.clone())).collect();
    for (pid, pos) in starters_data {
        let is_off = off_starter_ids.contains(&pid);
        let idx = position_index(&pos);
        let target = if is_off {
            let f = off_formation[idx];
            Vec2::new(f.0 * dir, f.1 * dir)
        } else {
            let f = def_f[idx];
            Vec2::new(f.0 * -dir, f.1 * -dir)
        };
        let player = team.players.iter_mut().find(|p| p.id == pid).unwrap();
        player.current_position = target;
        player.target_position = target;
    }
}

fn update_locomotion(player: &mut Player, vel: Vec2, is_defense: bool) {
    let speed = vel.length();
    if speed < 0.1 && is_defense {
        player.locomotion_state = LocomotionState::DefendingStationary;
        player.ticks_established += 1;
    } else if speed < 0.1 {
        player.locomotion_state = LocomotionState::Idle;
        player.ticks_established = 0;
    } else {
        player.locomotion_state = LocomotionState::Sprinting;
        player.ticks_established = 0;
    }
}

pub fn offensive_formation(tactic: &OffensiveTactic, _handler_idx: usize) -> [(f32, f32); 5] {
    match tactic {
        OffensiveTactic::PickAndRoll => [(-1.0, 8.0), (3.0, 5.0), (-3.0, 4.0), (2.0, 2.0), (0.0, 3.0)],
        OffensiveTactic::Isolation => [(0.0, 8.0), (4.0, 2.0), (-4.0, 2.0), (3.0, 1.0), (-2.0, 1.0)],
        OffensiveTactic::PostUp => [(-2.0, 7.0), (3.0, 7.0), (-4.0, 3.0), (0.0, 3.5), (2.0, 1.0)],
        OffensiveTactic::Princeton => [(0.0, 8.0), (3.5, 6.0), (-3.5, 6.0), (0.0, 5.0), (2.0, 2.0)],
        OffensiveTactic::Triangle => [(-2.0, 8.0), (4.0, 6.0), (-3.0, 4.0), (0.0, 5.5), (2.5, 1.5)],
        OffensiveTactic::Motion => [(-2.0, 8.0), (3.0, 6.0), (-3.0, 5.0), (2.0, 3.0), (-1.0, 2.0)],
        OffensiveTactic::SevenSeconds => [(0.0, 6.5), (4.5, 8.0), (-4.5, 8.0), (-2.0, 12.0), (2.0, 12.0)],
    }
}

pub fn defensive_formation(tactic: &DefensiveTactic, offense: &[(f32, f32); 5]) -> [(f32, f32); 5] {
    match tactic {
        DefensiveTactic::ManToMan => [
            (offense[0].0, (offense[0].1 - 0.8).max(0.5)),
            (offense[1].0, (offense[1].1 - 0.8).max(0.5)),
            (offense[2].0, (offense[2].1 - 0.8).max(0.5)),
            (offense[3].0, (offense[3].1 - 0.8).max(0.5)),
            (offense[4].0, (offense[4].1 - 0.8).max(0.5)),
        ],
        DefensiveTactic::Zone2_3 => [(0.0, 7.0), (3.0, 5.5), (0.0, 3.5), (2.5, 1.5), (-2.5, 1.5)],
        DefensiveTactic::Zone3_2 => [(0.0, 8.0), (3.5, 6.5), (-3.5, 6.5), (2.0, 2.5), (-2.0, 2.5)],
        DefensiveTactic::FullCourtPress => [(0.0, 12.5), (3.0, 11.0), (-3.0, 11.0), (2.0, 8.0), (-1.5, 7.0)],
        DefensiveTactic::HalfCourtTrap => [(0.0, 9.0), (3.0, 8.0), (-3.0, 6.0), (2.0, 3.0), (-1.5, 1.5)],
        DefensiveTactic::BoxAndOne => [(0.0, 7.5), (3.0, 4.5), (-3.0, 4.5), (2.0, 2.0), (-2.0, 2.0)],
    }
}

pub fn init_player_positions(
    home_team: &mut Team, away_team: &mut Team,
    possession_team: TeamId, ball_handler: Option<PlayerId>, tactic: &TacticConfig,
) {
    let is_home_off = possession_team == home_team.id;
    let off_starter_ids: Vec<PlayerId> = if is_home_off {
        home_team.starters().iter().map(|p| p.id).collect()
    } else {
        away_team.starters().iter().map(|p| p.id).collect()
    };
    let handler_idx = ball_handler.and_then(|id| off_starter_ids.iter().position(|&pid| pid == id)).unwrap_or(0);
    let off_formation = offensive_formation(&tactic.offensive, handler_idx);
    let dir = if is_home_off { 1.0 } else { -1.0 };
    init_team_positions(home_team, &off_starter_ids, &off_formation, tactic, dir);
    init_team_positions(away_team, &off_starter_ids, &off_formation, tactic, dir);
}

pub fn calculate_ball_state(
    home_team: &Team, _away_team: &Team,
    _possession_team: TeamId, ball_handler: Option<PlayerId>,
    positions: &[PlayerPosition], last_action: &ActionType, tick_count: u64,
) -> BallState {
    let handler_pos = ball_handler.and_then(|id| positions.iter().find(|p| p.player_id == id));
    let hand_x = handler_pos.map_or(0.0, |p| p.x);
    let hand_z = handler_pos.map_or(0.0, |p| p.z);

    match last_action {
        ActionType::Shot { player, shot_type: _, result, distance: _ } => {
            let is_home = home_team.players.iter().any(|p| p.id == *player);
            let direction = if is_home { 1.0 } else { -1.0 };
            let shooter_pos = positions.iter().find(|p| p.player_id == *player);
            let sx = shooter_pos.map_or(0.0, |p| p.x);
            let sz = shooter_pos.map_or(0.0, |p| p.z);
            if *result == ShotResult::Made {
                let rim_z = direction * RIM_Z;
                BallState {
                    x: 0.0, y: 3.0, z: rim_z, holder: None, carrier_id: None,
                    trajectory: Some(BallTrajectory {
                        start_x: sx, start_y: 1.5, start_z: sz,
                        apex_x: hand_x / 2.0, apex_y: 5.0, apex_z: (hand_z + rim_z) / 2.0,
                        end_x: 0.0, end_y: 3.05, end_z: rim_z, progress: 0.0, speed: 8.0,
                    }),
                }
            } else if *result == ShotResult::Blocked {
                let mut rng = rand::thread_rng();
                let rim_z = direction * RIM_Z;
                let to_rim_x = 0.0 - sx;
                let to_rim_z = rim_z - sz;
                let dist = (to_rim_x * to_rim_x + to_rim_z * to_rim_z).sqrt().max(1.0);
                let block_dist = 1.5f32.min(dist * 0.5);
                let bx = sx + (to_rim_x / dist) * block_dist;
                let bz = sz + (to_rim_z / dist) * block_dist;
                
                let angle = rng.gen_range(0.0..std::f32::consts::TAU);
                let def_dist = rng.gen_range(2.0..6.0);
                let end_x = (bx + angle.cos() * def_dist).clamp(-HALF_WIDTH, HALF_WIDTH);
                let end_z = (bz + angle.sin() * def_dist).clamp(-HALF_LENGTH, HALF_LENGTH);

                BallState {
                    x: sx, y: 1.5, z: sz, holder: None, carrier_id: None,
                    trajectory: Some(BallTrajectory {
                        start_x: sx, start_y: 1.5, start_z: sz,
                        apex_x: bx, apex_y: 2.8, apex_z: bz,
                        end_x, end_y: 0.2, end_z, progress: 0.0, speed: 10.0,
                    }),
                }
            } else {
                let mut rng = rand::thread_rng();
                let rim_z = direction * RIM_Z;
                let angle = rng.gen_range(0.0..std::f32::consts::TAU);
                let rebound_dist = rng.gen_range(1.5..5.0);
                let end_x = (angle.cos() * rebound_dist).clamp(-HALF_WIDTH, HALF_WIDTH);
                let end_z = (rim_z + angle.sin() * rebound_dist).clamp(-HALF_LENGTH, HALF_LENGTH);
                
                BallState {
                    x: sx, y: 1.5, z: sz, holder: None, carrier_id: None,
                    trajectory: Some(BallTrajectory {
                        start_x: sx, start_y: 1.5, start_z: sz,
                        apex_x: 0.0, apex_y: 4.5, apex_z: rim_z,
                        end_x, end_y: 0.3, end_z, progress: 0.0, speed: 8.0,
                    }),
                }
            }
        }
        ActionType::Pass { from: _, to, start_pos, target_pos, air_time_ms: _, pass_type } => {
            let sx = start_pos[0]; let sz = start_pos[1];
            let ex = target_pos[0]; let ez = target_pos[1];
            
            let (start_y, apex_y, end_y, speed) = match pass_type {
                crate::engine::types::PassType::Chest => (1.2, 1.2, 1.1, 18.0),
                crate::engine::types::PassType::Bounce => (1.0, 0.0, 0.8, 12.0),
                crate::engine::types::PassType::Lob => (2.0, 3.5, 1.8, 8.0),
            };

            BallState {
                x: sx, y: start_y, z: sz, holder: Some(*to), carrier_id: None,
                trajectory: Some(BallTrajectory {
                    start_x: sx, start_y, start_z: sz,
                    apex_x: (sx + ex) / 2.0, apex_y, apex_z: (sz + ez) / 2.0,
                    end_x: ex, end_y, end_z: ez, progress: 0.0, speed,
                }),
            }
        }
        ActionType::FreeThrow { player, result } => {
            let is_home = home_team.players.iter().any(|p| p.id == *player);
            let direction = if is_home { 1.0 } else { -1.0 };
            let ft_z = direction * (HALF_LENGTH - 5.8);
            if *result == ShotResult::Made {
                BallState { x: 0.0, y: 0.0, z: ft_z, holder: None, carrier_id: None, trajectory: None }
            } else {
                BallState { x: 0.5, y: 0.3, z: ft_z + 0.5, holder: None, carrier_id: None, trajectory: None }
            }
        }
        _ => {
            BallState {
                x: hand_x, y: if tick_count % 10 < 5 { 1.0 } else { 1.2 }, z: hand_z,
                holder: ball_handler, carrier_id: ball_handler, trajectory: None,
            }
        }
    }
}
