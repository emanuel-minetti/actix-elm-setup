mod configuration;
mod routes;
mod validate_session;

use crate::configuration::get_configuration;
use crate::validate_session::ValidateSession;
use actix_files::Files;
use actix_web::web::Data;
use actix_web::{web, HttpServer};
use sqlx::{Pool, Postgres};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "debug");
    env_logger::init();

    let configuration = get_configuration().expect("Couldn't read configuration file.");
    let session_secret = bytes::Bytes::from(configuration.session_secret);
    let db_url = configuration.database.connection_string();
    let db_pool = Pool::<Postgres>::connect(db_url.as_str())
        .await
        .expect("Couldn't connect to database.");

    HttpServer::new(move || {
        actix_web::App::new()
            .app_data(Data::new(db_pool.clone()))
            .app_data(Data::new(session_secret.clone()))
            .service(
                web::scope("")
                    .service(Files::new("/js", "../public/js"))
                    .service(Files::new("/css", "../public/css"))
                    .service(Files::new("/img", "../public/img"))
                    .service(Files::new("/lang", "../public/lang"))
                    .route("/api/login", web::post().to(routes::login_handler))
                    .service(
                        web::scope("/api")
                            .wrap(ValidateSession)
                            .route("/session", web::get().to(routes::session_handler)),
                    )
                    .route("/favicon.ico", web::get().to(routes::return_favicon))
                    .route("/", web::get().to(routes::return_index))
                    .route("/{route}", web::get().to(routes::return_index)),
            )
    })
    .bind(("127.0.0.1", configuration.application_port))?
    .run()
    .await
}
