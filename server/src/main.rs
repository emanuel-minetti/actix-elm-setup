mod api_error;
mod authorisation;
mod configuration;
mod logging;
mod routes;
mod validation;

use crate::api_error::{ApiError, ApiErrorType};
use crate::authorisation::Authorisation;
use crate::configuration::get_configuration;
use crate::logging::Logger;
use crate::routes::ExpiresAt;
use actix_files::Files;
use actix_web::web::Data;
use actix_web::{web, HttpMessage, HttpServer};
use sqlx::{Pool, Postgres};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let configuration = get_configuration().expect("Couldn't read configuration file.");

    Logger::init(configuration.log).expect("Couldn't initialize logger");
    let session_secret = bytes::Bytes::from(configuration.session_secret);

    let db_url = configuration.database.connection_string();
    let db_pool = Pool::<Postgres>::connect(db_url.as_str())
        .await
        .expect("Couldn't connect to database.");

    let json_parse_config = web::JsonConfig::default()
        .limit(512)
        .content_type(|mime| mime == "application/json")
        .content_type_required(true)
        .error_handler(|_, req| {
            let api_error = ApiError::get_into(req)(ApiErrorType::BadRequest);
            req.extensions_mut().insert(api_error.clone());
            req.extensions_mut().insert::<ExpiresAt>(0);
            api_error.error.into()
        });

    HttpServer::new(move || {
        actix_web::App::new()
            .app_data(Data::new(db_pool.clone()))
            .service(
                web::scope("")
                    .service(Files::new("/js", "../public/js"))
                    .service(Files::new("/css", "../public/css"))
                    .service(Files::new("/img", "../public/img"))
                    .service(Files::new("/lang", "../public/lang"))
                    .service(
                        web::scope("/api")
                            .app_data(Data::new(session_secret.clone()))
                            .app_data(json_parse_config.clone())
                            .wrap(Authorisation)
                            .route("/login", web::post().to(routes::login_handler))
                            .route("/session", web::get().to(routes::session_handler))
                            .route("/{route}", web::get().to(routes::not_found_handler)),
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
