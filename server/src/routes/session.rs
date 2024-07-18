use actix_web::web::Data;
use actix_web::{HttpRequest, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use serde::Serialize;
use sqlx::types::chrono::Utc;
use sqlx::{query, PgPool};
use uuid::Uuid;

#[derive(Serialize)]
struct SessionResponse {
    name: String,
    expires_at: Option<i64>,
}

pub async fn session(
    req: HttpRequest,
    db_pool: Data<PgPool>,
    session_secret: Data<Bytes>,
) -> HttpResponse {
    let session_token = req.cookie("session_token").unwrap().value().to_string();
    let session_token_bytes = general_purpose::URL_SAFE.decode(&session_token).unwrap();
    let session_id = simple_crypt::decrypt(session_token_bytes.as_ref(), &session_secret).unwrap();
    let session_row = query!(
        r#"
        SELECT * FROM session WHERE id = $1
    "#,
        Uuid::from_slice(session_id.as_ref()).unwrap()
    )
    .fetch_optional(&**db_pool)
    .await
    .unwrap();

    let logged_in =
        session_row.is_some() && session_row.as_ref().unwrap().expires_at >= Utc::now().naive_utc();
    let res: SessionResponse;

    if logged_in {
        let account_row = query!(
            r#"
           SELECT name FROM account WHERE id = $1
       "#,
            session_row.as_ref().unwrap().account_id
        )
        .fetch_one(&**db_pool)
        .await
        .unwrap();
        //TODO update expires_at
        res = SessionResponse {
            name: account_row.name,
            expires_at: Some(
                session_row
                    .as_ref()
                    .unwrap()
                    .expires_at
                    .and_utc()
                    .timestamp(),
            ),
        }
    } else {
        res = SessionResponse {
            name: "".to_string(),
            expires_at: None,
        }
    }

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}
