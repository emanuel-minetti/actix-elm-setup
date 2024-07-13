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

    let name= req.account.to_string();
    let res = LoginResponse  {
        name ,
        token: "token".to_string()
    };

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}