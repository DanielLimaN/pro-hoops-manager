use godot::prelude::*;
use crate::engine::types::*;

pub fn tactic_to_dict(t: &TacticConfig) -> VarDictionary {
    let mut d = VarDictionary::new();
    let off_str = match t.offensive {
        OffensiveTactic::Motion => "Motion",
        OffensiveTactic::Isolation => "Isolation",
        OffensiveTactic::PickAndRoll => "PickAndRoll",
        OffensiveTactic::PostUp => "PostUp",
        OffensiveTactic::Princeton => "Princeton",
        OffensiveTactic::Triangle => "Triangle",
        OffensiveTactic::SevenSeconds => "SevenSeconds",
    };
    let def_str = match t.defensive {
        DefensiveTactic::ManToMan => "ManToMan",
        DefensiveTactic::Zone2_3 => "Zone2_3",
        DefensiveTactic::Zone3_2 => "Zone3_2",
        DefensiveTactic::FullCourtPress => "FullCourtPress",
        DefensiveTactic::HalfCourtTrap => "HalfCourtTrap",
        DefensiveTactic::BoxAndOne => "BoxAndOne",
    };
    d.set("offensive", &GString::from(off_str));
    d.set("defensive", &GString::from(def_str));
    d.set("pace", t.pace as f64);
    d.set("three_frequency", t.three_frequency as f64);
    d.set("physicality", t.physicality as f64);
    d
}

pub fn tactic_from_dict(d: &VarDictionary) -> TacticConfig {
    let off_str = d.get("offensive").map_or(GString::new(), |v| v.to::<GString>()).to_string();
    let def_str = d.get("defensive").map_or(GString::new(), |v| v.to::<GString>()).to_string();
    let offensive = match off_str.as_str() {
        "Isolation" => OffensiveTactic::Isolation,
        "PickAndRoll" => OffensiveTactic::PickAndRoll,
        "PostUp" => OffensiveTactic::PostUp,
        "Princeton" => OffensiveTactic::Princeton,
        "Triangle" => OffensiveTactic::Triangle,
        "SevenSeconds" => OffensiveTactic::SevenSeconds,
        _ => OffensiveTactic::Motion,
    };
    let defensive = match def_str.as_str() {
        "Zone2_3" => DefensiveTactic::Zone2_3,
        "Zone3_2" => DefensiveTactic::Zone3_2,
        "FullCourtPress" => DefensiveTactic::FullCourtPress,
        "HalfCourtTrap" => DefensiveTactic::HalfCourtTrap,
        "BoxAndOne" => DefensiveTactic::BoxAndOne,
        _ => DefensiveTactic::ManToMan,
    };
    TacticConfig {
        offensive, defensive,
        pace: d.get("pace").map_or(50.0, |v| v.to::<f64>()) as f32,
        three_frequency: d.get("three_frequency").map_or(35.0, |v| v.to::<f64>()) as f32,
        physicality: d.get("physicality").map_or(50.0, |v| v.to::<f64>()) as f32,
    }
}

fn attr_dict(attrs: &PlayerAttributes) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("speed", attrs.speed as f64);
    d.set("strength", attrs.strength as f64);
    d.set("stamina", attrs.stamina as f64);
    d.set("jumping", attrs.jumping as f64);
    d.set("height_cm", attrs.height_cm as f64);
    d.set("weight_kg", attrs.weight_kg as f64);
    d.set("three_pt", attrs.three_pt as f64);
    d.set("mid_range", attrs.mid_range as f64);
    d.set("close_shot", attrs.close_shot as f64);
    d.set("dunk", attrs.dunk as f64);
    d.set("layup", attrs.layup as f64);
    d.set("free_throw", attrs.free_throw as f64);
    d.set("ball_handle", attrs.ball_handle as f64);
    d.set("passing", attrs.passing as f64);
    d.set("offensive_rebound", attrs.offensive_rebound as f64);
    d.set("perimeter_def", attrs.perimeter_def as f64);
    d.set("interior_def", attrs.interior_def as f64);
    d.set("steal", attrs.steal as f64);
    d.set("block", attrs.block as f64);
    d.set("defensive_rebound", attrs.defensive_rebound as f64);
    d.set("basketball_iq", attrs.basketball_iq as f64);
    d.set("clutch", attrs.clutch as f64);
    d.set("overall", attrs.overall() as f64);
    d.set("potential", attrs.potential as f64);
    d
}

pub fn player_to_dict(p: &Player) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("id", p.id as i64);
    d.set("first_name", &GString::from(&p.first_name));
    d.set("last_name", &GString::from(&p.last_name));
    let pos_str = match p.position {
        Position::PG => "PG", Position::SG => "SG", Position::SF => "SF",
        Position::PF => "PF", Position::C => "C",
    };
    d.set("position", &GString::from(pos_str));
    d.set("age", p.age as i64);
    d.set("attributes", &attr_dict(&p.attributes));
    d.set("morale", p.morale as f64);
    d.set("salary", p.salary as i64);
    d.set("contract_year", p.contract_year as i64);
    d.set("overall", p.attributes.overall() as f64);
    
    let mut portrait = VarDictionary::new();
    let skin_str = match p.portrait_config.skin_tone {
        crate::engine::types::SkinTone::Light => "light",
        crate::engine::types::SkinTone::Tan => "tan",
        crate::engine::types::SkinTone::Medium => "medium",
        crate::engine::types::SkinTone::Dark => "dark",
        crate::engine::types::SkinTone::Olive => "olive",
    };
    let hair_str = match p.portrait_config.hair_style {
        crate::engine::types::HairStyle::Short => "short",
        crate::engine::types::HairStyle::Afro => "afro",
        crate::engine::types::HairStyle::Buzzcut => "buzzcut",
        crate::engine::types::HairStyle::None => "none",
    };
    let color_str = match p.portrait_config.hair_color {
        crate::engine::types::HairColor::Black => "black",
        crate::engine::types::HairColor::Blonde => "blonde",
        crate::engine::types::HairColor::Brown => "brown",
        crate::engine::types::HairColor::Gray => "gray",
        crate::engine::types::HairColor::Red => "red",
    };
    let beard_str = match p.portrait_config.facial_hair_style {
        crate::engine::types::FacialHairStyle::Full => "full",
        crate::engine::types::FacialHairStyle::None => "none",
    };
    portrait.set("skin_tone", &GString::from(skin_str));
    portrait.set("hair_style", &GString::from(hair_str));
    portrait.set("hair_color", &GString::from(color_str));
    portrait.set("facial_hair_style", &GString::from(beard_str));
    d.set("portrait_config", &portrait);
    
    d
}

pub fn team_to_dict(t: &Team) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("id", t.id as i64);
    d.set("name", &GString::from(&t.name));
    d.set("city", &GString::from(&t.city));
    d.set("abbreviation", &GString::from(&t.abbreviation));
    d.set("chemistry", t.chemistry as f64);
    d.set("wins", t.wins as i64);
    d.set("losses", t.losses as i64);
    d.set("tactic", &tactic_to_dict(&t.tactic));

    let starters = t.starters();
    let mut starter_arr = VarArray::new();
    for s in &starters { starter_arr.push(&player_to_dict(s)); }
    d.set("starters", &starter_arr);

    let mut rotation_order_arr = VarArray::new();
    for pid in &t.rotation_order {
        rotation_order_arr.push(*pid as i64);
    }
    d.set("rotation_order", &rotation_order_arr);

    let mut player_arr = VarArray::new();
    for p in &t.players { player_arr.push(&player_to_dict(p)); }
    d.set("players", &player_arr);
    d
}

pub fn league_to_dict(l: &League) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("season", l.season as i64);
    d.set("current_week", l.current_week as i64);
    d.set("playoffs_active", l.playoffs_active);

    let mut team_arr = VarArray::new();
    for t in &l.teams { team_arr.push(&team_to_dict(t)); }
    d.set("teams", &team_arr);

    let mut sched_arr = VarArray::new();
    for sg in &l.schedule {
        let mut sd = VarDictionary::new();
        sd.set("id", sg.id as i64);
        sd.set("home_team", sg.home_team as i64);
        sd.set("away_team", sg.away_team as i64);
        sd.set("week", sg.week as i64);
        sd.set("played", sg.played);
        sd.set("is_playoff", sg.is_playoff);
        if let Some(s) = sg.home_score { sd.set("home_score", s as i64); }
        if let Some(s) = sg.away_score { sd.set("away_score", s as i64); }
        sched_arr.push(&sd);
    }
    d.set("schedule", &sched_arr);

    // Playoff series
    let mut playoff_arr = VarArray::new();
    for ps in &l.playoff_series {
        let mut pd = VarDictionary::new();
        let round_str = match ps.round {
            PlayoffRound::Quarterfinals => "quarterfinals",
            PlayoffRound::Semifinals => "semifinals",
            PlayoffRound::Finals => "finals",
        };
        pd.set("round", &GString::from(round_str));
        pd.set("series_id", ps.series_id as i64);
        pd.set("higher_seed", ps.higher_seed as i64);
        pd.set("lower_seed", ps.lower_seed as i64);
        pd.set("higher_seed_wins", ps.higher_seed_wins as i64);
        pd.set("lower_seed_wins", ps.lower_seed_wins as i64);
        pd.set("completed", ps.completed);
        if let Some(w) = ps.winner { pd.set("winner", w as i64); }
        playoff_arr.push(&pd);
    }
    d.set("playoff_series", &playoff_arr);

    d.set("events", &events_to_arr(&l.events));

    d
}

pub fn event_to_dict(evt: &MatchEvent) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("tick", evt.tick as i64);
    d.set("text", &GString::from(&evt.text));

    let mut sd = VarDictionary::new();
    sd.set("home", evt.score.home as i64);
    sd.set("away", evt.score.away as i64);
    sd.set("quarter", &GString::from(&evt.score.quarter));
    sd.set("clock_seconds", evt.score.clock_seconds as i64);
    sd.set("shot_clock", evt.score.shot_clock as i64);
    sd.set("home_fouls", evt.score.home_fouls as i64);
    sd.set("away_fouls", evt.score.away_fouls as i64);
    d.set("score", &sd);

    let action_type = match &evt.action {
        ActionType::Pass { .. } => "pass",
        ActionType::Shot { result, .. } => match result {
            ShotResult::Made => "shot_made", _ => "shot_missed",
        },
        ActionType::Rebound { .. } => "rebound",
        ActionType::Steal { .. } => "steal",
        ActionType::Block { .. } => "block",
        ActionType::Turnover { .. } => "turnover",
        ActionType::OffensiveFoul { .. } => "offensive_foul",
        ActionType::IllegalScreen { .. } => "illegal_screen",
        ActionType::QuarterEnd => "quarter_end",
        ActionType::GameEnd => "game_end",
        ActionType::Tick => "tick",
        _ => "other",
    };
    d.set("action_type", &GString::from(action_type));

    let mut pos_arr = VarArray::new();
    for pp in &evt.positions {
        let mut pd = VarDictionary::new();
        pd.set("player_id", pp.player_id as i64);
        pd.set("x", pp.x as f64);
        pd.set("z", pp.z as f64);
        pd.set("y", pp.y as f64);
        pd.set("angle", pp.angle as f64);
        pd.set("animation", &GString::from(&pp.animation));
        pos_arr.push(&pd);
    }
    d.set("positions", &pos_arr);

    let mut bd = VarDictionary::new();
    bd.set("x", evt.ball.x as f64);
    bd.set("y", evt.ball.y as f64);
    bd.set("z", evt.ball.z as f64);
    if let Some(h) = evt.ball.holder { bd.set("holder", h as i64); }
    d.set("ball", &bd);

    d
}

pub fn game_event_to_dict(evt: &GameEvent) -> VarDictionary {
    let mut d = VarDictionary::new();
    d.set("id", evt.id as i64);
    d.set("event_type", &GString::from(&evt.event_type));
    d.set("season", evt.season as i64);
    d.set("year", evt.year as i64);
    d.set("month", evt.month as i64);
    d.set("day", evt.day as i64);
    d.set("hour", evt.hour as i64);
    d.set("minute", evt.minute as i64);
    if let Some(ref comp) = evt.competition {
        d.set("competition", &GString::from(comp));
    }
    d.set("description", &GString::from(&evt.description));
    d.set("is_completed", evt.is_completed);
    if let Some(id) = evt.home_team_id { d.set("home_team_id", id as i64); }
    if let Some(id) = evt.away_team_id { d.set("away_team_id", id as i64); }
    if let Some(id) = evt.game_id { d.set("game_id", id as i64); }
    if let Some(p) = evt.is_playoff { d.set("is_playoff", p); }
    if let Some(ref s) = evt.phase_label { d.set("phase_label", &GString::from(s)); }
    if let Some(ref s) = evt.cup_stage { d.set("cup_stage", &GString::from(s)); }
    d
}

pub fn game_event_from_dict(d: &VarDictionary) -> GameEvent {
    let home_id: Option<u32> = d.get("home_team_id")
        .and_then(|v| { let id = v.to::<i64>() as u32; if id == 0 { None } else { Some(id) } });
    let away_id: Option<u32> = d.get("away_team_id")
        .and_then(|v| { let id = v.to::<i64>() as u32; if id == 0 { None } else { Some(id) } });
    let g_id: Option<u32> = d.get("game_id")
        .and_then(|v| { let id = v.to::<i64>() as u32; if id == 0 { None } else { Some(id) } });
    GameEvent {
        id: d.get("id").map_or(0, |v| v.to::<i64>()) as u32,
        event_type: d.get("event_type").map_or(GString::new(), |v| v.to::<GString>()).to_string(),
        season: d.get("season").map_or(0, |v| v.to::<i64>()) as u16,
        year: d.get("year").map_or(0, |v| v.to::<i64>()) as u16,
        month: d.get("month").map_or(1, |v| v.to::<i64>()) as u8,
        day: d.get("day").map_or(1, |v| v.to::<i64>()) as u8,
        hour: d.get("hour").map_or(20, |v| v.to::<i64>()) as u8,
        minute: d.get("minute").map_or(0, |v| v.to::<i64>()) as u8,
        competition: d.get("competition").map(|v| v.to::<GString>().to_string()),
        description: d.get("description").map_or(GString::new(), |v| v.to::<GString>()).to_string(),
        is_completed: d.get("is_completed").map_or(false, |v| v.to::<bool>()),
        home_team_id: home_id,
        away_team_id: away_id,
        game_id: g_id,
        is_playoff: d.get("is_playoff").map(|v| v.to::<bool>()),
        phase_label: d.get("phase_label").map(|v| v.to::<GString>().to_string()),
        cup_stage: d.get("cup_stage").map(|v| v.to::<GString>().to_string()),
    }
}

pub fn events_to_arr(events: &[GameEvent]) -> VarArray {
    let mut arr = VarArray::new();
    for evt in events {
        arr.push(&game_event_to_dict(evt));
    }
    arr
}

pub fn events_from_arr(arr: &VarArray) -> Vec<GameEvent> {
    let mut events = Vec::new();
    for i in 0..arr.len() {
        if let Some(variant) = arr.get(i) {
            if let Ok(dict) = variant.try_to::<VarDictionary>() {
                events.push(game_event_from_dict(&dict));
            }
        }
    }
    events
}

pub fn schedule_to_arr(schedule: &[ScheduledGame]) -> VarArray {
    let mut arr = VarArray::new();
    for sg in schedule {
        let mut d = VarDictionary::new();
        d.set("id", sg.id as i64);
        d.set("home_team", sg.home_team as i64);
        d.set("away_team", sg.away_team as i64);
        d.set("week", sg.week as i64);
        d.set("played", sg.played);
        d.set("is_playoff", sg.is_playoff);
        if let Some(s) = sg.home_score { d.set("home_score", s as i64); }
        if let Some(s) = sg.away_score { d.set("away_score", s as i64); }
        arr.push(&d);
    }
    arr
}
