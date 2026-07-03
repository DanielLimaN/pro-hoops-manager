use rand::Rng;
use glam::Vec2;
use crate::engine::types::*;

pub fn detect_and_resolve_collisions(
    home_team: &mut Team,
    away_team: &mut Team,
    ball_handler_id: Option<PlayerId>,
    rng: &mut impl Rng,
) -> Option<ActionType> {
    struct PairData { h_idx: usize, a_idx: usize, overlap: f32, dir: Vec2 }
    let mut pushes: Vec<PairData> = Vec::new();

    for i in 0..5 {
        let h_id = home_team.starters()[i].id;
        let h_pos = home_team.players.iter().find(|p| p.id == h_id).unwrap().current_position;
        let h_radius = home_team.players.iter().find(|p| p.id == h_id).unwrap().radius;
        let h_loco = home_team.players.iter().find(|p| p.id == h_id).unwrap().locomotion_state;
        let h_vel = home_team.players.iter().find(|p| p.id == h_id).unwrap().velocity;
        let h_established = home_team.players.iter().find(|p| p.id == h_id).unwrap().ticks_established;

        for j in 0..5 {
            let a_id = away_team.starters()[j].id;
            let a_pos = away_team.players.iter().find(|p| p.id == a_id).unwrap().current_position;
            let a_radius = away_team.players.iter().find(|p| p.id == a_id).unwrap().radius;
            let a_loco = away_team.players.iter().find(|p| p.id == a_id).unwrap().locomotion_state;
            let a_vel = away_team.players.iter().find(|p| p.id == a_id).unwrap().velocity;
            let a_established = away_team.players.iter().find(|p| p.id == a_id).unwrap().ticks_established;

            let dist = h_pos.distance(a_pos);
            let min_dist = h_radius + a_radius;
            if dist >= min_dist { continue; }

            if let Some(bh) = ball_handler_id {
                if bh == h_id {
                    if a_loco == LocomotionState::DefendingStationary && a_established > 5 {
                        let atk_dribble = home_team.players.iter().find(|p| p.id == h_id).unwrap().dna.dribbling as f32 / 20.0;
                        let def_iq = away_team.players.iter().find(|p| p.id == a_id).unwrap().attributes.perimeter_def / 100.0;
                        let charge_prob = def_iq / ((def_iq + atk_dribble) / 2.0) * 0.5;
                        if rng.gen::<f32>() < charge_prob {
                            return Some(ActionType::OffensiveFoul { offender: h_id, defender: a_id });
                        }
                    }
                    
                    let def_reach = away_team.players.iter().find(|p| p.id == a_id).unwrap().attributes.steal / 100.0;
                    let atk_protect = home_team.players.iter().find(|p| p.id == h_id).unwrap().attributes.ball_handle / 100.0;
                    let foul_prob = def_reach / ((def_reach + atk_protect) / 2.0) * 0.05;
                    if rng.gen::<f32>() < foul_prob {
                        let is_shooting = match home_team.players.iter().find(|p| p.id == h_id).unwrap().intent {
                            PlayerIntent::Shoot { .. } => true,
                            _ => false,
                        };
                        return Some(ActionType::Foul { defender: a_id, offender: h_id, shooting: is_shooting, personal: true });
                    }
                }
                if bh == a_id {
                    if h_loco == LocomotionState::DefendingStationary && h_established > 5 {
                        let atk_dribble = away_team.players.iter().find(|p| p.id == a_id).unwrap().dna.dribbling as f32 / 20.0;
                        let def_iq = home_team.players.iter().find(|p| p.id == h_id).unwrap().attributes.perimeter_def / 100.0;
                        let charge_prob = def_iq / ((def_iq + atk_dribble) / 2.0) * 0.5;
                        if rng.gen::<f32>() < charge_prob {
                            return Some(ActionType::OffensiveFoul { offender: a_id, defender: h_id });
                        }
                    }
                    
                    let def_reach = home_team.players.iter().find(|p| p.id == h_id).unwrap().attributes.steal / 100.0;
                    let atk_protect = away_team.players.iter().find(|p| p.id == a_id).unwrap().attributes.ball_handle / 100.0;
                    let foul_prob = def_reach / ((def_reach + atk_protect) / 2.0) * 0.05;
                    if rng.gen::<f32>() < foul_prob {
                        let is_shooting = match away_team.players.iter().find(|p| p.id == a_id).unwrap().intent {
                            PlayerIntent::Shoot { .. } => true,
                            _ => false,
                        };
                        return Some(ActionType::Foul { defender: h_id, offender: a_id, shooting: is_shooting, personal: true });
                    }
                }
            }

            if h_loco == LocomotionState::Screening && h_vel.length() > 0.1 {
                return Some(ActionType::IllegalScreen { screen_setter: h_id, defender: a_id });
            }
            if a_loco == LocomotionState::Screening && a_vel.length() > 0.1 {
                return Some(ActionType::IllegalScreen { screen_setter: a_id, defender: h_id });
            }

            let overlap = min_dist - dist;
            let dir = (a_pos - h_pos).normalize_or_zero();
            pushes.push(PairData { h_idx: i, a_idx: j, overlap, dir });
        }
    }

    for pd in &pushes {
        let h_id = home_team.starters()[pd.h_idx].id;
        let a_id = away_team.starters()[pd.a_idx].id;
        let push = pd.dir * pd.overlap * 0.5;
        if let Some(hp) = home_team.players.iter_mut().find(|p| p.id == h_id) {
            hp.current_position -= push;
            clamp_to_court(&mut hp.current_position);
        }
        if let Some(ap) = away_team.players.iter_mut().find(|p| p.id == a_id) {
            ap.current_position += push;
            clamp_to_court(&mut ap.current_position);
        }
    }

    None
}

const HALF_LENGTH: f32 = 15.525;
const HALF_WIDTH: f32 = 7.62;

fn clamp_to_court(pos: &mut Vec2) {
    pos.x = pos.x.clamp(-HALF_WIDTH, HALF_WIDTH);
    pos.y = pos.y.clamp(-HALF_LENGTH, HALF_LENGTH);
}
