use rand::Rng;
use crate::engine::types::*;
use crate::engine::decisions;
use crate::engine::shot_resolver;

pub fn process_possession(
    offense: &Team,
    defense: &Team,
    ball_handler_id: PlayerId,
    shot_clock: u8,
    _clock_seconds: u16,
    _score_diff: i16,
) -> (ActionType, String) {
    let ball_handler = offense.starters().into_iter()
        .find(|p| p.id == ball_handler_id)
        .unwrap_or(offense.starters()[0]);

    let defense_pressure = compute_defense_pressure(ball_handler, defense);
    let tactics = TacticalModifiers::from_tactic(&offense.tactic);

    let decision = decisions::choose_action(ball_handler, defense_pressure, &tactics, shot_clock);

    match decision {
        UtilityAction::ShootThree => handle_shot(ball_handler, defense, ShotType::ThreePointer, 7.5),
        UtilityAction::MidRange => handle_shot(ball_handler, defense, ShotType::TwoPointer, 4.5),
        UtilityAction::Drive => handle_drive(ball_handler, defense),
        UtilityAction::PostUp => handle_post_up(ball_handler, defense),
        UtilityAction::Pass => {
            let target_id = pick_pass_target(ball_handler, offense);
            handle_pass(ball_handler, target_id, defense, offense)
        }
    }
}

fn compute_defense_pressure(handler: &Player, defense: &Team) -> f32 {
    let closest = defense.starters().into_iter()
        .map(|d| {
            let perim = d.attributes.perimeter_def / 100.0;
            let steal = d.attributes.steal / 100.0;
            let height_advantage = ((d.attributes.height_cm - handler.attributes.height_cm) / 30.0).max(0.0);
            0.5 + perim * 0.25 + steal * 0.15 + height_advantage * 0.1
        })
        .fold(0.0_f32, |a, b| a.max(b));
    closest.min(1.0)
}

fn pick_pass_target(handler: &Player, offense: &Team) -> PlayerId {
    let mut rng = rand::thread_rng();
    let teammates: Vec<&Player> = offense.starters().into_iter()
        .filter(|p| p.id != handler.id)
        .collect();
    if teammates.is_empty() { return handler.id; }
    let total: f32 = teammates.iter().map(|p| {
        p.effective_ovr() / 100.0 * (1.0 - p.attributes.steal / 100.0 * 0.2)
    }).sum();
    let mut roll = rng.gen::<f32>() * total;
    for teammate in &teammates {
        let weight = teammate.effective_ovr() / 100.0 * (1.0 - teammate.attributes.steal / 100.0 * 0.2);
        if roll < weight { return teammate.id; }
        roll -= weight;
    }
    teammates.last().map_or(handler.id, |p| p.id)
}

fn handle_shot(shooter: &Player, defense: &Team, shot_type: ShotType, distance: f32) -> (ActionType, String) {
    let defender = defense.starters().into_iter()
        .min_by(|a, b| {
            let dist_a = (a.attributes.height_cm - shooter.attributes.height_cm).abs();
            let dist_b = (b.attributes.height_cm - shooter.attributes.height_cm).abs();
            dist_a.partial_cmp(&dist_b).unwrap()
        });

    let ctx = shot_resolver::ShotContext {
        shooter: shooter.clone(),
        defender: defender.cloned(),
        shot_type: shot_type.clone(),
        distance,
        is_clutch: false,
        defender_distance: if defender.is_some() { 1.5 } else { 3.0 },
    };

    let (result, text) = shot_resolver::resolve_shot(&ctx);
    (ActionType::Shot { player: shooter.id, shot_type: shot_type.clone(), result, distance }, text)
}

fn handle_pass(passer: &Player, target_id: PlayerId, defense: &Team, offense: &Team) -> (ActionType, String) {
    let mut rng = rand::thread_rng();
    let pass_skill = passer.attributes.passing / 100.0;

    let steal_chance: f32 = defense.starters().into_iter()
        .map(|p| p.attributes.steal / 100.0 * 0.02)
        .sum::<f32>()
        .min(0.3);

    if rng.gen::<f32>() < steal_chance * (1.0 - pass_skill * 0.5) {
        let starters = defense.starters();
        let stealer = starters[rng.gen_range(0..starters.len())].id;
        (ActionType::Steal { defender: stealer, offender: passer.id },
         format!("{} rouba a bola! Passe de {} interceptado!",
             defense.starters().into_iter().find(|p| p.id == stealer).map_or("", |p| &p.last_name),
             passer.last_name))
    } else {
        let receiver = offense.starters().into_iter().find(|p| p.id == target_id);
        let start_pos = [passer.current_position.x, passer.current_position.y];
        let target_pos = receiver.map_or([0.0, 0.0], |r| [r.current_position.x, r.current_position.y]);
        let dx = target_pos[0] - start_pos[0];
        let dz = target_pos[1] - start_pos[1];
        let dist = (dx * dx + dz * dz).sqrt().max(1.0);
        let air_time_ms = (dist / 12.0 * 1000.0) as u32;
        (ActionType::Pass { from: passer.id, to: target_id, start_pos, target_pos, air_time_ms, pass_type: PassType::Chest },
         format!("{} passa para o companheiro.", passer.last_name))
    }
}

fn handle_drive(driver: &Player, defense: &Team) -> (ActionType, String) {
    let mut rng = rand::thread_rng();
    let drive_success = driver.dna.driving as f32 / 20.0 * 0.6
        + driver.attributes.speed / 100.0 * 0.3
        + 0.15;

    if rng.gen::<f32>() < drive_success {
        let shot_type = if driver.attributes.dunk > 70.0 && rng.gen::<f32>() < 0.4 { ShotType::Dunk } else { ShotType::Layup };
        let distance = match shot_type { ShotType::Dunk => 0.5, _ => 1.0 };
        handle_shot(driver, defense, shot_type, distance)
    } else {
        let reason = format!("{} tenta penetrar mas perde a bola!", driver.last_name);
        (ActionType::Turnover { player: driver.id, reason: reason.clone() }, reason)
    }
}

fn handle_post_up(player: &Player, defense: &Team) -> (ActionType, String) {
    let mut rng = rand::thread_rng();
    let post_success = player.dna.post_scoring as f32 / 20.0 * 0.6
        + player.attributes.strength / 100.0 * 0.3
        + 0.15;

    if rng.gen::<f32>() < post_success {
        handle_shot(player, defense, ShotType::TwoPointer, 2.5)
    } else {
        let reason = format!("{} tenta jogar de costas mas perde a bola!", player.last_name);
        (ActionType::Turnover { player: player.id, reason: reason.clone() }, reason)
    }
}
