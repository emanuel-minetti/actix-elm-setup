use crate::configuration::LogSettings;
use actix_web::dev::Path;
use log::{Level, LevelFilter, Metadata, Record, SetLoggerError};
use sqlx::types::chrono::Utc;

pub struct Logger {
    level: Level,
    path: Path<String>,
}

impl log::Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= self.level
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
    fn new(settings: LogSettings) -> Box<Self> {
        Box::new(Logger {
            level: settings.max_level,
            path: Path::new(settings.path_string),
        })
    }
    pub fn init(config: LogSettings) -> Result<(), SetLoggerError> {
        log::set_boxed_logger(Self::new(config)).map(|()| log::set_max_level(LevelFilter::Debug))
    }
}
