use rand::Rng;
use crate::engine::types::*;

pub fn resolve_rebound(
    rebounding_team: &mut Team,
    other_team: &mut Team,
    rebound_pos: (f32, f32),
) -> (PlayerId, bool) {
    let mut rng = rand::thread_rng();
    let mut candidates: Vec<(PlayerId, f32, bool)> = Vec::new();

    for team in [&*rebounding_team, &*other_team] {
        let is_rebounding = team.id == rebounding_team.id;
        for player in team.starters() {
            match player.intent {
                PlayerIntent::Rebound { .. } | PlayerIntent::BoxOut { .. } | PlayerIntent::Idle => {
                    let dist = player.current_position.distance(glam::Vec2::new(rebound_pos.0, rebound_pos.1));
                    let base_stat = if is_rebounding { player.attributes.defensive_rebound } else { player.attributes.offensive_rebound };
                    let score = player.attributes.height_cm * 0.4
                        + player.attributes.jumping * 0.3
                        + base_stat * 0.3
                        - (dist * dist * 15.0);
                    let score = score.max(0.1);
                    candidates.push((player.id, score, is_rebounding));
                }
                _ => {}
            }
        }
    }

    if candidates.is_empty() {
        return (rebounding_team.starters()[0].id, true);
    }

    let total_score: f32 = candidates.iter().map(|c| c.1).sum();
    let mut roll = rng.gen::<f32>() * total_score;
    for (id, score, is_offensive) in &candidates {
        if roll < *score {
            return (*id, *is_offensive);
        }
        roll -= *score;
    }
    let last = candidates.last().unwrap();
    (last.0, last.2)
}

pub fn calculate_rebound_position(shot_x: f32, shot_z: f32, _missed: bool) -> (f32, f32) {
    if _missed {
        let angle = rand::thread_rng().gen_range(0.0..std::f32::consts::TAU);
        let dist = rand::thread_rng().gen_range(1.0..4.0);
        (shot_x + angle.cos() * dist, shot_z + angle.sin() * dist)
    } else {
        (0.0, 0.0)
    }
}
