use serde::{Deserialize, Serialize};
use std::hash::Hash;
use glam::Vec2;

pub type PlayerId = u32;
pub type TeamId = u32;
pub type GameId = u32;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum Position {
    PG,
    SG,
    SF,
    PF,
    C,
}

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub enum LocomotionState {
    #[default]
    Idle,
    Sprinting,
    LateralSliding,
    DefendingStationary,
    Screening,
    PostUpEngaged,
}

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub enum PossessionPhase {
    #[default]
    Execution,
    JumpBall,
    ShotInAir,
    ReboundContest,
    Inbound,
    BringUp,
}

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub enum PlayStage {
    #[default]
    Inception,
    Execution,
    Resolution,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivePlay {
    pub tactic: OffensiveTactic,
    pub stage: PlayStage,
    pub ticks_in_stage: u32,
    pub screen_anchor_index: Option<usize>,
}

impl ActivePlay {
    pub fn new(tactic: OffensiveTactic) -> Self {
        Self { tactic, stage: PlayStage::Inception, ticks_in_stage: 0, screen_anchor_index: None }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum PassType {
    Chest,
    Bounce,
    Lob,
}

impl Position {
    pub fn list() -> &'static [Position] {
        &[Position::PG, Position::SG, Position::SF, Position::PF, Position::C]
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerAttributes {
    pub speed: f32,
    pub strength: f32,
    pub stamina: f32,
    pub jumping: f32,
    pub height_cm: f32,
    pub weight_kg: f32,
    pub wingspan_cm: f32,
    pub three_pt: f32,
    pub mid_range: f32,
    pub close_shot: f32,
    pub dunk: f32,
    pub layup: f32,
    pub free_throw: f32,
    pub ball_handle: f32,
    pub passing: f32,
    pub offensive_rebound: f32,
    pub perimeter_def: f32,
    pub interior_def: f32,
    pub steal: f32,
    pub block: f32,
    pub defensive_rebound: f32,
    pub basketball_iq: f32,
    pub clutch: f32,
    pub leadership: f32,
    pub work_ethic: f32,
    pub potential: f32,
}

impl PlayerAttributes {
    pub fn overall(&self) -> f32 {
        let weights = [
            (self.speed, 0.05),
            (self.strength, 0.03),
            (self.stamina, 0.03),
            (self.jumping, 0.02),
            (self.three_pt, 0.10),
            (self.mid_range, 0.10),
            (self.close_shot, 0.08),
            (self.dunk, 0.04),
            (self.layup, 0.05),
            (self.free_throw, 0.03),
            (self.ball_handle, 0.08),
            (self.passing, 0.07),
            (self.offensive_rebound, 0.03),
            (self.perimeter_def, 0.08),
            (self.interior_def, 0.06),
            (self.steal, 0.04),
            (self.block, 0.04),
            (self.defensive_rebound, 0.04),
            (self.basketball_iq, 0.02),
            (self.clutch, 0.01),
        ];
        weights.iter().map(|(val, w)| val * w).sum()
    }
}

impl Player {
    pub fn effective_ovr(&self) -> f32 {
        let base = self.attributes.overall();
        let morale_mod = if self.morale >= 85.0 {
            3.0
        } else if self.morale < 50.0 {
            -(50.0 - self.morale) / 5.0
        } else {
            0.0
        };
        (base + morale_mod).clamp(20.0, 99.0)
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum PlayerIntent {
    #[default]
    Idle,
    Shoot {
        shot_type: ShotType,
        ticks_left: u32,
        distance: f32,
    },
    Drive {
        ticks_left: u32,
    },
    Pass {
        target: PlayerId,
        ticks_left: u32,
    },
    Move {
        target_pos: Vec2,
    },
    Defend {
        target_player: PlayerId,
        intensity: f32,
    },
    Block {
        target_player: PlayerId,
        ticks_left: u32,
    },
    BoxOut {
        ticks_left: u32,
    },
    Rebound {
        ticks_left: u32,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Badge {
    Sniper,
    LockdownDefender,
    Playmaker,
    PostScorer,
    SlashingFinisher,
    ReboundChaser,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Player {
    pub id: PlayerId,
    pub first_name: String,
    pub last_name: String,
    pub position: Position,
    pub age: u8,
    pub attributes: PlayerAttributes,
    pub tendencies: BehaviorTendencies,
    pub spatial_anchor: SpatialAnchor,
    pub dna: PlayerDNA,
    pub radius: f32,
    #[serde(default)]
    pub badges: Vec<Badge>,
    #[serde(skip)]
    pub angle: f32,
    #[serde(skip)]
    pub velocity: Vec2,
    #[serde(skip)]
    pub current_position: Vec2,
    #[serde(skip)]
    pub target_position: Vec2,
    #[serde(skip)]
    pub acceleration: f32,
    #[serde(skip)]
    pub locomotion_state: LocomotionState,
    #[serde(skip)]
    pub ticks_established: u32,
    #[serde(skip)]
    pub intent: PlayerIntent,
    pub morale: f32,
    pub injury_days: u8,
    pub contract_year: u8,
    pub salary: u32,
    pub stats_season: PlayerStats,
    pub stats_career: PlayerStats,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PlayerStats {
    pub games_played: u16,
    pub points: f32,
    pub rebounds: f32,
    pub assists: f32,
    pub steals: f32,
    pub blocks: f32,
    pub turnovers: f32,
    pub minutes: f32,
    pub fg_pct: f32,
    pub three_pct: f32,
    pub ft_pct: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum OffensiveTactic {
    Motion,
    Isolation,
    PickAndRoll,
    PostUp,
    Princeton,
    Triangle,
    SevenSeconds,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum DefensiveTactic {
    ManToMan,
    Zone2_3,
    Zone3_2,
    FullCourtPress,
    HalfCourtTrap,
    BoxAndOne,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TacticConfig {
    pub offensive: OffensiveTactic,
    pub defensive: DefensiveTactic,
    pub pace: f32,
    pub three_frequency: f32,
    pub physicality: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BehaviorTendencies {
    pub shoot_three: u8,
    pub drive_to_basket: u8,
    pub pass_first: u8,
    pub post_up: u8,
    pub mid_range: u8,
}

impl BehaviorTendencies {
    pub fn normalized(&self, action: &UtilityAction) -> f32 {
        match action {
            UtilityAction::ShootThree => self.shoot_three as f32 / 100.0,
            UtilityAction::Drive => self.drive_to_basket as f32 / 100.0,
            UtilityAction::Pass => self.pass_first as f32 / 100.0,
            UtilityAction::PostUp => self.post_up as f32 / 100.0,
            UtilityAction::MidRange => self.mid_range as f32 / 100.0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpatialAnchor {
    pub x: f32,
    pub z: f32,
    pub anchor_weight: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerDNA {
    pub three_point: u8,
    pub passing: u8,
    pub dribbling: u8,
    pub driving: u8,
    pub post_scoring: u8,
    pub court_vision: u8,
}

impl PlayerDNA {
    pub fn skill_for(&self, action: &UtilityAction) -> f32 {
        match action {
            UtilityAction::ShootThree => self.three_point as f32 / 20.0,
            UtilityAction::Drive => self.driving as f32 / 20.0,
            UtilityAction::Pass => self.passing as f32 / 20.0,
            UtilityAction::PostUp => self.post_scoring as f32 / 20.0,
            UtilityAction::MidRange => (self.three_point.max(self.driving) as f32) / 20.0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TacticalModifiers {
    pub three_pt_weight: f32,
    pub drive_weight: f32,
    pub pass_weight: f32,
    pub post_weight: f32,
    pub mid_range_weight: f32,
}

impl TacticalModifiers {
    pub fn from_tactic(tactic: &TacticConfig) -> Self {
        match tactic.offensive {
            OffensiveTactic::SevenSeconds | OffensiveTactic::Motion => Self {
                three_pt_weight: 1.5 + tactic.three_frequency / 200.0,
                drive_weight: 1.0,
                pass_weight: 0.8,
                post_weight: 0.4,
                mid_range_weight: 0.6,
            },
            OffensiveTactic::PickAndRoll => Self {
                three_pt_weight: 1.0 + tactic.three_frequency / 200.0,
                drive_weight: 1.4,
                pass_weight: 1.2,
                post_weight: 0.6,
                mid_range_weight: 1.0,
            },
            OffensiveTactic::Isolation => Self {
                three_pt_weight: 0.6,
                drive_weight: 1.6,
                pass_weight: 0.4,
                post_weight: 0.8,
                mid_range_weight: 0.6,
            },
            OffensiveTactic::PostUp => Self {
                three_pt_weight: 0.5,
                drive_weight: 0.6,
                pass_weight: 0.8,
                post_weight: 1.8,
                mid_range_weight: 0.7,
            },
            OffensiveTactic::Princeton => Self {
                three_pt_weight: 0.8,
                drive_weight: 0.8,
                pass_weight: 1.6,
                post_weight: 1.0,
                mid_range_weight: 1.2,
            },
            OffensiveTactic::Triangle => Self {
                three_pt_weight: 0.7,
                drive_weight: 0.6,
                pass_weight: 1.4,
                post_weight: 1.2,
                mid_range_weight: 1.2,
            },
        }
    }

    pub fn weight_for(&self, action: &UtilityAction) -> f32 {
        match action {
            UtilityAction::ShootThree => self.three_pt_weight,
            UtilityAction::Drive => self.drive_weight,
            UtilityAction::Pass => self.pass_weight,
            UtilityAction::PostUp => self.post_weight,
            UtilityAction::MidRange => self.mid_range_weight,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum UtilityAction {
    ShootThree,
    Drive,
    Pass,
    PostUp,
    MidRange,
}

impl Default for TacticConfig {
    fn default() -> Self {
        Self {
            offensive: OffensiveTactic::SevenSeconds,
            defensive: DefensiveTactic::ManToMan,
            pace: 50.0,
            three_frequency: 35.0,
            physicality: 50.0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TrainingFocus {
    Shooting,
    Defense,
    Playmaking,
    Physical,
    Balanced,
}

impl Default for TrainingFocus {
    fn default() -> Self { Self::Balanced }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Team {
    pub id: TeamId,
    pub name: String,
    pub city: String,
    pub abbreviation: String,
    pub players: Vec<Player>,
    pub tactic: TacticConfig,
    pub chemistry: f32,
    pub wins: u16,
    pub losses: u16,
    #[serde(default)]
    pub training_focus: TrainingFocus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Quarter {
    First,
    Second,
    Third,
    Fourth,
    Overtime(u8),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ShotType {
    ThreePointer,
    TwoPointer,
    Layup,
    Dunk,
    FreeThrow,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ShotResult {
    Made,
    Missed,
    Blocked,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ActionType {
    Pass {
        from: PlayerId,
        to: PlayerId,
        start_pos: [f32; 2],
        target_pos: [f32; 2],
        air_time_ms: u32,
        pass_type: PassType,
    },
    Shot {
        player: PlayerId,
        shot_type: ShotType,
        result: ShotResult,
        distance: f32,
    },
    Rebound {
        player: PlayerId,
        offensive: bool,
    },
    Steal {
        defender: PlayerId,
        offender: PlayerId,
    },
    Block {
        defender: PlayerId,
        shooter: PlayerId,
    },
    Foul {
        defender: PlayerId,
        offender: PlayerId,
        shooting: bool,
        personal: bool,
    },
    FreeThrow {
        player: PlayerId,
        result: ShotResult,
    },
    Turnover {
        player: PlayerId,
        reason: String,
    },
    Substitution {
        player_out: PlayerId,
        player_in: PlayerId,
    },
    OffensiveFoul {
        offender: PlayerId,
        defender: PlayerId,
    },
    IllegalScreen {
        screen_setter: PlayerId,
        defender: PlayerId,
    },
    Tick,
    Timeout,
    QuarterEnd,
    GameEnd,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerPosition {
    pub player_id: PlayerId,
    pub x: f32,
    pub z: f32,
    pub y: f32,
    pub angle: f32,
    pub animation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BallState {
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub holder: Option<PlayerId>,
    pub carrier_id: Option<PlayerId>,
    pub trajectory: Option<BallTrajectory>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BallTrajectory {
    pub start_x: f32,
    pub start_y: f32,
    pub start_z: f32,
    pub apex_x: f32,
    pub apex_y: f32,
    pub apex_z: f32,
    pub end_x: f32,
    pub end_y: f32,
    pub end_z: f32,
    pub progress: f32,
    pub speed: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScoreSnapshot {
    pub home: u16,
    pub away: u16,
    pub quarter: String,
    pub clock_seconds: u16,
    pub shot_clock: u8,
    pub home_fouls: u8,
    pub away_fouls: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchEvent {
    pub tick: u64,
    pub action: ActionType,
    pub score: ScoreSnapshot,
    pub positions: Vec<PlayerPosition>,
    pub ball: BallState,
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PlayoffRound {
    Quarterfinals,
    Semifinals,
    Finals,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayoffSeries {
    pub round: PlayoffRound,
    pub series_id: u32,
    pub higher_seed: TeamId,
    pub lower_seed: TeamId,
    pub higher_seed_wins: u16,
    pub lower_seed_wins: u16,
    pub completed: bool,
    pub winner: Option<TeamId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct League {
    pub teams: Vec<Team>,
    pub schedule: Vec<ScheduledGame>,
    pub current_week: u16,
    pub season: u16,
    pub playoffs_active: bool,
    pub playoff_series: Vec<PlayoffSeries>,
    #[serde(default)]
    pub events: Vec<GameEvent>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameEvent {
    pub id: u32,
    pub event_type: String,
    pub season: u16,
    pub year: u16,
    pub month: u8,
    pub day: u8,
    pub hour: u8,
    pub minute: u8,
    pub competition: Option<String>,
    pub description: String,
    pub is_completed: bool,
    pub home_team_id: Option<u32>,
    pub away_team_id: Option<u32>,
    pub game_id: Option<u32>,
    pub is_playoff: Option<bool>,
    pub phase_label: Option<String>,
    pub cup_stage: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyEvent {
    pub event_type: String,
    pub title: String,
    pub body: String,
    pub severity: String,
    pub sender_role: String,
    pub sender_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScheduledGame {
    pub id: GameId,
    pub home_team: TeamId,
    pub away_team: TeamId,
    pub week: u16,
    pub played: bool,
    pub is_playoff: bool,
    pub home_score: Option<u16>,
    pub away_score: Option<u16>,
}
