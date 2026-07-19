use rusqlite::{Connection, Result};

pub fn create_tables(conn: &Connection) -> Result<()> {
    conn.execute_batch("
        CREATE TABLE IF NOT EXISTS game_state (
            id INTEGER PRIMARY KEY,
            data TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS teams (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            city TEXT NOT NULL,
            abbreviation TEXT NOT NULL,
            tactic_json TEXT,
            chemistry REAL DEFAULT 50.0,
            wins INTEGER DEFAULT 0,
            losses INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY,
            team_id INTEGER,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            position TEXT NOT NULL,
            age INTEGER,
            attributes_json TEXT,
            morale REAL DEFAULT 75.0,
            injury_days INTEGER DEFAULT 0,
            contract_year INTEGER DEFAULT 4,
            salary INTEGER DEFAULT 1000000,
            stats_season_json TEXT,
            stats_career_json TEXT,
            portrait_json TEXT,
            FOREIGN KEY (team_id) REFERENCES teams(id)
        );
        CREATE TABLE IF NOT EXISTS league (
            id INTEGER PRIMARY KEY,
            season INTEGER NOT NULL,
            current_week INTEGER DEFAULT 1,
            playoffs_active INTEGER DEFAULT 0,
            schedule_json TEXT
        );
        CREATE TABLE IF NOT EXISTS games (
            id INTEGER PRIMARY KEY,
            home_team_id INTEGER,
            away_team_id INTEGER,
            week INTEGER,
            played INTEGER DEFAULT 0,
            home_score INTEGER,
            away_score INTEGER,
            FOREIGN KEY (home_team_id) REFERENCES teams(id),
            FOREIGN KEY (away_team_id) REFERENCES teams(id)
        );
        CREATE TABLE IF NOT EXISTS coach_profiles (
            id INTEGER PRIMARY KEY,
            team_id INTEGER,
            name TEXT NOT NULL,
            focus TEXT NOT NULL,
            reputation INTEGER DEFAULT 50,
            FOREIGN KEY (team_id) REFERENCES teams(id)
        );
        CREATE TABLE IF NOT EXISTS staff (
            id INTEGER PRIMARY KEY,
            team_id INTEGER,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            skill_level INTEGER DEFAULT 50,
            FOREIGN KEY (team_id) REFERENCES teams(id)
        );
        CREATE TABLE IF NOT EXISTS inbox_messages (
            id INTEGER PRIMARY KEY,
            coach_id INTEGER,
            sender_name TEXT NOT NULL,
            sender_role TEXT NOT NULL,
            subject TEXT NOT NULL,
            body TEXT NOT NULL,
            read INTEGER DEFAULT 0,
            date_received TEXT NOT NULL,
            action_required INTEGER DEFAULT 0,
            FOREIGN KEY (coach_id) REFERENCES coach_profiles(id)
        );
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY,
            season INTEGER NOT NULL,
            event_type TEXT NOT NULL,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            day INTEGER NOT NULL,
            hour INTEGER NOT NULL,
            minute INTEGER DEFAULT 0,
            competition TEXT,
            description TEXT,
            is_completed INTEGER DEFAULT 0,
            home_team_id INTEGER,
            away_team_id INTEGER,
            game_id INTEGER,
            is_playoff INTEGER DEFAULT 0,
            phase_label TEXT,
            cup_stage TEXT,
            FOREIGN KEY (home_team_id) REFERENCES teams(id),
            FOREIGN KEY (away_team_id) REFERENCES teams(id),
            FOREIGN KEY (game_id) REFERENCES games(id)
        );
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY,
            team_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            week INTEGER NOT NULL,
            season INTEGER NOT NULL,
            FOREIGN KEY (team_id) REFERENCES teams(id)
        );
        CREATE TABLE IF NOT EXISTS sponsors (
            id INTEGER PRIMARY KEY,
            team_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            amount_per_year REAL NOT NULL,
            years_remaining INTEGER NOT NULL,
            total_years INTEGER NOT NULL,
            category TEXT NOT NULL,
            FOREIGN KEY (team_id) REFERENCES teams(id)
        );
    ")?;
    Ok(())
}
