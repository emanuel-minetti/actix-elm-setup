use actix_web::{HttpResponse, web};
use deadpool_postgres::{Client, Pool};
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
struct LoginResponse {
    name: String,
    token: String
}

#[derive(Deserialize)]
pub struct LoginRequest {
    account: String,
    pw: String
}

pub async fn login(req: web::Json<LoginRequest>, db_pool: web::Data<Pool>) -> HttpResponse {
    let client: Client = db_pool.get().await.unwrap();
    let stmt = client.prepare(
        r#"
            SELECT pw_hash
            FROM "user"
            WHERE account_name = $1
        "#
    ).await.unwrap();

    let rows = client.query(&stmt, &[&"emu"]).await.unwrap();

    let res = LoginResponse  {
        name: req.account.to_string(),
        token: rows[0].get(0)
    };

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}