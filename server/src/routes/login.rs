use crate::validation::LoginData;
use actix_web::web::Data;
use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bcrypt::verify;
use bytes::Bytes;
use log::{log, Level};
use serde::{Deserialize, Serialize};
use simple_crypt;
use sqlx::{query, PgPool};
use uuid::Uuid;

use crate::api_error::{return_early, ApiError, ApiErrorType};
use crate::authorisation::HandlerResponse;

pub type ExpiresAt = i64;
#[derive(Serialize, Deserialize, Debug)]
pub struct LoginResponse {
    session_token: String,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub account: Option<String>,
    pub pw: Option<String>,
}

pub async fn login_handler(
    request: HttpRequest,
    req_json_body: web::Json<LoginRequest>,
    db_pool: Data<PgPool>,
    session_secret: Data<Bytes>,
) -> HttpResponse {
    let into_api_error = ApiError::get_into(&request);

    let login_data = match LoginData::parse(req_json_body) {
        Ok(data) => data,
        Err(error) => {
            log!(
                Level::Warn,
                "Error: {:?}, IP: {:?}",
                &error,
                request.peer_addr().unwrap().ip()
            );
            return return_early(into_api_error(ApiErrorType::Unauthorized));
        }
    };

    let account_id = match authenticate(&login_data, &*db_pool.as_ref()).await {
        Ok(Some(id)) => id,
        Ok(None) => {
            log!(
                Level::Warn,
                "Error: Invalid Credentials, Account name: {:?}, IP: {:?}",
                login_data.account_name,
                request.peer_addr().unwrap().ip()
            );
            return return_early(into_api_error(ApiErrorType::Unauthorized.into()));
        }
        Err(error) => {
            if error == ApiErrorType::DbError {
                log!(
                    Level::Error,
                    "Error: {}, while authenticating credentials, Data: {:?}",
                    error,
                    login_data
                )
            }
            log!(
                Level::Warn,
                "Error: Invalid Credentials, Account name: {:?}",
                login_data.account_name
            );
            return return_early(into_api_error(error.into()));
        }
    };

    let session_row = match query!(
        // language=postgresql
        r#"
            INSERT INTO session (account_id) VALUES ($1) RETURNING id, expires_at
        "#,
        account_id
    )
    .fetch_one(&**db_pool)
    .await
    {
        Ok(row) => row,
        Err(error) => {
            log!(
                Level::Error,
                "Error: {}, while inserting session row, Data: {:?}",
                error,
                account_id
            );
            return return_early(into_api_error(error.into()));
        }
    };
    let session_token_bytes = match simple_crypt::encrypt(session_row.id.as_ref(), &session_secret)
    {
        Ok(bytes) => bytes,
        Err(error) => {
            log!(
                Level::Error,
                "Error: {}, while encrypting session uuid, Data: {}",
                error,
                session_row.id
            );
            return return_early(into_api_error(ApiErrorType::Unauthorized));
        }
    };
    let session_token = general_purpose::URL_SAFE.encode(session_token_bytes);
    request
        .extensions_mut()
        .insert::<ExpiresAt>(session_row.expires_at.and_utc().timestamp());

    let res = HandlerResponse::Login(LoginResponse { session_token });
    log!(Level::Info, "Logged in: {:?}", login_data.account_name.as_ref());
    HttpResponse::Ok().json(res)
}

async fn authenticate(cred: &LoginData, db_pool: &PgPool) -> Result<Option<Uuid>, ApiErrorType> {
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
        match verify(
            cred.password.clone(),
            account_row.as_ref().unwrap().pw_hash.as_str(),
        ) {
            Ok(true) => Ok(Some(account_row.unwrap().account_id)),
            _ => Err(ApiErrorType::Unauthorized),
        }
    }
}
