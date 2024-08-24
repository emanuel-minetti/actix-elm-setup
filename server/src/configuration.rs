use serde::de::Error;
use serde::{Deserialize, Deserializer};
use std::str::FromStr;

#[derive(Deserialize)]
pub struct Settings {
    pub database: DatabaseSettings,
    pub log: LogSettings,
    pub application_port: u16,
    pub session_secret: Vec<u8>,
}

#[derive(Deserialize)]
pub struct DatabaseSettings {
    pub username: String,
    pub password: String,
    pub host: String,
    pub port: u16,
    pub database_name: String,
}

impl DatabaseSettings {
    pub fn connection_string(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.username, self.password, self.host, self.port, self.database_name
        )
    }
}

#[derive(Deserialize)]
pub struct LogSettings {
    #[serde(deserialize_with = "string_to_level_filter")]
    pub max_level: log::Level,
    #[serde(rename = "path")]
    pub path_string: String,
    pub days_to_keep: u64,
}

fn string_to_level_filter<'de, D>(deserializer: D) -> Result<log::Level, D::Error>
where
    D: Deserializer<'de>,
{
    let string: String = Deserialize::deserialize(deserializer)?;
    match log::Level::from_str(string.as_str()) {
        Ok(l) => Ok(l),
        Err(e) => Err(Error::custom(e.to_string())),
    }
}

pub fn get_configuration() -> Result<Settings, config::ConfigError> {
    println!(
        "{:?}",
        std::env::current_dir().expect("Couldn't get present working directory.")
    );
    let settings = config::Config::builder()
        .add_source(config::File::new(
            "config/configuration.json",
            config::FileFormat::Json,
        ))
        .build()?;
    settings.try_deserialize::<Settings>()
}
