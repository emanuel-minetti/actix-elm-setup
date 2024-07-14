mod routes;

use actix_web::{web, HttpServer};
use actix_files::Files;
use actix_web::web::Data;
use deadpool_postgres::{Config as PoolConfig, ManagerConfig, RecyclingMethod, Runtime};
use deadpool_postgres::tokio_postgres::NoTls;

#[actix_web::main]
async fn main() -> std::io::Result<()> {

    std::env::set_var("RUST_LOG", "debug");
    env_logger::init();

    let mut db_conn_cfg = PoolConfig::new();
    db_conn_cfg.host = Some("localhost".to_string());
    db_conn_cfg.port = Some(5432);
    db_conn_cfg.dbname = Some("aes".to_string());
    db_conn_cfg.user = Some("aes".to_string());
    db_conn_cfg.password = Some("aes".to_string());
    db_conn_cfg.connect_timeout = Some(std::time::Duration::from_secs(2));
    db_conn_cfg.manager = Some(ManagerConfig {
        recycling_method: RecyclingMethod::Fast
    });

    let db_pool = db_conn_cfg.create_pool(Some(Runtime::Tokio1), NoTls).unwrap();

    HttpServer::new(move || {
        actix_web::App::new()
            .app_data(Data::new(db_pool.clone()))
            .service(
                web::scope("")
                    .service(Files::new("/js", "../public/js"))
                    .service(Files::new("/css", "../public/css"))
                    .service(Files::new("/img", "../public/img"))
                    .service(Files::new("/lang", "../public/lang"))
                    .service(web::scope("/api")
                         .route("/login", web::post().to(routes::login)))
                    .route("/favicon.ico", web::get().to(routes::return_favicon))
                    .route("/", web::get().to(routes::return_index))
                    .route("/{route}", web::get().to(routes::return_index))
            )})
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
}

