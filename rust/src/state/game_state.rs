use serde::{Deserialize, Serialize};
use crate::engine::types::*;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GameState {
    pub league: Option<League>,
    pub current_match: Option<MatchState>,
    pub user_team_id: Option<TeamId>,
    pub date: GameDate,
    pub settings: GameSettings,
    pub coach: Option<crate::engine::manager::CoachProfile>,
    pub staff: Vec<crate::engine::manager::Staff>,
    pub inbox: Vec<crate::engine::manager::InboxMessage>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameDate {
    pub year: u16,
    pub month: u8,
    pub day: u8,
}

impl Default for GameDate {
    fn default() -> Self {
        Self { year: 2025, month: 10, day: 1 }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameSettings {
    pub quarter_length: u8,
    pub simulation_speed: f32,
    pub sound_enabled: bool,
    pub auto_save: bool,
}

impl Default for GameSettings {
    fn default() -> Self {
        Self { quarter_length: 12, simulation_speed: 1.0, sound_enabled: true, auto_save: true }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchState {
    pub home_team_id: TeamId,
    pub away_team_id: TeamId,
    pub home_score: u16,
    pub away_score: u16,
    pub quarter: u8,
    pub clock_seconds: u16,
    pub shot_clock: u8,
    pub is_simulating: bool,
    pub speed: f32,
}
