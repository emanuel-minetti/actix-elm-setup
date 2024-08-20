use serde::Deserialize;

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
    pub max_level: String,
    pub path: String
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
