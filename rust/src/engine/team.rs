use rand::Rng;
use std::collections::HashSet;
use crate::engine::types::*;
use crate::engine::player::generate_player;

impl Team {
    pub fn generate(id: TeamId, name: &str, city: &str, abbreviation: &str, rating: f32, used_names: &mut HashSet<String>) -> Self {
        let mut rng = rand::thread_rng();
        let mut players = Vec::new();
        let mut player_id = id * 100;

        for pos in Position::list() {
            let starter_ovr = rating + rng.gen_range(-5.0..10.0);
            players.push(generate_player(player_id, pos.clone(), starter_ovr, used_names));
            player_id += 1;

            let bench_ovr = rating - rng.gen_range(5.0..15.0);
            players.push(generate_player(player_id, pos.clone(), bench_ovr, used_names));
            player_id += 1;
        }

        for _ in 0..5 {
            let pos = Position::list()[rng.gen_range(0..5)].clone();
            let bench_ovr = rating - rng.gen_range(10.0..20.0);
            players.push(generate_player(player_id, pos, bench_ovr, used_names));
            player_id += 1;
        }

        Self {
            id,
            name: name.to_string(),
            city: city.to_string(),
            abbreviation: abbreviation.to_string(),
            players,
            tactic: TacticConfig::default(),
            chemistry: rng.gen_range(30.0..90.0),
            wins: 0,
            losses: 0,
            training_focus: TrainingFocus::default(),
        }
    }

    pub fn starters(&self) -> Vec<&Player> {
        let mut sorted: Vec<&Player> = self.players.iter().collect();
        sorted.sort_by(|a, b| b.attributes.overall().partial_cmp(&a.attributes.overall()).unwrap());
        let mut starters = Vec::new();
        let mut used_positions = std::collections::HashSet::new();

        for player in &sorted {
            if used_positions.contains(&player.position) {
                continue;
            }
            if starters.len() >= 5 {
                break;
            }
            used_positions.insert(player.position.clone());
            starters.push(*player);
        }

        for player in &sorted {
            if starters.len() >= 5 { break; }
            if !starters.iter().any(|p| p.id == player.id) {
                starters.push(*player);
            }
        }

        starters
    }

    pub fn best_lineup(&self, _tactic: &TacticConfig) -> Vec<PlayerId> {
        self.starters().iter().map(|p| p.id).collect()
    }
}
