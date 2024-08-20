use log::{Level, LevelFilter, Metadata, Record, SetLoggerError};
use sqlx::types::chrono::Utc;

pub struct Logger;

impl log::Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Debug
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let now = Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
            println!("{} [{}]: {}", now, record.level(), record.args())
        }
    }

    fn flush(&self) {}
}

impl Logger {
    pub fn init() -> Result<(), SetLoggerError> {
        log::set_boxed_logger(Box::new(Logger)).map(|()| log::set_max_level(LevelFilter::Debug))
    }
}