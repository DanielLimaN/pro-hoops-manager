use rand::Rng;
use crate::engine::types::*;

pub struct ShotContext {
    pub shooter: Player,
    pub defender: Option<Player>,
    pub shot_type: ShotType,
    pub distance: f32,
    pub is_clutch: bool,
    pub defender_distance: f32,
}

pub fn resolve_shot(ctx: &ShotContext) -> (ShotResult, String) {
    let mut rng = rand::thread_rng();
    let attrs = &ctx.shooter.attributes;

    let base_pct = match ctx.shot_type {
        ShotType::ThreePointer => attrs.three_pt,
        ShotType::TwoPointer => attrs.mid_range,
        ShotType::Layup => attrs.layup,
        ShotType::Dunk => attrs.dunk,
        ShotType::FreeThrow => attrs.free_throw,
    };

    let defender_mod = match &ctx.defender {
        Some(d) => {
            let def_skill = match ctx.shot_type {
                ShotType::ThreePointer | ShotType::TwoPointer => d.attributes.perimeter_def,
                ShotType::Layup | ShotType::Dunk => d.attributes.interior_def,
                ShotType::FreeThrow => 0.0,
            };
            let dist_mod = (3.0 - ctx.defender_distance.min(3.0)) / 3.0;
            def_skill / 100.0 * dist_mod * 0.5
        }
        None => 0.0,
    };

    let distance_mod = if ctx.distance > 1.0 { (ctx.distance - 1.0) / 7.0 * 0.30 } else { 0.0 };
    let clutch_mod = if ctx.is_clutch { 1.0 + (attrs.clutch - 50.0) / 500.0 } else { 1.0 };
    let stamina_mod = attrs.stamina / 100.0;
    let morale_factor = if ctx.shooter.morale >= 85.0 {
        1.10
    } else if ctx.shooter.morale < 50.0 {
        let debuff = (50.0 - ctx.shooter.morale) / 200.0;
        1.0 - debuff
    } else {
        1.0
    };

    let final_pct = ((base_pct / 170.0)
        * (1.0 - defender_mod)
        * (1.0 - distance_mod.min(0.99))
        * stamina_mod
        * clutch_mod
        * morale_factor)
        .max(0.0);

    let roll: f32 = rng.gen();

    if roll < final_pct {
        match ctx.shot_type {
            ShotType::Dunk => (ShotResult::Made, format!("EMBALADA E FOGO DE CESTA! {} enterra com forca!", ctx.shooter.last_name)),
            ShotType::ThreePointer => (ShotResult::Made, format!("{} acerta uma bola de tres pontos!", ctx.shooter.last_name)),
            ShotType::Layup => (ShotResult::Made, format!("{} faz a bandeja.", ctx.shooter.last_name)),
            ShotType::TwoPointer => (ShotResult::Made, format!("{} acerta o arremesso de media distancia.", ctx.shooter.last_name)),
            ShotType::FreeThrow => (ShotResult::Made, format!("{} converte o lance livre.", ctx.shooter.last_name)),
        }
    } else {
        let block_chance = match &ctx.defender {
            Some(d) => {
                let height_advantage = (d.attributes.height_cm - ctx.shooter.attributes.height_cm).max(0.0) / 30.0;
                let jump_mod = d.attributes.jumping / 100.0;
                let block_mod = d.attributes.block / 100.0;
                (block_mod * 0.3 + jump_mod * 0.1 + height_advantage * 0.1) * (0.3 + defender_mod * 1.4)
            }
            None => 0.0,
        };
        if rng.gen::<f32>() < block_chance {
            (ShotResult::Blocked, format!("{} bloqueia o arremesso de {}!",
                ctx.defender.as_ref().map_or("", |d| &d.last_name), ctx.shooter.last_name))
        } else {
            match ctx.shot_type {
                ShotType::ThreePointer => (ShotResult::Missed, format!("{} erra o tres pontos.", ctx.shooter.last_name)),
                ShotType::Dunk => (ShotResult::Missed, format!("{} perde a enterrada!", ctx.shooter.last_name)),
                _ => (ShotResult::Missed, format!("{} erra o arremesso.", ctx.shooter.last_name)),
            }
        }
    }
}
