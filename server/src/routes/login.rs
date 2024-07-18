use actix_web::web::Data;
use actix_web::{web, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use simple_crypt;
use sqlx::{query, PgPool};

#[derive(Serialize)]
struct LoginResponse {
    session_token: String,
    expires_at: Option<i64>,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    account: String,
    pw: String,
}

pub async fn login(
    req: web::Json<LoginRequest>,
    db_pool: Data<PgPool>,
    session_secret: Data<Bytes>,
) -> HttpResponse {
    let account_row = query!(
        r#"
            SELECT
                id as account_id,
                pw_hash,
                name
            FROM account
            WHERE account_name = $1
        "#,
        req.account
    )
    .fetch_optional(&**db_pool)
    .await
    .unwrap();

    let authenticated = account_row.is_some()
        && bcrypt::verify(&req.pw, account_row.as_ref().unwrap().pw_hash.as_str()).unwrap();
    let res: LoginResponse;

    if authenticated {
        let session_row = query!(
            r#"
            INSERT INTO session (account_id) VALUES ($1) RETURNING id, expires_at
        "#,
            account_row.unwrap().account_id
        )
        .fetch_one(&**db_pool)
        .await
        .unwrap();
        let session_token_bytes =
            simple_crypt::encrypt(session_row.id.as_ref(), &session_secret).unwrap();
        let session_token = general_purpose::URL_SAFE.encode(session_token_bytes);

        res = LoginResponse {
            session_token,
            expires_at: Some(session_row.expires_at.and_utc().timestamp()),
        };
    } else {
        res = LoginResponse {
            session_token: "".to_string(),
            expires_at: None,
        };
    }

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}
