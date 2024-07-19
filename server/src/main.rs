mod routes;

use actix_files::Files;
use actix_web::web::Data;
use actix_web::{web, HttpServer};
use bytes::Bytes;
use sqlx::{Pool, Postgres};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "debug");
    env_logger::init();

    let db_host = "localhost";
    let db_port = 5432;
    let db_name = "aes";
    let db_user = "aes";
    let db_password = "aes";

    let session_secret = Bytes::from_static(
        [
            229, 84, 94, 175, 10, 21, 99, 226, 105, 37, 151, 121, 241, 201, 164, 176,
        ]
        .as_ref(),
    );

    let db_url = format!(
        "postgres://{}:{}@{}:{}/{}",
        db_user, db_password, db_host, db_port, db_name
    );

    let db_pool = Pool::<Postgres>::connect(db_url.as_str()).await.unwrap();

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
                    .route("/api/login", web::post().to(routes::login))
                    .service(
                        web::scope("/api")
                            // TODO introduce middleware
                            //.wrap(ValidateSession)
                            .route("/session", web::get().to(routes::session)),
                    )
                    .route("/favicon.ico", web::get().to(routes::return_favicon))
                    .route("/", web::get().to(routes::return_index))
                    .route("/{route}", web::get().to(routes::return_index)),
            )
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
