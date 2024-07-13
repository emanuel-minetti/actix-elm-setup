use actix_web::{HttpResponse, web};
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

pub async fn login(req: web::Json<LoginRequest>) -> HttpResponse {
    let res = LoginResponse  {
        name: req.account.to_string(),
        token: "token".to_string()
    };

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}