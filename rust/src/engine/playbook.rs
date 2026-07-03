use glam::Vec2;
use crate::engine::types::*;

const HALF_LENGTH: f32 = 14.325;

pub fn apply_playbook_tactics(
    play: &mut ActivePlay, team: &mut Team, ball_holder_id: Option<PlayerId>, basket_dir: f32,
) {
    let mut saved_targets = std::collections::HashMap::new();
    for player in team.players.iter() {
        if matches!(player.intent, PlayerIntent::Shoot { .. } | PlayerIntent::Drive { .. } | PlayerIntent::Pass { .. }) {
            saved_targets.insert(player.id, player.target_position);
        }
    }

    let starter_ids: Vec<PlayerId> = team.starters().iter().map(|p| p.id).collect();
    let mut offense: Vec<&mut Player> = team.players.iter_mut()
        .filter(|p| starter_ids.contains(&p.id)).collect();

    match play.tactic {
        OffensiveTactic::PickAndRoll => tick_pick_and_roll(play, &mut offense, ball_holder_id, basket_dir),
        OffensiveTactic::Triangle => tick_triangle(play, &mut offense, basket_dir),
        OffensiveTactic::Motion => tick_motion(play, &mut offense, ball_holder_id, basket_dir),
        OffensiveTactic::Isolation => tick_isolation(play, &mut offense, ball_holder_id, basket_dir),
        OffensiveTactic::PostUp => tick_post_up(play, &mut offense, ball_holder_id, basket_dir),
        OffensiveTactic::Princeton => tick_princeton(play, &mut offense, ball_holder_id, basket_dir),
        OffensiveTactic::SevenSeconds => tick_seven_seconds(play, &mut offense, ball_holder_id, basket_dir),
    }

    for player in team.players.iter_mut() {
        if let Some(target) = saved_targets.get(&player.id) {
            player.target_position = *target;
        }
    }
}

fn tick_pick_and_roll(play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    let handler_idx = offense.iter().position(|p| p.id == handler_id).unwrap_or(0);
    let top_of_key = Vec2::new(0.0, 6.325 * basket_dir);
    let corner_left = Vec2::new(-6.5, 12.325 * basket_dir);
    let corner_right = Vec2::new(6.5, 12.325 * basket_dir);
    let wing_left = Vec2::new(-4.5, 9.325 * basket_dir);
    let wing_right = Vec2::new(4.5, 9.325 * basket_dir);

    match play.stage {
        PlayStage::Inception => {
            for (i, player) in offense.iter_mut().enumerate() {
                if i == handler_idx {
                    player.target_position = top_of_key;
                } else if player.position == Position::C {
                    let screen_spot = Vec2::new(top_of_key.x + 0.8, top_of_key.y - 1.5 * basket_dir);
                    player.target_position = screen_spot;
                } else if i % 2 == 0 {
                    player.target_position = corner_left;
                } else {
                    player.target_position = corner_right;
                }
            }
            let center_at_target = offense.iter()
                .filter(|p| p.position == Position::C)
                .any(|c| c.current_position.distance(c.target_position) < 0.5);
            if center_at_target { play.stage = PlayStage::Execution; play.ticks_in_stage = 0; }
        }
        PlayStage::Execution => {
            play.ticks_in_stage += 1;
            for (i, player) in offense.iter_mut().enumerate() {
                if i == handler_idx {
                    let offset_x = (play.ticks_in_stage as f32 * 0.1).sin() * 1.5;
                    player.target_position = Vec2::new(top_of_key.x + offset_x, top_of_key.y - 0.5 * basket_dir);
                } else if player.position == Position::C {
                    player.velocity = Vec2::ZERO;
                    player.locomotion_state = LocomotionState::Screening;
                    player.target_position = top_of_key - Vec2::new(0.0, 1.5 * basket_dir);
                } else {
                    let wave = ((play.ticks_in_stage as f32 * 0.05) + i as f32).cos() * 0.6;
                    let base_target = if i % 2 == 0 { corner_left } else { corner_right };
                    player.target_position = base_target + Vec2::new(wave, wave * basket_dir);
                }
            }
            if play.ticks_in_stage > 15 { play.stage = PlayStage::Resolution; play.ticks_in_stage = 0; }
        }
        PlayStage::Resolution => {
            play.ticks_in_stage += 1;
            for (i, player) in offense.iter_mut().enumerate() {
                if i == handler_idx {
                    let penetration = (play.ticks_in_stage as f32 * 0.15).min(5.0);
                    player.target_position = Vec2::new(0.0, basket_dir * (6.325 + penetration));
                } else if player.position == Position::C {
                    player.locomotion_state = LocomotionState::Sprinting;
                    player.target_position = Vec2::new(0.0, basket_dir * HALF_LENGTH);
                } else {
                    let wave = ((play.ticks_in_stage as f32 * 0.05) + i as f32).cos() * 0.6;
                    let base_target = if i % 2 == 0 { wing_left } else { wing_right };
                    player.target_position = base_target + Vec2::new(wave, wave * basket_dir);
                }
            }
            if play.ticks_in_stage > 25 {
                play.stage = PlayStage::Inception;
                play.ticks_in_stage = 0;
            }
        }
    }
}

fn tick_pace_and_space(_play: &mut ActivePlay, offense: &mut [&mut Player], basket_dir: f32) {
    for player in offense.iter_mut() {
        match player.position {
            Position::PG => player.target_position = Vec2::new(0.0, 6.5 * basket_dir),
            Position::SG => player.target_position = Vec2::new(4.5, 8.0 * basket_dir),
            Position::SF => player.target_position = Vec2::new(-4.5, 8.0 * basket_dir),
            Position::PF => player.target_position = Vec2::new(-2.0, 12.0 * basket_dir),
            Position::C => player.target_position = Vec2::new(2.0, 12.0 * basket_dir),
        }
    }
}

pub fn mirror_defensive_targets(defense: &mut Team, offense: &Team, basket_dir: f32, ball_handler_id: Option<PlayerId>) {
    let def_ids: Vec<(PlayerId, Position)> = defense.starters().iter().map(|s| (s.id, s.position.clone())).collect();
    let off_current: Vec<(PlayerId, Position, Vec2)> = offense.starters().iter().map(|s| (s.id, s.position.clone(), s.current_position)).collect();
    let hoop_pos = Vec2::new(0.0, basket_dir * HALF_LENGTH);

    for (def_id, def_pos) in &def_ids {
        if let Some((off_id, _, off_pos)) = off_current.iter().find(|(_, pos, _)| pos == def_pos) {
            let dir_to_hoop = (hoop_pos - *off_pos).normalize_or_zero();
            let distance = if Some(*off_id) == ball_handler_id {
                0.8
            } else {
                let dist_to_hoop = off_pos.distance(hoop_pos);
                if dist_to_hoop > 8.0 { 2.5 } else { 1.2 }
            };
            let target = *off_pos + dir_to_hoop * distance;
            if let Some(p) = defense.players.iter_mut().find(|p| p.id == *def_id) {
                p.target_position = target;
            }
        }
    }
}

fn tick_triangle(play: &mut ActivePlay, offense: &mut [&mut Player], basket_dir: f32) {
    play.ticks_in_stage += 1;
    let time_offset = (play.ticks_in_stage as f32) * 0.04;
    for (i, player) in offense.iter_mut().enumerate() {
        let pos = [
            Vec2::new(-2.0, 6.325 * basket_dir),
            Vec2::new(4.0, 8.325 * basket_dir),
            Vec2::new(-3.0, 10.325 * basket_dir),
            Vec2::new(0.0, 8.825 * basket_dir),
            Vec2::new(2.5, 12.825 * basket_dir),
        ];
        let mut target = pos[i.min(4)];
        if i > 0 { // Subtle off-ball movement to simulate getting open
            let wave_x = (time_offset + i as f32 * 1.5).cos() * 0.8;
            let wave_y = (time_offset + i as f32 * 1.5).sin() * 0.8 * basket_dir;
            target += Vec2::new(wave_x, wave_y);
        }
        player.target_position = target;
    }
}

fn tick_motion(play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    let handler_idx = offense.iter().position(|p| p.id == handler_id).unwrap_or(0);
    play.ticks_in_stage += 1;
    let time_offset = (play.ticks_in_stage as f32) * 0.05;

    for (i, player) in offense.iter_mut().enumerate() {
        if i == handler_idx {
            player.target_position = Vec2::new(time_offset.sin() * 2.0, basket_dir * 7.5);
        } else {
            let angle = (i as f32 * 1.25) + (time_offset * 0.3);
            let radius = if player.position == Position::C || player.position == Position::PF { 5.0 } else { 8.0 };
            player.target_position = Vec2::new(angle.cos() * radius, basket_dir * (5.0 + angle.sin() * 4.0));
        }
    }
}

fn tick_isolation(_play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    let handler_idx = offense.iter().position(|p| p.id == handler_id).unwrap_or(0);
    for (i, player) in offense.iter_mut().enumerate() {
        if i == handler_idx {
            player.target_position = Vec2::new(0.0, 7.0 * basket_dir);
        } else {
            let pos = [
                Vec2::new(-7.0, 12.0 * basket_dir), Vec2::new(7.0, 12.0 * basket_dir),
                Vec2::new(-6.0, 8.0 * basket_dir), Vec2::new(6.0, 8.0 * basket_dir),
                Vec2::new(-7.0, 12.0 * basket_dir),
            ];
            player.target_position = pos[i];
        }
    }
}

fn tick_post_up(_play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    let handler_idx = offense.iter().position(|p| p.id == handler_id).unwrap_or(0);
    for (i, player) in offense.iter_mut().enumerate() {
        if player.position == Position::C || player.position == Position::PF {
            if i == handler_idx {
                player.target_position = Vec2::new(-3.0, 11.0 * basket_dir);
            } else {
                player.target_position = Vec2::new(3.0, 11.0 * basket_dir);
            }
        } else {
            let pos = [
                Vec2::new(0.0, 7.0 * basket_dir), Vec2::new(6.0, 9.0 * basket_dir),
                Vec2::new(-6.0, 9.0 * basket_dir), Vec2::new(0.0, 7.0 * basket_dir),
                Vec2::new(0.0, 7.0 * basket_dir),
            ];
            player.target_position = pos[i];
        }
    }
}

fn tick_princeton(play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    play.ticks_in_stage += 1;
    let time_offset = (play.ticks_in_stage as f32) * 0.04;
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    for (i, player) in offense.iter_mut().enumerate() {
        let mut target = match player.position {
            Position::PG => Vec2::new(3.0, 7.0 * basket_dir),
            Position::SG => Vec2::new(-3.0, 7.0 * basket_dir),
            Position::SF => Vec2::new(-6.0, 10.0 * basket_dir),
            Position::PF => Vec2::new(6.0, 10.0 * basket_dir),
            Position::C => Vec2::new(0.0, 10.0 * basket_dir),
        };
        if player.id != handler_id {
            let wave_x = (time_offset + i as f32 * 1.5).cos() * 0.8;
            let wave_y = (time_offset + i as f32 * 1.5).sin() * 0.8 * basket_dir;
            target += Vec2::new(wave_x, wave_y);
        }
        player.target_position = target;
    }
}

fn tick_seven_seconds(play: &mut ActivePlay, offense: &mut [&mut Player], ball_holder_id: Option<PlayerId>, basket_dir: f32) {
    play.ticks_in_stage += 1;
    let time_offset = (play.ticks_in_stage as f32) * 0.05;
    let handler_id = ball_holder_id.unwrap_or_else(|| offense[0].id);
    let handler_idx = offense.iter().position(|p| p.id == handler_id).unwrap_or(0);
    for (i, player) in offense.iter_mut().enumerate() {
        if i == handler_idx {
            player.target_position = Vec2::new(0.0, 5.0 * basket_dir);
        } else {
            let pos = [
                Vec2::new(-7.0, 12.0 * basket_dir), Vec2::new(7.0, 12.0 * basket_dir),
                Vec2::new(-5.0, 7.0 * basket_dir), Vec2::new(5.0, 7.0 * basket_dir),
                Vec2::new(-7.0, 12.0 * basket_dir),
            ];
            let mut target = pos[i];
            let wave_x = (time_offset + i as f32 * 1.2).cos() * 0.8;
            let wave_y = (time_offset + i as f32 * 1.2).sin() * 0.8 * basket_dir;
            target += Vec2::new(wave_x, wave_y);
            player.target_position = target;
        }
    }
}
