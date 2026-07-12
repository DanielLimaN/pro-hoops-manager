use serde::{Deserialize, Serialize};

/// All tunable game parameters.
/// Loaded from the `settings` table in SQLite on game start.
/// Falls back to `Default::default()` if not found in DB.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameParams {
    // ── Financeiro ──
    pub ticket_base_price: f64,
    pub ticket_price_per_chem: f64,
    pub attendance_base: u32,
    pub attendance_variance: u32,
    pub weekly_staff_cost: f64,
    pub travel_cost_per_game: f64,
    pub infra_monthly: f64,
    pub marketing_monthly: f64,
    pub medical_monthly: f64,
    pub salary_cap: f64,
    pub tv_rights_monthly: f64,
    pub merchandising_base_monthly: f64,
    pub prize_pool_winner: f64,
    pub prize_pool_runner_up: f64,

    // ── Treino (boost semanal por intensidade) ──
    pub training_boost_low: f32,
    pub training_boost_med: f32,
    pub training_boost_high: f32,
    pub training_shooting_three: f32,
    pub training_shooting_mid: f32,
    pub training_defense_perim: f32,
    pub training_defense_interior: f32,
    pub training_physical_stamina: f32,
    pub training_physical_speed: f32,
    pub training_playmaking_pass: f32,
    pub training_playmaking_handle: f32,
    pub training_balanced_all: f32,

    // ── Moral ──
    pub morale_win_bonus: f32,
    pub morale_loss_penalty: f32,
    pub morale_max: f32,
    pub morale_min: f32,
    pub morale_natural_target: f32,
    pub morale_decay_per_week: f32,

    // ── Stamina ──
    pub stamina_base_recovery: f32,
    pub stamina_game_fatigue: f32,
    pub stamina_training_fatigue: f32,
    pub stamina_max: f32,
    pub stamina_min: f32,

    // ── Lesão ──
    pub injury_stamina_threshold: f32,
    pub injury_probability: f64,
    pub injury_min_days: u8,
    pub injury_max_days: u8,

    // ── Partida ──
    pub tick_interval_seconds: f64,
    pub quarter_length_minutes: u8,
    pub shot_clock_seconds: u8,

    // ── Patrocinadores ──
    pub sponsor_min_count: u8,
    pub sponsor_max_count: u8,
    pub sponsor_years_min: u8,
    pub sponsor_years_max: u8,
}

impl Default for GameParams {
    fn default() -> Self {
        Self {
            // ── Financeiro ──
            ticket_base_price: 80.0,
            ticket_price_per_chem: 0.5,
            attendance_base: 8000,
            attendance_variance: 5000,
            weekly_staff_cost: 200_000.0,
            travel_cost_per_game: 150_000.0,
            infra_monthly: 200_000.0,
            marketing_monthly: 133_333.0,
            medical_monthly: 33_333.0,
            salary_cap: 150_000_000.0,
            tv_rights_monthly: 500_000.0,
            merchandising_base_monthly: 533_333.0,
            prize_pool_winner: 5_000_000.0,
            prize_pool_runner_up: 2_500_000.0,

            // ── Treino ──
            training_boost_low: 1.0,
            training_boost_med: 2.0,
            training_boost_high: 3.0,
            training_shooting_three: 0.5,
            training_shooting_mid: 0.3,
            training_defense_perim: 0.5,
            training_defense_interior: 0.4,
            training_physical_stamina: 0.4,
            training_physical_speed: 0.3,
            training_playmaking_pass: 0.5,
            training_playmaking_handle: 0.4,
            training_balanced_all: 0.2,

            // ── Moral ──
            morale_win_bonus: 5.0,
            morale_loss_penalty: 5.0,
            morale_max: 100.0,
            morale_min: 0.0,
            morale_natural_target: 50.0,
            morale_decay_per_week: 1.0,

            // ── Stamina ──
            stamina_base_recovery: 5.0,
            stamina_game_fatigue: 15.0,
            stamina_training_fatigue: 3.0,
            stamina_max: 100.0,
            stamina_min: 0.0,

            // ── Lesão ──
            injury_stamina_threshold: 15.0,
            injury_probability: 0.3,
            injury_min_days: 3,
            injury_max_days: 21,

            // ── Partida ──
            tick_interval_seconds: 0.4,
            quarter_length_minutes: 12,
            shot_clock_seconds: 24,

            // ── Patrocinadores ──
            sponsor_min_count: 2,
            sponsor_max_count: 4,
            sponsor_years_min: 1,
            sponsor_years_max: 5,
        }
    }
}

impl GameParams {
    /// Returns the boost value for a given intensity label.
    pub fn training_boost_for(&self, intensity: &str) -> f32 {
        match intensity {
            "BAIXA" | "LOW" => self.training_boost_low,
            "ALTA" | "HIGH" => self.training_boost_high,
            _ => self.training_boost_med,
        }
    }

    /// Converts all fields to a flat key-value dictionary for GDScript.
    pub fn to_dict(&self) -> std::collections::HashMap<String, serde_json::Value> {
        let mut map = std::collections::HashMap::new();
        macro_rules! insert {
            ($field:ident) => {
                map.insert(
                    stringify!($field).to_string(),
                    serde_json::json!(self.$field),
                );
            };
        }
        insert!(ticket_base_price);
        insert!(ticket_price_per_chem);
        insert!(attendance_base);
        insert!(attendance_variance);
        insert!(weekly_staff_cost);
        insert!(travel_cost_per_game);
        insert!(infra_monthly);
        insert!(marketing_monthly);
        insert!(medical_monthly);
        insert!(salary_cap);
        insert!(tv_rights_monthly);
        insert!(merchandising_base_monthly);
        insert!(prize_pool_winner);
        insert!(prize_pool_runner_up);
        insert!(training_boost_low);
        insert!(training_boost_med);
        insert!(training_boost_high);
        insert!(training_shooting_three);
        insert!(training_shooting_mid);
        insert!(training_defense_perim);
        insert!(training_defense_interior);
        insert!(training_physical_stamina);
        insert!(training_physical_speed);
        insert!(training_playmaking_pass);
        insert!(training_playmaking_handle);
        insert!(training_balanced_all);
        insert!(morale_win_bonus);
        insert!(morale_loss_penalty);
        insert!(morale_max);
        insert!(morale_min);
        insert!(morale_natural_target);
        insert!(morale_decay_per_week);
        insert!(stamina_base_recovery);
        insert!(stamina_game_fatigue);
        insert!(stamina_training_fatigue);
        insert!(stamina_max);
        insert!(stamina_min);
        insert!(injury_stamina_threshold);
        insert!(injury_probability);
        insert!(injury_min_days);
        insert!(injury_max_days);
        insert!(tick_interval_seconds);
        insert!(quarter_length_minutes);
        insert!(shot_clock_seconds);
        insert!(sponsor_min_count);
        insert!(sponsor_max_count);
        insert!(sponsor_years_min);
        insert!(sponsor_years_max);
        map
    }

    /// Updates a single field from a string key and JSON value.
    /// Returns true if the key was found and updated.
    pub fn set_from_json(&mut self, key: &str, value: serde_json::Value) -> bool {
        macro_rules! update {
            ($field:ident, $type:ty) => {
                if key == stringify!($field) {
                    if let Some(v) = value.as_f64() {
                        self.$field = v as $type;
                        return true;
                    }
                    if let Some(v) = value.as_i64() {
                        self.$field = v as $type;
                        return true;
                    }
                    if let Some(v) = value.as_u64() {
                        self.$field = v as $type;
                        return true;
                    }
                    return false;
                }
            };
        }
        update!(ticket_base_price, f64);
        update!(ticket_price_per_chem, f64);
        update!(attendance_base, u32);
        update!(attendance_variance, u32);
        update!(weekly_staff_cost, f64);
        update!(travel_cost_per_game, f64);
        update!(infra_monthly, f64);
        update!(marketing_monthly, f64);
        update!(medical_monthly, f64);
        update!(salary_cap, f64);
        update!(tv_rights_monthly, f64);
        update!(merchandising_base_monthly, f64);
        update!(prize_pool_winner, f64);
        update!(prize_pool_runner_up, f64);
        update!(training_boost_low, f32);
        update!(training_boost_med, f32);
        update!(training_boost_high, f32);
        update!(training_shooting_three, f32);
        update!(training_shooting_mid, f32);
        update!(training_defense_perim, f32);
        update!(training_defense_interior, f32);
        update!(training_physical_stamina, f32);
        update!(training_physical_speed, f32);
        update!(training_playmaking_pass, f32);
        update!(training_playmaking_handle, f32);
        update!(training_balanced_all, f32);
        update!(morale_win_bonus, f32);
        update!(morale_loss_penalty, f32);
        update!(morale_max, f32);
        update!(morale_min, f32);
        update!(morale_natural_target, f32);
        update!(morale_decay_per_week, f32);
        update!(stamina_base_recovery, f32);
        update!(stamina_game_fatigue, f32);
        update!(stamina_training_fatigue, f32);
        update!(stamina_max, f32);
        update!(stamina_min, f32);
        update!(injury_stamina_threshold, f32);
        update!(injury_probability, f64);
        update!(injury_min_days, u8);
        update!(injury_max_days, u8);
        update!(tick_interval_seconds, f64);
        update!(quarter_length_minutes, u8);
        update!(shot_clock_seconds, u8);
        update!(sponsor_min_count, u8);
        update!(sponsor_max_count, u8);
        update!(sponsor_years_min, u8);
        update!(sponsor_years_max, u8);
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_params() {
        let p = GameParams::default();
        assert_eq!(p.salary_cap, 150_000_000.0);
        assert_eq!(p.quarter_length_minutes, 12);
        assert_eq!(p.training_boost_med, 2.0);
    }

    #[test]
    fn test_set_from_json() {
        let mut p = GameParams::default();
        assert!(p.set_from_json("salary_cap", serde_json::json!(200_000_000.0)));
        assert_eq!(p.salary_cap, 200_000_000.0);

        assert!(p.set_from_json("training_boost_high", serde_json::json!(5.0)));
        assert_eq!(p.training_boost_high, 5.0);

        // Unknown key returns false
        assert!(!p.set_from_json("nonexistent", serde_json::json!(42)));
    }

    #[test]
    fn test_to_dict_roundtrip() {
        let p = GameParams::default();
        let dict = p.to_dict();
        assert!(dict.contains_key("salary_cap"));
        assert!(dict.contains_key("training_boost_med"));
        assert_eq!(dict.len(), 48); // all fields

        let mut restored = GameParams::default();
        for (k, v) in &dict {
            assert!(restored.set_from_json(k, v.clone()), "Failed to set {}", k);
        }
        assert_eq!(restored.salary_cap, p.salary_cap);
    }

    #[test]
    fn test_training_boost_for() {
        let p = GameParams::default();
        assert_eq!(p.training_boost_for("BAIXA"), p.training_boost_low);
        assert_eq!(p.training_boost_for("LOW"), p.training_boost_low);
        assert_eq!(p.training_boost_for("MÉDIA"), p.training_boost_med);
        assert_eq!(p.training_boost_for("MED"), p.training_boost_med);
        assert_eq!(p.training_boost_for("ALTA"), p.training_boost_high);
        assert_eq!(p.training_boost_for("HIGH"), p.training_boost_high);
    }
}
