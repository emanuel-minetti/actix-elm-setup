use crate::configuration::LogSettings;
use log::{Level, LevelFilter, Metadata, Record, SetLoggerError};
use sqlx::types::chrono::Utc;
use std::fs::File;
use std::io::Write;

pub struct Logger {
    level: Level,
    file: File,
}

impl log::Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= self.level
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let mut file = &mut self.file.try_clone().unwrap();
            let now = Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
            println!("{} [{}]: {}", now, record.level(), record.args());
            writeln!(
                file,
                "{} [{}]: {}",
                now,
                record.level(),
                record.args()
            )
            .expect("Could not write to log file");
            file.flush().unwrap();
        }
    }

    fn flush(&self) {}
}

impl Logger {
    fn new(settings: LogSettings) -> Box<Self> {
        let today = Utc::now().format("%Y-%m-%d");
        let file_name = format!("log-{}.txt", today);
        let file_path = settings.path_string + &*file_name;
        let mut file = File::options()
            .append(true)
            .create(true)
            .open(file_path)
            .expect("Unable to open log file");
        // TODO delete outdated
        Box::new(Logger {
            level: settings.max_level,
            file,
        })
    }
    pub fn init(config: LogSettings) -> Result<(), SetLoggerError> {
        log::set_boxed_logger(Self::new(config)).map(|()| log::set_max_level(LevelFilter::Debug))
    }
}
