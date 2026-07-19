use rand::Rng;
use glam::Vec2;
use std::collections::HashSet;
use crate::engine::types::*;

fn ab(rng: &mut impl Rng, center: f32) -> f32 {
    (center + rng.gen_range(-10.0..10.0)).clamp(20.0, 99.0)
}

pub fn generate_player(id: PlayerId, position: Position, overall: f32, used_names: &mut HashSet<String>) -> Player {
    let mut rng = rand::thread_rng();
    let base = overall;

    let (height_cm, weight_kg): (f32, f32) = match position {
        Position::PG => (rng.gen_range(178.0..193.0), rng.gen_range(77.0..91.0)),
        Position::SG => (rng.gen_range(190.0..201.0), rng.gen_range(84.0..100.0)),
        Position::SF => (rng.gen_range(198.0..208.0), rng.gen_range(96.0..110.0)),
        Position::PF => (rng.gen_range(203.0..213.0), rng.gen_range(104.0..118.0)),
        Position::C => (rng.gen_range(208.0..221.0), rng.gen_range(111.0..130.0)),
    };
    let wingspan_cm = height_cm + rng.gen_range(5.0..20.0);

    let speed = match position {
        Position::PG => ab(&mut rng, base + 10.0),
        Position::SG => ab(&mut rng, base + 5.0),
        Position::SF => ab(&mut rng, base),
        Position::PF => ab(&mut rng, base - 5.0),
        Position::C => ab(&mut rng, base - 10.0),
    };
    let strength = match position {
        Position::PG => ab(&mut rng, base - 5.0),
        Position::SG => ab(&mut rng, base),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base + 15.0),
        Position::C => ab(&mut rng, base + 20.0),
    };
    let stamina = match position {
        Position::PG | Position::SG | Position::SF => ab(&mut rng, base + 5.0),
        Position::PF | Position::C => ab(&mut rng, base),
    };
    let jumping = match position {
        Position::PG => ab(&mut rng, base),
        Position::SG => ab(&mut rng, base + 10.0),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base + 5.0),
    };

    let three_pt = match position {
        Position::PG => ab(&mut rng, base + 10.0),
        Position::SG => ab(&mut rng, base + 15.0),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base - 5.0),
        Position::C => ab(&mut rng, base - 10.0),
    };
    let mid_range = match position {
        Position::PG => ab(&mut rng, base + 5.0),
        Position::SG => ab(&mut rng, base + 15.0),
        Position::SF => ab(&mut rng, base + 10.0),
        Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base - 5.0),
    };
    let close_shot = match position {
        Position::PG => ab(&mut rng, base - 5.0),
        Position::SG => ab(&mut rng, base),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base + 10.0),
        Position::C => ab(&mut rng, base + 15.0),
    };
    let dunk = match position {
        Position::PG => ab(&mut rng, base - 10.0),
        Position::SG => ab(&mut rng, base),
        Position::SF => ab(&mut rng, base + 10.0),
        Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base + 10.0),
    };
    let layup = match position {
        Position::PG => ab(&mut rng, base),
        Position::SG => ab(&mut rng, base + 5.0),
        Position::SF => ab(&mut rng, base + 10.0),
        Position::PF => ab(&mut rng, base),
        Position::C => ab(&mut rng, base + 5.0),
    };
    let free_throw = match position {
        Position::PG | Position::SG => ab(&mut rng, base + 10.0),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF | Position::C => ab(&mut rng, base - 5.0),
    };

    let ball_handle = match position {
        Position::PG => ab(&mut rng, base + 20.0),
        Position::SG => ab(&mut rng, base + 10.0),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base - 5.0),
        Position::C => ab(&mut rng, base - 10.0),
    };
    let passing = match position {
        Position::PG => ab(&mut rng, base + 20.0),
        Position::SG => ab(&mut rng, base + 5.0),
        Position::SF => ab(&mut rng, base),
        Position::PF => ab(&mut rng, base - 5.0),
        Position::C => ab(&mut rng, base - 10.0),
    };
    let offensive_rebound = match position {
        Position::PG | Position::SG => ab(&mut rng, base - 5.0),
        Position::SF => ab(&mut rng, base),
        Position::PF => ab(&mut rng, base + 10.0),
        Position::C => ab(&mut rng, base + 15.0),
    };

    let perimeter_def = match position {
        Position::PG | Position::SG | Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base),
        Position::C => ab(&mut rng, base - 10.0),
    };
    let interior_def = match position {
        Position::PG => ab(&mut rng, base - 10.0),
        Position::SG => ab(&mut rng, base - 5.0),
        Position::SF => ab(&mut rng, base),
        Position::PF => ab(&mut rng, base + 15.0),
        Position::C => ab(&mut rng, base + 20.0),
    };
    let steal = match position {
        Position::PG | Position::SG | Position::SF | Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base - 5.0),
    };
    let block = match position {
        Position::PG => ab(&mut rng, base - 10.0),
        Position::SG => ab(&mut rng, base - 5.0),
        Position::SF => ab(&mut rng, base),
        Position::PF => ab(&mut rng, base + 10.0),
        Position::C => ab(&mut rng, base + 20.0),
    };
    let defensive_rebound = match position {
        Position::PG => ab(&mut rng, base - 5.0),
        Position::SG => ab(&mut rng, base),
        Position::SF => ab(&mut rng, base + 5.0),
        Position::PF => ab(&mut rng, base + 15.0),
        Position::C => ab(&mut rng, base + 20.0),
    };
    let basketball_iq = match position {
        Position::PG => ab(&mut rng, base + 10.0),
        Position::SG | Position::SF | Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base - 5.0),
    };
    let clutch = match position {
        Position::PG => ab(&mut rng, base + 5.0),
        Position::SG => ab(&mut rng, base),
        Position::SF | Position::PF => ab(&mut rng, base + 5.0),
        Position::C => ab(&mut rng, base),
    };

    let tendencies = position_tendencies(&position, &mut rng);
    let spatial_anchor = position_anchor(&position);
    let dna = PlayerDNA {
        three_point: (three_pt / 5.0).round() as u8,
        passing: (passing / 5.0).round() as u8,
        dribbling: (ball_handle / 5.0).round() as u8,
        driving: ((speed + ball_handle) / 10.0).round() as u8,
        post_scoring: ((close_shot + strength) / 10.0).round() as u8,
        court_vision: ((passing + basketball_iq) / 10.0).round() as u8,
    };

    let player_radius = position_radius(&position);

    use super::names::{FIRST_NAMES, LAST_NAMES};
    let (first_name, last_name) = loop {
        let first = FIRST_NAMES[rng.gen_range(0..FIRST_NAMES.len())];
        let last = LAST_NAMES[rng.gen_range(0..LAST_NAMES.len())];
        if used_names.insert(format!("{} {}", first, last)) {
            break (first.to_string(), last.to_string());
        }
    };

    let mut badges = Vec::new();
    if three_pt > 85.0 { badges.push(Badge::Sniper); }
    if perimeter_def > 85.0 || steal > 85.0 { badges.push(Badge::LockdownDefender); }
    if passing > 85.0 || basketball_iq > 85.0 { badges.push(Badge::Playmaker); }
    if close_shot > 85.0 || strength > 85.0 { badges.push(Badge::PostScorer); }
    if speed > 85.0 && dunk > 80.0 { badges.push(Badge::SlashingFinisher); }
    if offensive_rebound > 85.0 || defensive_rebound > 85.0 { badges.push(Badge::ReboundChaser); }

    let skin_tones = [SkinTone::Light, SkinTone::Tan, SkinTone::Medium, SkinTone::Dark, SkinTone::Olive];
    let hair_styles = [HairStyle::Short, HairStyle::Afro, HairStyle::Buzzcut, HairStyle::None];
    let hair_colors = [HairColor::Black, HairColor::Blonde, HairColor::Brown, HairColor::Gray, HairColor::Red];
    let facial_hair_styles = [FacialHairStyle::Full, FacialHairStyle::None];

    let skin_tone = skin_tones[rng.gen_range(0..skin_tones.len())].clone();
    let hair_style = hair_styles[rng.gen_range(0..hair_styles.len())].clone();
    let hair_color = hair_colors[rng.gen_range(0..hair_colors.len())].clone();
    let facial_hair_style = facial_hair_styles[rng.gen_range(0..facial_hair_styles.len())].clone();

    let portrait_config = PortraitConfig {
        skin_tone,
        hair_style,
        hair_color,
        facial_hair_style,
    };

    Player {
        id,
        first_name,
        last_name,
        position,
        age: rng.gen_range(19..35),
        attributes: PlayerAttributes {
            speed, strength, stamina, jumping, height_cm, weight_kg, wingspan_cm,
            three_pt, mid_range, close_shot, dunk, layup, free_throw,
            ball_handle, passing, offensive_rebound, perimeter_def, interior_def,
            steal, block, defensive_rebound, basketball_iq, clutch,
            leadership: rng.gen_range(30.0..99.0),
            work_ethic: rng.gen_range(30.0..99.0),
            potential: overall + rng.gen_range(-5.0..15.0),
        },
        tendencies,
        spatial_anchor,
        dna,
        portrait_config,
        radius: player_radius,
        angle: 0.0,
        badges,
        velocity: Vec2::ZERO,
        current_position: Vec2::ZERO,
        target_position: Vec2::ZERO,
        acceleration: 6.0,
        locomotion_state: LocomotionState::Idle,
        ticks_established: 0,
        intent: PlayerIntent::default(),
        morale: rng.gen_range(50.0..100.0),
        injury_days: 0,
        contract_year: rng.gen_range(1..5),
        salary: rng.gen_range(1_000_000..30_000_000),
        stats_season: PlayerStats::default(),
        stats_career: PlayerStats::default(),
    }
}

fn get_attr_mut<'a>(attrs: &'a mut PlayerAttributes, _name: &str) -> &'a mut f32 {
    let name = _name;
    match name {
        "speed"             => &mut attrs.speed,
        "strength"          => &mut attrs.strength,
        "stamina"           => &mut attrs.stamina,
        "jumping"           => &mut attrs.jumping,
        "three_pt"          => &mut attrs.three_pt,
        "mid_range"         => &mut attrs.mid_range,
        "close_shot"        => &mut attrs.close_shot,
        "dunk"              => &mut attrs.dunk,
        "layup"             => &mut attrs.layup,
        "free_throw"        => &mut attrs.free_throw,
        "ball_handle"       => &mut attrs.ball_handle,
        "passing"           => &mut attrs.passing,
        "offensive_rebound" => &mut attrs.offensive_rebound,
        "perimeter_def"     => &mut attrs.perimeter_def,
        "interior_def"      => &mut attrs.interior_def,
        "steal"             => &mut attrs.steal,
        "block"             => &mut attrs.block,
        "defensive_rebound" => &mut attrs.defensive_rebound,
        "basketball_iq"     => &mut attrs.basketball_iq,
        "clutch"            => &mut attrs.clutch,
        "leadership"        => &mut attrs.leadership,
        "work_ethic"        => &mut attrs.work_ethic,
        _ => panic!("unknown attribute: {}", name),
    }
}

pub fn clamp_attributes(attrs: &mut PlayerAttributes) {
    attrs.speed             = attrs.speed.clamp(20.0, 99.0);
    attrs.strength          = attrs.strength.clamp(20.0, 99.0);
    attrs.stamina           = attrs.stamina.clamp(20.0, 99.0);
    attrs.jumping           = attrs.jumping.clamp(20.0, 99.0);
    attrs.three_pt          = attrs.three_pt.clamp(20.0, 99.0);
    attrs.mid_range         = attrs.mid_range.clamp(20.0, 99.0);
    attrs.close_shot        = attrs.close_shot.clamp(20.0, 99.0);
    attrs.dunk              = attrs.dunk.clamp(20.0, 99.0);
    attrs.layup             = attrs.layup.clamp(20.0, 99.0);
    attrs.free_throw        = attrs.free_throw.clamp(20.0, 99.0);
    attrs.ball_handle       = attrs.ball_handle.clamp(20.0, 99.0);
    attrs.passing           = attrs.passing.clamp(20.0, 99.0);
    attrs.offensive_rebound = attrs.offensive_rebound.clamp(20.0, 99.0);
    attrs.perimeter_def     = attrs.perimeter_def.clamp(20.0, 99.0);
    attrs.interior_def      = attrs.interior_def.clamp(20.0, 99.0);
    attrs.steal             = attrs.steal.clamp(20.0, 99.0);
    attrs.block             = attrs.block.clamp(20.0, 99.0);
    attrs.defensive_rebound = attrs.defensive_rebound.clamp(20.0, 99.0);
    attrs.basketball_iq     = attrs.basketball_iq.clamp(20.0, 99.0);
    attrs.clutch            = attrs.clutch.clamp(20.0, 99.0);
    attrs.leadership        = attrs.leadership.clamp(20.0, 99.0);
    attrs.work_ethic        = attrs.work_ethic.clamp(20.0, 99.0);
    attrs.potential         = attrs.potential.clamp(20.0, 99.0);
}

pub fn apply_training_progression(player: &mut Player, focus: &TrainingFocus, weeks: u16) {
    if player.age >= 27 { return; }

    let overall = player.attributes.overall();
    let potential = player.attributes.potential;
    let gap = ((potential - overall) / 100.0).max(0.0);
    let ethic = player.attributes.work_ethic / 100.0;
    let base_delta = gap * ethic * 0.5 * weeks as f32;

    let (primary, secondary): (&[&str], &[&str]) = match focus {
        TrainingFocus::Shooting   => (&["three_pt", "mid_range", "free_throw"], &["close_shot", "ball_handle"]),
        TrainingFocus::Defense    => (&["perimeter_def", "interior_def", "steal", "block"], &["defensive_rebound", "speed"]),
        TrainingFocus::Playmaking => (&["ball_handle", "passing", "basketball_iq"], &["speed", "clutch"]),
        TrainingFocus::Physical   => (&["speed", "stamina", "strength", "jumping"], &["interior_def", "close_shot"]),
        TrainingFocus::Balanced   => (&["speed", "stamina", "three_pt", "passing", "perimeter_def"], &[]),
    };

    let n_primary = primary.len() as f32;
    let n_secondary = secondary.len() as f32;

    for name in primary {
        let attr = get_attr_mut(&mut player.attributes, name);
        *attr += base_delta * 0.7 / n_primary;
    }
    for name in secondary {
        let attr = get_attr_mut(&mut player.attributes, name);
        *attr += base_delta * 0.3 / n_secondary.max(1.0);
    }

    clamp_attributes(&mut player.attributes);
}

fn position_tendencies(position: &Position, rng: &mut impl Rng) -> BehaviorTendencies {
    let mut variance = || rng.gen_range(0..15);
    match position {
        Position::PG => BehaviorTendencies {
            pass_first: (80 + variance()).min(100),
            shoot_three: (50 + variance()).min(100),
            drive_to_basket: (80 + variance()).min(100),
            mid_range: (50 + variance()).min(100),
            post_up: (10 + variance()).min(100),
        },
        Position::SG => BehaviorTendencies {
            shoot_three: (65 + variance()).min(100),
            drive_to_basket: (80 + variance()).min(100),
            mid_range: (60 + variance()).min(100),
            pass_first: (35 + variance()).min(100),
            post_up: (15 + variance()).min(100),
        },
        Position::SF => BehaviorTendencies {
            drive_to_basket: (75 + variance()).min(100),
            mid_range: (65 + variance()).min(100),
            shoot_three: (55 + variance()).min(100),
            pass_first: (40 + variance()).min(100),
            post_up: (40 + variance()).min(100),
        },
        Position::PF => BehaviorTendencies {
            post_up: (75 + variance()).min(100),
            mid_range: (60 + variance()).min(100),
            drive_to_basket: (55 + variance()).min(100),
            shoot_three: (35 + variance()).min(100),
            pass_first: (30 + variance()).min(100),
        },
        Position::C => BehaviorTendencies {
            post_up: (90 + variance()).min(100),
            mid_range: (40 + variance()).min(100),
            drive_to_basket: (45 + variance()).min(100),
            pass_first: (35 + variance()).min(100),
            shoot_three: (20 + variance()).min(100),
        },
    }
}

fn position_anchor(position: &Position) -> SpatialAnchor {
    match position {
        Position::PG => SpatialAnchor { x: 0.5, z: 0.75, anchor_weight: 0.8 },
        Position::SG => SpatialAnchor { x: 0.7, z: 0.55, anchor_weight: 0.6 },
        Position::SF => SpatialAnchor { x: 0.3, z: 0.55, anchor_weight: 0.6 },
        Position::PF => SpatialAnchor { x: 0.6, z: 0.30, anchor_weight: 0.7 },
        Position::C => SpatialAnchor { x: 0.5, z: 0.20, anchor_weight: 0.9 },
    }
}

fn position_radius(position: &Position) -> f32 {
    match position {
        Position::PG => 0.35,
        Position::SG => 0.35,
        Position::SF => 0.40,
        Position::PF => 0.45,
        Position::C => 0.50,
    }
}
