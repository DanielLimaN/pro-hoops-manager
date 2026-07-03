use std::collections::{HashMap, VecDeque};
use std::sync::mpsc::{self, Receiver, Sender, TryRecvError};
use std::sync::{Arc, Mutex};
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread::{self, JoinHandle};
use std::time::Duration;

use serde_json::{json, Value};

use crate::engine::*;
use crate::engine::player::apply_training_progression;
use crate::state::GameState;

#[derive(Debug)]
pub enum SimCommand {
    SimulateToWeek { target_week: u16 },
    Resume { simulate_match: bool },
    Cancel,
    Shutdown,
}

#[derive(Debug, Clone)]
pub struct SimEvent {
    pub kind: SimEventKind,
    pub data: HashMap<String, Value>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum SimEventKind {
    MatchSimulated,
    DayAdvanced,
    ProgressUpdate,
    MatchDay,
    SimulationComplete,
    Cancelled,
    Error,
}

impl SimEvent {
    pub fn kind_str(&self) -> &'static str {
        match self.kind {
            SimEventKind::MatchSimulated => "match_simulated",
            SimEventKind::DayAdvanced => "day_advanced",
            SimEventKind::ProgressUpdate => "progress_update",
            SimEventKind::MatchDay => "match_day",
            SimEventKind::SimulationComplete => "simulation_complete",
            SimEventKind::Cancelled => "cancelled",
            SimEventKind::Error => "error",
        }
    }
}

fn push_event(queue: &Arc<Mutex<VecDeque<SimEvent>>>, event: SimEvent) {
    if let Ok(mut q) = queue.lock() {
        q.push_back(event);
    }
}

fn make_progress_data(completed: u32, total: u32, message: &str) -> HashMap<String, Value> {
    let mut h = HashMap::new();
    h.insert("completed".into(), json!(completed));
    h.insert("total".into(), json!(total));
    let p = if total > 0 { completed as f64 / total as f64 } else { 0.0 };
    h.insert("progress".into(), json!(p));
    h.insert("message".into(), json!(message));
    h
}

fn make_match_day_data(
    home_id: u32,
    away_id: u32,
    week: u16,
    league: &League,
) -> HashMap<String, Value> {
    let mut h = HashMap::new();
    h.insert("home_id".into(), json!(home_id));
    h.insert("away_id".into(), json!(away_id));
    h.insert("week".into(), json!(week));
    if let Some(t) = league.teams.iter().find(|t| t.id == home_id) {
        h.insert("home_name".into(), json!(t.name));
        h.insert("home_abbr".into(), json!(t.abbreviation));
    }
    if let Some(t) = league.teams.iter().find(|t| t.id == away_id) {
        h.insert("away_name".into(), json!(t.name));
        h.insert("away_abbr".into(), json!(t.abbreviation));
    }
    h
}

fn make_match_result_data(
    league: &League,
    schedule_idx: usize,
    user_id: u32,
) -> HashMap<String, Value> {
    let sg = &league.schedule[schedule_idx];
    let is_home = sg.home_team == user_id;
    let opp_id = if is_home { sg.away_team } else { sg.home_team };
    let opp_name = league.teams.iter()
        .find(|t| t.id == opp_id)
        .map(|t| t.abbreviation.as_str())
        .unwrap_or("OPP");
    let h_score = sg.home_score.unwrap_or(0);
    let a_score = sg.away_score.unwrap_or(0);
    let won = (is_home && h_score > a_score) || (!is_home && a_score > h_score);

    let mut h = HashMap::new();
    h.insert("team_id".into(), json!(user_id));
    h.insert("opponent".into(), json!(opp_name));
    h.insert("home_score".into(), json!(h_score));
    h.insert("away_score".into(), json!(a_score));
    h.insert("home_id".into(), json!(sg.home_team));
    h.insert("away_id".into(), json!(sg.away_team));
    h.insert("won".into(), json!(won));
    h.insert("is_home".into(), json!(is_home));
    h.insert("week".into(), json!(sg.week));
    h.insert("is_playoff".into(), json!(sg.is_playoff));
    h
}

fn make_day_advanced_data(league: &League, user_id: u32) -> HashMap<String, Value> {
    let mut h = HashMap::new();
    h.insert("week".into(), json!(league.current_week));
    h.insert("season".into(), json!(league.season));
    h.insert("playoffs_active".into(), json!(league.playoffs_active));
    let stats = make_stats_map(league, user_id);
    h.insert("stats".into(), json!(stats));
    h
}

fn make_stats_map(league: &League, user_id: u32) -> HashMap<String, Value> {
    let mut h = HashMap::new();
    if let Some(team) = league.teams.iter().find(|t| t.id == user_id) {
        h.insert("wins".into(), json!(team.wins));
        h.insert("losses".into(), json!(team.losses));
        let total_salary: u64 = team.players.iter().map(|p| p.salary as u64).sum();
        let budget = 150_000_000i64 - total_salary as i64;
        h.insert("budget".into(), json!(budget));
        let avg_morale = if team.players.is_empty() { 100.0 } else {
            team.players.iter().map(|p| p.morale as f64).sum::<f64>() / team.players.len() as f64
        };
        h.insert("morale".into(), json!((avg_morale * 100.0).round() / 100.0));
        let avg_stamina = if team.players.is_empty() { 100.0 } else {
            team.players.iter().map(|p| p.attributes.stamina as f64).sum::<f64>() / team.players.len() as f64
        };
        h.insert("energy".into(), json!((avg_stamina * 100.0).round() / 100.0));
    } else {
        h.insert("wins".into(), json!(0));
        h.insert("losses".into(), json!(0));
        h.insert("budget".into(), json!(0f64));
        h.insert("morale".into(), json!(100.0));
        h.insert("energy".into(), json!(100.0));
    }
    h
}

fn generate_playoffs(league: &mut League) {
    league.playoffs_active = true;
    let mut ranked: Vec<u32> = league.teams.iter().map(|t| t.id).collect();
    ranked.sort_by(|a, b| {
        let ta = league.teams.iter().find(|t| t.id == *a).unwrap();
        let tb = league.teams.iter().find(|t| t.id == *b).unwrap();
        tb.wins.cmp(&ta.wins)
    });
    let mut game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;
    let matchups: [(usize, usize); 4] = [(0, 7), (3, 4), (1, 6), (2, 5)];
    for (i, &(hi, lo)) in matchups.iter().enumerate() {
        let higher = ranked[hi];
        let lower = ranked[lo];
        league.schedule.push(ScheduledGame {
            id: game_id, home_team: higher, away_team: lower, week: 23,
            played: false, is_playoff: true, home_score: None, away_score: None,
        });
        game_id += 1;
        league.playoff_series.push(PlayoffSeries {
            round: PlayoffRound::Quarterfinals, series_id: i as u32,
            higher_seed: higher, lower_seed: lower,
            higher_seed_wins: 0, lower_seed_wins: 0,
            completed: false, winner: None,
        });
    }
}

fn generate_semifinals(league: &mut League) {
    if league.playoff_series.iter().any(|s| s.round == PlayoffRound::Semifinals) { return; }
    let mut game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;
    let w_a1 = league.playoff_series[0].winner.unwrap();
    let w_a2 = league.playoff_series[1].winner.unwrap();
    let (ha, aa) = if w_a1 < w_a2 { (w_a1, w_a2) } else { (w_a2, w_a1) };
    league.schedule.push(ScheduledGame {
        id: game_id, home_team: ha, away_team: aa, week: 24,
        played: false, is_playoff: true, home_score: None, away_score: None,
    });
    game_id += 1;
    league.playoff_series.push(PlayoffSeries {
        round: PlayoffRound::Semifinals, series_id: 4,
        higher_seed: ha, lower_seed: aa,
        higher_seed_wins: 0, lower_seed_wins: 0, completed: false, winner: None,
    });
    let w_b1 = league.playoff_series[2].winner.unwrap();
    let w_b2 = league.playoff_series[3].winner.unwrap();
    let (hb, ab) = if w_b1 < w_b2 { (w_b1, w_b2) } else { (w_b2, w_b1) };
    league.schedule.push(ScheduledGame {
        id: game_id + 1, home_team: hb, away_team: ab, week: 24,
        played: false, is_playoff: true, home_score: None, away_score: None,
    });
    league.playoff_series.push(PlayoffSeries {
        round: PlayoffRound::Semifinals, series_id: 5,
        higher_seed: hb, lower_seed: ab,
        higher_seed_wins: 0, lower_seed_wins: 0, completed: false, winner: None,
    });
}

fn generate_finals(league: &mut League) {
    if league.playoff_series.iter().any(|s| s.round == PlayoffRound::Finals) { return; }
    let game_id = league.schedule.iter().map(|g| g.id).max().unwrap_or(0) + 1;
    let w1 = league.playoff_series[4].winner.unwrap();
    let w2 = league.playoff_series[5].winner.unwrap();
    let (h, a) = if w1 < w2 { (w1, w2) } else { (w2, w1) };
    league.schedule.push(ScheduledGame {
        id: game_id, home_team: h, away_team: a, week: 25,
        played: false, is_playoff: true, home_score: None, away_score: None,
    });
    league.playoff_series.push(PlayoffSeries {
        round: PlayoffRound::Finals, series_id: 6,
        higher_seed: h, lower_seed: a,
        higher_seed_wins: 0, lower_seed_wins: 0, completed: false, winner: None,
    });
}

fn resolve_playoff_round(league: &mut League, week: u16) {
    for series in league.playoff_series.iter_mut() {
        if series.completed { continue; }
        let sw = match series.round {
            PlayoffRound::Quarterfinals => 23,
            PlayoffRound::Semifinals => 24,
            PlayoffRound::Finals => 25,
        };
        if sw != week { continue; }
        for g in &league.schedule {
            if g.week != week || !g.played { continue; }
            let involved = (g.home_team == series.higher_seed && g.away_team == series.lower_seed)
                || (g.home_team == series.lower_seed && g.away_team == series.higher_seed);
            if !involved { continue; }
            let ih = g.home_team == series.higher_seed;
            let (hs, ls) = if ih { (g.home_score, g.away_score) } else { (g.away_score, g.home_score) };
            if let (Some(hsv), Some(lsv)) = (hs, ls) {
                series.winner = Some(if hsv > lsv { series.higher_seed } else { series.lower_seed });
                series.completed = true;
            }
            break;
        }
    }
}

fn simulate_game(
    schedule_idx: usize,
    league: &mut League,
    player_stats_delta: &mut std::collections::HashMap<u32, PlayerStats>,
) {
    let g = &league.schedule[schedule_idx];
    let home_id = g.home_team;
    let away_id = g.away_team;

    let home_team = league.teams.iter().find(|t| t.id == home_id).cloned().unwrap();
    let away_team = league.teams.iter().find(|t| t.id == away_id).cloned().unwrap();

    let mut sim = MatchSimulator::new(home_team.clone(), away_team.clone());
    sim.store_events = false;
    let events = sim.simulate_full();

    let fh = sim.home_score;
    let fa = sim.away_score;

    for p in home_team.players.iter().chain(away_team.players.iter()) {
        player_stats_delta.entry(p.id).or_default().games_played += 1;
    }

    let mut last_passer = None;
    for evt in events {
        match evt.action {
            ActionType::Pass { from, .. } => { last_passer = Some(from); },
            ActionType::Shot { player, shot_type, result, .. } => {
                let s = player_stats_delta.entry(player).or_default();
                if result == ShotResult::Made {
                    if shot_type == ShotType::ThreePointer { s.points += 3.0; } else { s.points += 2.0; }
                    if let Some(passer) = last_passer {
                        if passer != player { player_stats_delta.entry(passer).or_default().assists += 1.0; }
                    }
                }
                last_passer = None;
            },
            ActionType::Rebound { player, .. } => { player_stats_delta.entry(player).or_default().rebounds += 1.0; last_passer = None; },
            ActionType::Steal { defender, .. } => { player_stats_delta.entry(defender).or_default().steals += 1.0; last_passer = None; },
            ActionType::Block { defender, .. } => { player_stats_delta.entry(defender).or_default().blocks += 1.0; },
            ActionType::Turnover { player, .. } => { player_stats_delta.entry(player).or_default().turnovers += 1.0; last_passer = None; },
            ActionType::FreeThrow { player, result } => {
                if result == ShotResult::Made { player_stats_delta.entry(player).or_default().points += 1.0; }
                last_passer = None;
            },
            _ => {}
        }
    }

    let sg = &mut league.schedule[schedule_idx];
    sg.played = true;
    sg.home_score = Some(fh);
    sg.away_score = Some(fa);

    let (hw, aw) = if fh > fa { (1, 0) } else { (0, 1) };
    for team in league.teams.iter_mut() {
        if team.id == home_id {
            team.wins += hw;
            team.losses += aw;
        } else if team.id == away_id {
            team.wins += aw;
            team.losses += hw;
        }
        for p in team.players.iter_mut() {
            if let Some(delta) = player_stats_delta.get(&p.id) {
                p.stats_season.games_played += delta.games_played;
                p.stats_season.points += delta.points;
                p.stats_season.rebounds += delta.rebounds;
                p.stats_season.assists += delta.assists;
                p.stats_season.steals += delta.steals;
                p.stats_season.blocks += delta.blocks;
                p.stats_season.turnovers += delta.turnovers;
            }
        }
    }
}

pub struct SimulationWorker {
    command_tx: Sender<SimCommand>,
    handle: Option<JoinHandle<()>>,
    result_queue: Arc<Mutex<VecDeque<SimEvent>>>,
    cancel_flag: Arc<AtomicBool>,
    working_state: Arc<Mutex<GameState>>,
}

impl SimulationWorker {
    pub fn new(initial_state: GameState) -> Self {
        let result_queue: Arc<Mutex<VecDeque<SimEvent>>> = Arc::new(Mutex::new(VecDeque::new()));
        let cancel_flag = Arc::new(AtomicBool::new(false));
        let working_state = Arc::new(Mutex::new(initial_state.clone()));
        let (command_tx, command_rx) = mpsc::channel::<SimCommand>();

        let rq = result_queue.clone();
        let cf = cancel_flag.clone();
        let ws = working_state.clone();

        let handle = thread::Builder::new()
            .name("sim-worker".into())
            .spawn(move || {
                Self::worker_loop(initial_state, command_rx, rq, cf, ws);
            })
            .expect("Failed to spawn simulation worker thread");

        Self {
            command_tx,
            handle: Some(handle),
            result_queue,
            cancel_flag,
            working_state,
        }
    }

    pub fn send_command(&self, cmd: SimCommand) {
        let _ = self.command_tx.send(cmd);
    }

    pub fn drain_events(&self) -> Vec<SimEvent> {
        let mut events = Vec::new();
        if let Ok(mut q) = self.result_queue.lock() {
            while let Some(evt) = q.pop_front() {
                events.push(evt);
            }
        }
        events
    }

    pub fn get_working_state(&self) -> Option<GameState> {
        self.working_state.lock().ok().map(|s| s.clone())
    }

    pub fn is_alive(&self) -> bool {
        self.handle.as_ref().map_or(false, |h| !h.is_finished())
    }

    pub fn shutdown(mut self) {
        let _ = self.command_tx.send(SimCommand::Shutdown);
        if let Some(handle) = self.handle.take() {
            let start = std::time::Instant::now();
            loop {
                if handle.is_finished() { break; }
                if start.elapsed() >= Duration::from_secs(3) { break; }
                thread::sleep(Duration::from_millis(10));
            }
        }
    }

    fn worker_loop(
        mut state: GameState,
        command_rx: Receiver<SimCommand>,
        result_queue: Arc<Mutex<VecDeque<SimEvent>>>,
        cancel_flag: Arc<AtomicBool>,
        working_state: Arc<Mutex<GameState>>,
    ) {
        loop {
            match command_rx.try_recv() {
                Ok(SimCommand::SimulateToWeek { target_week }) => {
                    cancel_flag.store(false, Ordering::SeqCst);
                    let user_id = state.user_team_id.unwrap_or(0);

                    let total_games = state.league.as_ref().map_or(0, |l| {
                        l.schedule.iter()
                            .filter(|g| !g.played && g.week <= target_week)
                            .count() as u32
                    });
                    let mut completed = 0u32;

                    while state.league.as_ref().map_or(false, |l| l.current_week <= target_week) {
                        if cancel_flag.load(Ordering::SeqCst) {
                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::Cancelled,
                                data: HashMap::new(),
                            });
                            break;
                        }

                        let cw = {
                            let league = state.league.as_ref().unwrap();
                            league.current_week
                        };

                        // Playoff setup (short league borrow)
                        {
                            let league = state.league.as_mut().unwrap();
                            if cw >= 23 && !league.playoffs_active { generate_playoffs(league); }
                            if league.playoffs_active {
                                if cw == 24 { generate_semifinals(league); }
                                if cw == 25 { generate_finals(league); }
                            }
                        }

                        // Collect unplayed games for this week
                        let gts: Vec<usize> = {
                            let league = state.league.as_ref().unwrap();
                            league.schedule.iter()
                                .enumerate()
                                .filter(|(_, g)| g.week == cw && !g.played)
                                .map(|(i, _)| i)
                                .collect()
                        };

                        if gts.is_empty() {
                            let league = state.league.as_mut().unwrap();
                            league.current_week += 1;
                            for team in league.teams.iter_mut() {
                                for player in team.players.iter_mut() {
                                    apply_training_progression(player, &team.training_focus, 1);
                                }
                            }
                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::DayAdvanced,
                                data: make_day_advanced_data(league, user_id),
                            });
                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::ProgressUpdate,
                                data: make_progress_data(completed, total_games,
                                    &format!("Week {} – no games", cw)),
                            });
                            continue;
                        }

                        // Find user game index (if any)
                        let user_game_idx = {
                            let league = state.league.as_ref().unwrap();
                            gts.iter().find(|&&idx| {
                                let g = &league.schedule[idx];
                                g.home_team == user_id || g.away_team == user_id
                            }).copied()
                        };

                        // Simulate all non-user games of this week
                        {
                            let league = state.league.as_mut().unwrap();
                            let mut all_deltas = std::collections::HashMap::new();
                            for &idx in &gts {
                                if Some(idx) == user_game_idx { continue; }
                                if cancel_flag.load(Ordering::SeqCst) { break; }
                                simulate_game(idx, league, &mut all_deltas);
                                completed += 1;

                                push_event(&result_queue, SimEvent {
                                    kind: SimEventKind::ProgressUpdate,
                                    data: make_progress_data(completed, total_games,
                                        &format!("Game {}", completed)),
                                });
                            }
                        }

                        if cancel_flag.load(Ordering::SeqCst) {
                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::Cancelled,
                                data: HashMap::new(),
                            });
                            break;
                        }

                        // ─── BREAKPOINT: user game found ─────────────────
                        if let Some(ug_idx) = user_game_idx {
                            // Sync working state so the main thread can read it
                            if let Ok(mut ws) = working_state.lock() {
                                *ws = state.clone();
                            }

                            let (home_id, away_id, sg_week, _is_playoff) = {
                                let league = state.league.as_ref().unwrap();
                                let sg = &league.schedule[ug_idx];
                                (sg.home_team, sg.away_team, sg.week, sg.is_playoff)
                            };

                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::MatchDay,
                                data: make_match_day_data(home_id, away_id, sg_week, state.league.as_ref().unwrap()),
                            });

                            // BLOCK — zero CPU until user responds
                            let mut do_simulate = false;
                            let mut got_command = true;
                            loop {
                                match command_rx.recv() {
                                    Ok(SimCommand::Resume { simulate_match }) => {
                                        do_simulate = simulate_match;
                                        break;
                                    }
                                    Ok(SimCommand::Cancel) => {
                                        cancel_flag.store(true, Ordering::SeqCst);
                                        break;
                                    }
                                    Ok(SimCommand::Shutdown) => {
                                        got_command = false;
                                        break;
                                    }
                                    _ => {}
                                }
                            }

                            if !got_command { break; }
                            if cancel_flag.load(Ordering::SeqCst) {
                                push_event(&result_queue, SimEvent {
                                    kind: SimEventKind::Cancelled,
                                    data: HashMap::new(),
                                });
                                break;
                            }

                            if do_simulate {
                                {
                                    let league = state.league.as_mut().unwrap();
                                    let mut match_deltas = std::collections::HashMap::new();
                                    simulate_game(ug_idx, league, &mut match_deltas);
                                }
                                completed += 1;

                                if let Ok(mut ws) = working_state.lock() {
                                    *ws = state.clone();
                                }

                                let result_data = {
                                    let league = state.league.as_ref().unwrap();
                                    make_match_result_data(league, ug_idx, user_id)
                                };
                                push_event(&result_queue, SimEvent {
                                    kind: SimEventKind::MatchSimulated,
                                    data: result_data,
                                });
                                push_event(&result_queue, SimEvent {
                                    kind: SimEventKind::ProgressUpdate,
                                    data: make_progress_data(completed, total_games,
                                        &format!("Game {}", completed)),
                                });
                            }
                        }

                        // Advance to next week
                        {
                            let league = state.league.as_mut().unwrap();
                            league.current_week += 1;
                            if league.playoffs_active { resolve_playoff_round(league, cw); }

                            for team in league.teams.iter_mut() {
                                for player in team.players.iter_mut() {
                                    apply_training_progression(player, &team.training_focus, 1);
                                }
                            }

                            push_event(&result_queue, SimEvent {
                                kind: SimEventKind::DayAdvanced,
                                data: make_day_advanced_data(league, user_id),
                            });
                        }
                    }

                    if !cancel_flag.load(Ordering::SeqCst) {
                        // Sync final state for main thread before sending completion
                        if let Ok(mut ws) = working_state.lock() {
                            *ws = state.clone();
                        }
                        push_event(&result_queue, SimEvent {
                            kind: SimEventKind::SimulationComplete,
                            data: HashMap::new(),
                        });
                    }
                }
                Ok(SimCommand::Resume { simulate_match: _ }) => {
                    // Resume outside of SimulateToWeek context is ignored
                }
                Ok(SimCommand::Cancel) => {
                    cancel_flag.store(true, Ordering::SeqCst);
                }
                Ok(SimCommand::Shutdown) => break,
                Err(TryRecvError::Empty) => {
                    thread::sleep(Duration::from_millis(1));
                }
                Err(TryRecvError::Disconnected) => break,
            }
        }
    }
}

impl Drop for SimulationWorker {
    fn drop(&mut self) {
        self.cancel_flag.store(true, Ordering::SeqCst);
        let _ = self.command_tx.send(SimCommand::Shutdown);
        if let Some(handle) = self.handle.take() {
            let start = std::time::Instant::now();
            loop {
                if handle.is_finished() { break; }
                if start.elapsed() >= Duration::from_secs(3) { break; }
                thread::sleep(Duration::from_millis(10));
            }
        }
    }
}
