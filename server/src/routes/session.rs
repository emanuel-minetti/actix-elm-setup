use crate::validate_session::Session;
use actix_web::web::{Data, ReqData};
use actix_web::HttpResponse;
use serde::Serialize;
use sqlx::{query, PgPool};

#[derive(Serialize)]
struct SessionResponse {
    name: Option<String>,
    expires_at: Option<i64>,
}

pub async fn session(
    db_pool: Data<PgPool>,
    session: Option<ReqData<Option<Session>>>,
) -> HttpResponse {
    let res: SessionResponse;

    let logged_in = session.as_ref().is_some() && session.as_ref().unwrap().is_some();

    if logged_in {
        let account_row = query!(
            // language=postgresql
            r#"
           SELECT name FROM account WHERE id = $1
       "#,
            session.clone().unwrap().into_inner().unwrap().account_id
        )
        .fetch_one(&**db_pool)
        .await
        .unwrap();
        let expires_at = Some(
            session
                .unwrap()
                .as_ref()
                .unwrap()
                .expires_at
                .and_utc()
                .timestamp(),
        );
        res = SessionResponse {
            name: Some(account_row.name),
            expires_at,
        }
    } else {
        res = SessionResponse {
            name: None,
            expires_at: None,
        }
    }

    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())
}
