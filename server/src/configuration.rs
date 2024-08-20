use std::str::FromStr;
use serde::{Deserialize, Deserializer};
use serde::de::Error;

#[derive(Deserialize)]
pub struct Settings {
    pub database: DatabaseSettings,
    pub log: Box<LogSettings>,
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
    #[serde(deserialize_with = "string_to_level")]
    pub max_level: log::Level,
    pub path: String
}

fn string_to_level<'de, D>(deserializer: D) -> Result<log::Level, D::Error>
where
    D: Deserializer<'de>
{
    let string:String = Deserialize::deserialize(deserializer)?;
    match log::Level::from_str(string.as_str()) {
        Ok(l) => Ok(l),
        Err(e) => Err(Error::custom(e.to_string()))
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
