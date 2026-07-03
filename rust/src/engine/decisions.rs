use rand::Rng;
use glam::Vec2;
use crate::engine::types::*;

const RIM_Z: f32 = 14.325;

pub fn evaluate_off_ball_intent(
    player: &Player,
    ball_pos: Vec2,
    basket_dir: f32,
    shot_clock: u8,
    phase: PossessionPhase,
    shooter_id: Option<PlayerId>,
) -> PlayerIntent {
    let mut rng = rand::thread_rng();

    if phase == PossessionPhase::ReboundContest {
        return PlayerIntent::Move { target_pos: ball_pos };
    }

    if phase == PossessionPhase::Inbound {
        if Some(player.id) == shooter_id {
            // The designated inbounder runs to pick up the ball!
            return PlayerIntent::Move { target_pos: ball_pos };
        }
    }

    if phase == PossessionPhase::ShotInAir {
        if Some(player.id) == shooter_id {
            // The shooter stays back near the perimeter (holding follow-through or getting back to defense)
            let target_pos = Vec2::new(player.current_position.x * 0.8, -basket_dir * 3.0);
            return PlayerIntent::Move { target_pos };
        }
        let target_pos = match player.position {
            Position::C => Vec2::new(0.0, basket_dir * (RIM_Z - 1.0)),
            Position::PF => Vec2::new(-1.5, basket_dir * (RIM_Z - 1.5)),
            Position::SF => Vec2::new(1.5, basket_dir * (RIM_Z - 1.5)),
            Position::PG | Position::SG => Vec2::new(player.current_position.x * 0.5, -basket_dir * 2.0),
        };
        return PlayerIntent::Move { target_pos };
    }
    if phase == PossessionPhase::Inbound || phase == PossessionPhase::BringUp {
        let is_guard = player.position == Position::PG || player.position == Position::SG;
        let target_pos = if is_guard && ball_pos.distance(player.current_position) > 6.0 {
            let dir_to_ball = (ball_pos - player.current_position).normalize_or_zero();
            player.current_position + dir_to_ball * 3.0
        } else {
            let lane_x = (player.spatial_anchor.x * 2.0 - 1.0) * 7.62;
            let max_advance: f32 = if ball_pos.y * basket_dir < 0.0 { 2.0 } else { 12.0 };
            Vec2::new(lane_x, basket_dir * max_advance.min(ball_pos.y * basket_dir + 5.0))
        };
        return PlayerIntent::Move { target_pos };
    }

    let scaled_x = (player.spatial_anchor.x * 2.0 - 1.0) * 7.62;
    let scaled_y = basket_dir * (14.325 * (1.0 - player.spatial_anchor.z));
    let mut target_pos = Vec2::new(scaled_x, scaled_y);

    let dist_to_ball = target_pos.distance(ball_pos);
    if dist_to_ball < 4.0 {
        let push_dir = (target_pos - ball_pos).normalize_or_zero();
        target_pos += push_dir * (4.0 - dist_to_ball);
    }

    let cut_tendency = player.tendencies.drive_to_basket as f32 / 100.0;
    if shot_clock < 10 && rng.gen::<f32>() < cut_tendency * 0.05 {
        target_pos = Vec2::new(target_pos.x * 0.5, basket_dir * 12.0);
    }

    PlayerIntent::Move { target_pos }
}

pub fn evaluate_defensive_intent(
    defender: &Player,
    matchup: Option<&Player>,
    ball_pos: Vec2,
    ball_handler: Option<PlayerId>,
    basket_dir: f32,
    phase: PossessionPhase,
    teammates: &[Player],
    tactic: &DefensiveTactic,
) -> PlayerIntent {
    if phase == PossessionPhase::JumpBall {
        let target_pos = match defender.position {
            Position::C => Vec2::new(0.0, basket_dir * 1.0),
            Position::PF => Vec2::new(-2.0, basket_dir * 2.0),
            Position::SF => Vec2::new(2.0, basket_dir * 2.0),
            Position::SG => Vec2::new(3.0, basket_dir * 4.0),
            Position::PG => Vec2::new(-3.0, basket_dir * 4.0),
        };
        return PlayerIntent::Move { target_pos };
    }
    if phase == PossessionPhase::ReboundContest {
        return PlayerIntent::Move { target_pos: ball_pos };
    }

    if phase == PossessionPhase::ShotInAir {
        let target_pos = match defender.position {
            Position::C => Vec2::new(0.0, -basket_dir * (RIM_Z - 0.5)),
            Position::PF => Vec2::new(-1.2, -basket_dir * (RIM_Z - 1.0)),
            Position::SF => Vec2::new(1.2, -basket_dir * (RIM_Z - 1.0)),
            Position::PG | Position::SG => Vec2::new(0.0, -basket_dir * 8.0),
        };
        return PlayerIntent::Move { target_pos };
    }
    let hoop_pos = Vec2::new(0.0, -basket_dir * 14.325);

    let is_pressing = matches!(tactic, DefensiveTactic::FullCourtPress);
    if !is_pressing && (phase == PossessionPhase::Inbound || phase == PossessionPhase::BringUp) {
        let def_x = match defender.position {
            Position::C => 0.0,
            Position::PF => -3.0,
            Position::SF => 3.0,
            Position::PG => -4.0,
            Position::SG => 4.0,
        };
        let def_y = match defender.position {
            Position::C | Position::PF => -basket_dir * 10.0,
            Position::SF => -basket_dir * 8.0,
            Position::PG | Position::SG => -basket_dir * 4.0,
        };
        return PlayerIntent::Move { target_pos: Vec2::new(def_x, def_y) };
    }

    if let Some(offender) = matchup {
        let is_on_ball = Some(offender.id) == ball_handler;
        let mut target_pos = if is_on_ball {
            let dir_to_hoop = (hoop_pos - offender.current_position).normalize_or_zero();
            let distance_buffer = if phase == PossessionPhase::Inbound || phase == PossessionPhase::BringUp {
                2.0
            } else {
                0.8
            };
            let base_target = offender.current_position + dir_to_hoop * distance_buffer;
            if let PlayerIntent::Shoot { ticks_left, .. } = offender.intent {
                if defender.current_position.distance(offender.current_position) < 2.0 {
                    return PlayerIntent::Block { target_player: offender.id, ticks_left };
                }
            }
            base_target
        } else {
            if phase == PossessionPhase::Inbound || phase == PossessionPhase::BringUp {
                let mut fallback_z = offender.current_position.y * basket_dir;
                fallback_z = fallback_z.min(8.0);
                Vec2::new(offender.current_position.x, basket_dir * fallback_z)
            } else {
                let dist_to_ball = offender.current_position.distance(ball_pos);
                let dir_to_hoop = (hoop_pos - offender.current_position).normalize_or_zero();
                let distance_from_offender = if dist_to_ball > 8.0 { 2.5 } else { 1.2 };
                offender.current_position + dir_to_hoop * distance_from_offender
            }
        };

        let mut separation_force = Vec2::ZERO;
        for teammate in teammates {
            if teammate.id != defender.id {
                let dist = target_pos.distance(teammate.target_position);
                if dist < 1.5 && dist > 0.01 {
                    let repel_dir = (target_pos - teammate.target_position).normalize_or_zero();
                    separation_force += repel_dir * (1.5 - dist);
                }
            }
        }
        target_pos += separation_force * 0.5;

        if is_on_ball && separation_force.length() < 0.1 {
            return PlayerIntent::Defend { target_player: offender.id, intensity: 1.0 };
        }
        return PlayerIntent::Move { target_pos };
    }

    PlayerIntent::Idle
}

pub fn evaluate_on_ball_intent(
    player: &Player,
    teammates: &[Player],
    defense_pressure: f32,
    tactics: &TacticalModifiers,
    shot_clock: u8,
    basket_dir: f32,
) -> PlayerIntent {
    let action = choose_action(player, defense_pressure, tactics, shot_clock, basket_dir);
    let shooting_ticks = (12.0 - (player.attributes.speed / 100.0 * 6.0)) as u32;

    match action {
        UtilityAction::ShootThree => PlayerIntent::Shoot { shot_type: ShotType::ThreePointer, ticks_left: shooting_ticks, distance: 7.5 },
        UtilityAction::MidRange => PlayerIntent::Shoot { shot_type: ShotType::TwoPointer, ticks_left: shooting_ticks, distance: 4.5 },
        UtilityAction::Drive => PlayerIntent::Drive { ticks_left: 15 },
        UtilityAction::PostUp => PlayerIntent::Drive { ticks_left: 20 },
        UtilityAction::Pass => {
            let mut best_target = player.id;
            let mut best_score = -1.0;
            for t in teammates {
                if t.id != player.id {
                    let score = t.effective_ovr() + rand::thread_rng().gen_range(-10.0..10.0);
                    if score > best_score {
                        best_score = score;
                        best_target = t.id;
                    }
                }
            }
            PlayerIntent::Pass { target: best_target, ticks_left: 5 }
        }
    }
}

const CANDIDATE_ACTIONS: [UtilityAction; 5] = [
    UtilityAction::ShootThree,
    UtilityAction::Drive,
    UtilityAction::Pass,
    UtilityAction::PostUp,
    UtilityAction::MidRange,
];

pub fn choose_action(
    player: &Player,
    defense_pressure: f32,
    tactics: &TacticalModifiers,
    shot_clock: u8,
    basket_dir: f32,
) -> UtilityAction {
    let mut rng = rand::thread_rng();
    let hoop_pos = Vec2::new(0.0, basket_dir * 14.325);
    let dist_to_hoop = player.current_position.distance(hoop_pos);

    if shot_clock <= 4 {
        let three = if dist_to_hoop < 9.0 {
            utility_score(player, UtilityAction::ShootThree, defense_pressure, tactics, shot_clock)
        } else {
            0.0
        };
        let drive = utility_score(player, UtilityAction::Drive, defense_pressure, tactics, shot_clock);
        return if three >= drive && three > 0.0 { UtilityAction::ShootThree } else { UtilityAction::Drive };
    }

    let mut best: Option<(f32, UtilityAction)> = None;
    for &action in &CANDIDATE_ACTIONS {
        let is_allowed = match action {
            UtilityAction::ShootThree => dist_to_hoop < 9.0,
            UtilityAction::MidRange => dist_to_hoop < 6.0,
            UtilityAction::PostUp => dist_to_hoop < 4.5,
            UtilityAction::Drive | UtilityAction::Pass => true,
        };
        let score = if is_allowed {
            let raw = utility_score(player, action, defense_pressure, tactics, shot_clock);
            let noise = rng.gen_range(-0.05..0.05);
            (raw + noise).max(0.0)
        } else {
            0.0
        };
        if best.map_or(true, |(b, _)| score > b) {
            best = Some((score, action));
        }
    }

    best.map(|(_, a)| a).unwrap_or(UtilityAction::Pass)
}

fn utility_score(
    player: &Player,
    action: UtilityAction,
    defense_pressure: f32,
    tactics: &TacticalModifiers,
    shot_clock: u8,
) -> f32 {
    let skill = player.dna.skill_for(&action);
    let tendency = player.tendencies.normalized(&action);
    let tactical = tactics.weight_for(&action);

    let urgency = if shot_clock <= 8 {
        1.0 + (8.0 - shot_clock as f32) * 0.1
    } else {
        1.0
    };

    let pressure_mod = match action {
        UtilityAction::ShootThree | UtilityAction::MidRange => {
            if defense_pressure > 0.7 { 1.0 - defense_pressure * 0.4 } else { 1.0 }
        }
        UtilityAction::Drive => {
            if defense_pressure > 0.7 { 1.0 - defense_pressure * 0.2 }
            else { 1.0 + (1.0 - defense_pressure) * 0.3 }
        }
        UtilityAction::PostUp => 1.0 + (1.0 - defense_pressure) * 0.2,
        UtilityAction::Pass => 1.0 + defense_pressure * 0.3,
    };
    
    let mut badge_multiplier = 1.0;
    for badge in &player.badges {
        match (badge, &action) {
            (Badge::Sniper, UtilityAction::ShootThree) => badge_multiplier += 0.3,
            (Badge::Playmaker, UtilityAction::Pass) => badge_multiplier += 0.3,
            (Badge::PostScorer, UtilityAction::PostUp) => badge_multiplier += 0.3,
            (Badge::SlashingFinisher, UtilityAction::Drive) => badge_multiplier += 0.3,
            _ => {}
        }
    }

    let mut clock_patience_mod = 1.0;
    if shot_clock > 14 {
        match action {
            UtilityAction::Pass => clock_patience_mod = 3.5,
            UtilityAction::ShootThree | UtilityAction::MidRange | UtilityAction::Drive | UtilityAction::PostUp => {
                if defense_pressure > 0.15 {
                    clock_patience_mod = 0.1; // Do not shoot contested early
                } else {
                    clock_patience_mod = 1.5; // Open? Take it
                }
            }
        }
    } else if shot_clock > 7 {
        match action {
            UtilityAction::Pass => clock_patience_mod = 1.5,
            UtilityAction::ShootThree | UtilityAction::MidRange | UtilityAction::Drive | UtilityAction::PostUp => {
                if defense_pressure > 0.4 {
                    clock_patience_mod = 0.4; // Still prefer passing if decently covered
                } else {
                    clock_patience_mod = 1.2; 
                }
            }
        }
    }

    skill * tendency * tactical * urgency * pressure_mod * badge_multiplier * clock_patience_mod
}
