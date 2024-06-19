mod routes;

use actix_web::{web, HttpServer};
use actix_files::Files;


#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        actix_web::App::new()
            .service(
                web::scope("")
                    .service(Files::new("/js", "../public/js"))
                    .service(Files::new("/css", "../public/css"))
                    .service(Files::new("/img", "../public/img"))
                    .service(Files::new("/lang", "../public/lang"))
                    .route("/favicon.ico", web::get().to(routes::return_favicon))
                    .route("/", web::get().to(routes::return_index))
                    .route("/{route}", web::get().to(routes::return_index))
            )})
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
}

