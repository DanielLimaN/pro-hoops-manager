#[derive(Debug, Clone)]
pub struct GameClock {
    pub total_seconds: u16,
    pub quarter: u8,
    pub shot_clock: u8,
    pub is_running: bool,
}

impl GameClock {
    pub fn new() -> Self {
        Self {
            total_seconds: 12 * 60,
            quarter: 1,
            shot_clock: 24,
            is_running: true,
        }
    }

    pub fn tick(&mut self, seconds: u16) -> TickResult {
        if !self.is_running {
            return TickResult::Continue;
        }
        if seconds >= self.total_seconds {
            self.total_seconds = 0;
            self.shot_clock = 0;
            return TickResult::QuarterEnd;
        }
        self.total_seconds -= seconds;
        if self.shot_clock > seconds as u8 {
            self.shot_clock -= seconds as u8;
        } else {
            self.shot_clock = 0;
            return TickResult::ShotClockViolation;
        }
        if self.total_seconds == 0 {
            TickResult::QuarterEnd
        } else {
            TickResult::Continue
        }
    }

    pub fn advance_quarter(&mut self) -> bool {
        if self.quarter >= 4 {
            false
        } else {
            self.quarter += 1;
            self.total_seconds = 12 * 60;
            self.shot_clock = 24;
            true
        }
    }

    pub fn overtime(&mut self) {
        self.quarter = self.quarter.saturating_add(1);
        self.total_seconds = 5 * 60;
        self.shot_clock = 24;
    }

    pub fn reset_shot_clock(&mut self) { self.shot_clock = 24; }
    pub fn reset_shot_clock_offensive(&mut self) { self.shot_clock = 14; }
    pub fn stop(&mut self) { self.is_running = false; }
    pub fn start(&mut self) { self.is_running = true; }

    pub fn format_clock(&self) -> String {
        let mins = self.total_seconds / 60;
        let secs = self.total_seconds % 60;
        format!("{}:{:02}", mins, secs)
    }

    pub fn format_shot_clock(&self) -> u8 { self.shot_clock }
}

#[derive(Debug, Clone, PartialEq)]
pub enum TickResult {
    Continue,
    QuarterEnd,
    GameEnd,
    ShotClockViolation,
}
