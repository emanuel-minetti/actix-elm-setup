use crate::domain::LoginData;
use actix_web::web::Data;
use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use simple_crypt;
use sqlx::{query, PgPool};
use uuid::Uuid;

use crate::authorisation::ApiResponse;
use crate::error::ApiError;

pub type ExpiresAt = i64;
#[derive(Serialize, Deserialize, Debug)]
pub struct LoginResponse {
    session_token: String,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub account: String,
    pub pw: String,
}

pub async fn login_handler(
    request: HttpRequest,
    req: web::Json<LoginRequest>,
    db_pool: Data<PgPool>,
    session_secret: Data<Bytes>,
) -> HttpResponse {

    fn return_early(
        request: &HttpRequest,
        error: ApiError) -> HttpResponse {
        request.extensions_mut().insert(error);
        request.extensions_mut().insert::<ExpiresAt>(0);
        return HttpResponse::Ok().json(ApiResponse::None());
    }

    let login_data = match LoginData::parse(req) {
        Ok(data) => data,
        Err(_) => {
            return return_early(&request, ApiError::Unauthorized);
        }
    };

    let account_id = match authenticate(login_data, &*db_pool.as_ref()).await {
        Ok(id) => match id {
            None => return return_early(&request, ApiError::Unauthorized),
            Some(id) => id,
        },
        Err(_) => {
            return return_early(&request, ApiError::DbError)
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
    request
        .extensions_mut()
        .insert::<ExpiresAt>(session_row.expires_at.and_utc().timestamp());

    let res = ApiResponse::Login(LoginResponse { session_token });
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
