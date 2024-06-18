mod routes;

use actix_web::{web, HttpServer, Responder};
use actix_files::Files;


#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        actix_web::App::new()
            .service(
                web::scope("")
                    .service(Files::new("/assets", "../public/assets"))
                    .service(Files::new("/css", "../public/css"))
                    .route("/favicon.ico", web::get().to(routes::return_favicon))
                    .route("/elm.js", web::get().to(routes::return_elm))
                    .route("/{route}", web::get().to(routes::return_index))
            )})
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
}

