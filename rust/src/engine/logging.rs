use std::fs::{File, OpenOptions};
use std::io::Write;
use std::path::Path;
use serde_json::{json, Value};

pub struct SimLogger {
    log_file: File,
    calibration_entries: Vec<Value>,
    calibration_path: String,
}

impl SimLogger {
    pub fn new(log_path: &str, calibration_path: &str) -> Self {
        let log_file = OpenOptions::new()
            .create(true).write(true).truncate(true)
            .open(Path::new(log_path))
            .expect("Failed to open sim log file");
        Self { log_file, calibration_entries: Vec::new(), calibration_path: calibration_path.to_string() }
    }

    pub fn log(&mut self, tick: u64, component: &str, message: &str, data: Value) {
        let entry = json!({ "tick": tick, "component": component, "message": message, "data": data });
        writeln!(self.log_file, "{}", serde_json::to_string(&entry).unwrap()).ok();
        self.calibration_entries.push(entry);
    }

    pub fn write_calibration_baseline(&self, metadata: Value) {
        let cal = json!({ "type": "calibration_baseline", "metadata": metadata, "entries": self.calibration_entries });
        let mut f = File::create(Path::new(&self.calibration_path)).expect("Failed to create calibration file");
        write!(f, "{}", serde_json::to_string_pretty(&cal).unwrap()).ok();
    }
}
