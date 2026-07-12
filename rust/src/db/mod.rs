pub mod schema;

use rusqlite::{Connection, Result, params};

pub fn init_db(path: &str) -> Result<Connection> {
    let conn = Connection::open(path)?;
    schema::create_tables(&conn)?;
    Ok(conn)
}

/// Save GameParams to the `settings` table as a JSON blob.
pub fn save_params(conn: &Connection, params: &crate::engine::params::GameParams) -> Result<()> {
    let json = serde_json::to_string(params).unwrap_or_default();
    conn.execute(
        "INSERT OR REPLACE INTO settings (key, value) VALUES ('game_params', ?1)",
        [&json],
    )?;
    Ok(())
}

/// Load GameParams from the `settings` table. Returns `None` if not found.
pub fn load_params(conn: &Connection) -> Result<Option<crate::engine::params::GameParams>> {
    let mut stmt = conn.prepare("SELECT value FROM settings WHERE key = 'game_params'")?;
    let mut rows = stmt.query([])?;
    if let Some(row) = rows.next()? {
        let json: String = row.get(0)?;
        match serde_json::from_str(&json) {
            Ok(params) => Ok(Some(params)),
            Err(e) => {
                eprintln!("[DB] Failed to deserialize game_params: {}", e);
                Ok(None)
            }
        }
    } else {
        Ok(None)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::params::GameParams;

    #[test]
    fn test_save_load_params_roundtrip() {
        let conn = Connection::open_in_memory().unwrap();
        schema::create_tables(&conn).unwrap();

        let params = GameParams::default();
        save_params(&conn, &params).unwrap();

        let loaded = load_params(&conn).unwrap().expect("params should exist");
        assert_eq!(loaded.salary_cap, params.salary_cap);
        assert_eq!(loaded.training_boost_med, params.training_boost_med);
    }

    #[test]
    fn test_load_params_none_when_missing() {
        let conn = Connection::open_in_memory().unwrap();
        schema::create_tables(&conn).unwrap();
        let result = load_params(&conn).unwrap();
        assert!(result.is_none());
    }
}

pub fn save_game_state(conn: &Connection, state: &crate::state::GameState) -> Result<()> {
    let json = serde_json::to_string(state).unwrap_or_default();
    conn.execute("INSERT OR REPLACE INTO game_state (id, data) VALUES (1, ?1)", [&json])?;

    if let Some(league) = &state.league {
        for t in &league.teams {
            let tactic_json = serde_json::to_string(&t.tactic).unwrap_or_default();
            conn.execute("INSERT OR REPLACE INTO teams (id, name, city, abbreviation, tactic_json, chemistry, wins, losses)
                          VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![t.id as i64, t.name, t.city, t.abbreviation, tactic_json, t.chemistry as f64, t.wins as i64, t.losses as i64])?;

            for p in &t.players {
                let attrs_json = serde_json::to_string(&p.attributes).unwrap_or_default();
                let stats_s_json = serde_json::to_string(&p.stats_season).unwrap_or_default();
                let stats_c_json = serde_json::to_string(&p.stats_career).unwrap_or_default();
                let pos_str = match p.position {
                    crate::engine::types::Position::PG => "PG",
                    crate::engine::types::Position::SG => "SG",
                    crate::engine::types::Position::SF => "SF",
                    crate::engine::types::Position::PF => "PF",
                    crate::engine::types::Position::C => "C",
                };
                conn.execute("INSERT OR REPLACE INTO players (id, team_id, first_name, last_name, position, age, attributes_json, morale, injury_days, contract_year, salary, stats_season_json, stats_career_json)
                              VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)",
                    params![p.id as i64, t.id as i64, p.first_name, p.last_name, pos_str, p.age as i64, attrs_json, p.morale as f64, p.injury_days as i64, p.contract_year as i64, p.salary as i64, stats_s_json, stats_c_json])?;
            }
        }

        for g in &league.schedule {
            let played_int = if g.played { 1 } else { 0 };
            let h_score: Option<i64> = g.home_score.map(|s| s as i64);
            let a_score: Option<i64> = g.away_score.map(|s| s as i64);
            conn.execute("INSERT OR REPLACE INTO games (id, home_team_id, away_team_id, week, played, home_score, away_score)
                          VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                params![g.id as i64, g.home_team as i64, g.away_team as i64, g.week as i64, played_int, h_score, a_score])?;
        }

        for evt in &league.events {
            let completed_int = if evt.is_completed { 1 } else { 0 };
            let playoff_int = if evt.is_playoff.unwrap_or(false) { 1 } else { 0 };
            let home_id: Option<i64> = evt.home_team_id.map(|v| v as i64);
            let away_id: Option<i64> = evt.away_team_id.map(|v| v as i64);
            let g_id: Option<i64> = evt.game_id.map(|v| v as i64);
            conn.execute(
                "INSERT OR REPLACE INTO events (id, season, event_type, year, month, day, hour, minute, competition, description, is_completed, home_team_id, away_team_id, game_id, is_playoff, phase_label, cup_stage)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17)",
                params![
                    evt.id as i64, evt.season as i64, evt.event_type, evt.year as i64, evt.month as i64, evt.day as i64, evt.hour as i64, evt.minute as i64,
                    evt.competition, evt.description, completed_int,
                    home_id, away_id, g_id, playoff_int,
                    evt.phase_label, evt.cup_stage
                ],
            )?;
        }
    }

    if let Some(coach) = &state.coach {
        conn.execute("INSERT OR REPLACE INTO coach_profiles (id, team_id, name, focus, reputation) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![coach.id as i64, coach.team_id as i64, coach.name, coach.focus, coach.reputation as i64])?;
    }

    for s in &state.staff {
        conn.execute("INSERT OR REPLACE INTO staff (id, team_id, name, role, skill_level) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![s.id as i64, s.team_id as i64, s.name, s.role, s.skill_level as i64])?;
    }

    for msg in &state.inbox {
        let read_int = if msg.read { 1 } else { 0 };
        let act_int = if msg.action_required { 1 } else { 0 };
        conn.execute("INSERT OR REPLACE INTO inbox_messages (id, coach_id, sender_name, sender_role, subject, body, read, date_received, action_required)
                      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![msg.id as i64, msg.coach_id as i64, msg.sender_name, msg.sender_role, msg.subject, msg.body, read_int, msg.date_received, act_int])?;
    }

    // Also persist GameParams to the settings table
    save_params(conn, &state.params)?;

    // Persist transactions for all teams
    if let Some(ref league) = state.league {
        for team in &league.teams {
            for txn in &team.transactions {
                conn.execute(
                    "INSERT OR REPLACE INTO transactions (id, team_id, amount, category, description, week, season)
                     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                    params![txn.id as i64, txn.team_id as i64, txn.amount, txn.category, txn.description, txn.week as i64, txn.season as i64],
                )?;
            }
            for sponsor in &team.sponsors {
                conn.execute(
                    "INSERT OR REPLACE INTO sponsors (id, team_id, name, amount_per_year, years_remaining, total_years, category)
                     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                    params![sponsor.id as i64, sponsor.team_id as i64, sponsor.name, sponsor.amount_per_year, sponsor.years_remaining as i64, sponsor.total_years as i64, sponsor.category],
                )?;
            }
        }
    }

    Ok(())
}

pub fn load_game_state(conn: &Connection) -> Result<Option<crate::state::GameState>> {
    let mut stmt = conn.prepare("SELECT data FROM game_state WHERE id = 1")?;
    let mut rows = stmt.query([])?;
    if let Some(row) = rows.next()? {
        let json: String = row.get(0)?;
        let mut state: crate::state::GameState = serde_json::from_str(&json).unwrap_or_default();

        // Load GameParams from settings table (overrides JSON-stored params)
        if let Ok(Some(params)) = load_params(conn) {
            state.params = params;
        }
        
        Ok(Some(state))
    } else {
        Ok(None)
    }
}
