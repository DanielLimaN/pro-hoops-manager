use rand::Rng;
use crate::engine::types::*;

pub struct CoachAI;

impl CoachAI {
    pub fn adjust_tactic(team: &Team, opponent: &Team, score_diff: i16, quarter: u8, clock: u16) -> TacticConfig {
        let mut rng = rand::thread_rng();
        let mut tactic = team.tactic.clone();

        if score_diff < -10 {
            tactic.pace = (tactic.pace + 15.0).min(100.0);
            tactic.three_frequency = (tactic.three_frequency + 20.0).min(100.0);
        } else if score_diff > 10 {
            tactic.pace = (tactic.pace - 10.0).max(0.0);
        }

        if quarter >= 4 && clock <= 120 {
            if score_diff < 0 {
                tactic.three_frequency = 80.0;
                tactic.pace = 90.0;
            } else if score_diff > 0 && clock <= 30 {
                tactic.pace = 10.0;
            }
        }

        let opp_three_avg: f32 = opponent.players.iter().map(|p| p.attributes.three_pt).sum::<f32>() / opponent.players.len() as f32;
        if opp_three_avg > 75.0 { tactic.defensive = DefensiveTactic::Zone2_3; }

        tactic.three_frequency += rng.gen_range(-5.0..5.0);
        tactic.pace += rng.gen_range(-5.0..5.0);
        tactic
    }

    pub fn suggest_substitution(team: &Team, fatigue_threshold: f32, _foul_trouble: u8) -> Vec<(PlayerId, PlayerId)> {
        let mut subs = Vec::new();
        let starters = team.starters();
        for starter in &starters {
            let fatigue = 100.0 - starter.attributes.stamina;
            if fatigue > fatigue_threshold {
                if let Some(bench_player) = team.players.iter()
                    .filter(|p| !starters.iter().any(|s| s.id == p.id))
                    .filter(|p| p.position == starter.position)
                    .max_by(|a, b| a.attributes.overall().partial_cmp(&b.attributes.overall()).unwrap())
                {
                    subs.push((starter.id, bench_player.id));
                }
            }
        }
        subs
    }
}
