use crate::domain::LoginData;
use actix_web::body::BoxBody;
use actix_web::http::StatusCode;
use actix_web::web::Data;
use actix_web::{web, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use simple_crypt;
use sqlx::{query, PgPool};
use uuid::Uuid;

#[derive(Serialize)]
struct LoginResponse {
    session_token: Option<String>,
    expires_at: Option<i64>,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub account: String,
    pub pw: String,
}

pub async fn login_handler(
    req: web::Json<LoginRequest>,
    db_pool: Data<PgPool>,
    session_secret: Data<Bytes>,
) -> HttpResponse {
    let login_data = match LoginData::parse(req) {
        Ok(data) => data,
        Err(_) => return HttpResponse::BadRequest().finish(),
    };

    let account_id = match authenticate(login_data, &*db_pool.as_ref()).await {
        Ok(id) => match id {
            None => return HttpResponse::Unauthorized().finish(),
            Some(id) => id,
        },
        Err(_) => {
            return HttpResponse::with_body(
                StatusCode::INTERNAL_SERVER_ERROR,
                BoxBody::new("DB Error"),
            )
        }
    };

    let session_row = query!(
        // language=postgresql
        r#"
            INSERT INTO session (account_id) VALUES ($1) RETURNING id, expires_at
        "#,
        account_id
    )
    .fetch_one(&**db_pool)
    .await
    .expect("Failed to get session from table.");
    let session_token_bytes = simple_crypt::encrypt(session_row.id.as_ref(), &session_secret)
        .expect("Failed to encrypt session token.");
    let session_token = general_purpose::URL_SAFE.encode(session_token_bytes);

    let res = LoginResponse {
        session_token: Some(session_token),
        expires_at: Some(session_row.expires_at.and_utc().timestamp()),
    };

    HttpResponse::Ok().json(res)
}

async fn authenticate(cred: LoginData, db_pool: &PgPool) -> Result<Option<Uuid>, sqlx::Error> {
    let account_row = query!(
        // language=postgresql
        r#"
            SELECT
                id as account_id,
                pw_hash,
                name
            FROM account
            WHERE account_name = $1
        "#,
        cred.account_name.as_ref()
    )
    .fetch_optional(db_pool)
    .await?;

    if account_row.is_none() {
        Ok(None)
    } else {
        Ok(Some(account_row.unwrap().account_id))
    }
}
