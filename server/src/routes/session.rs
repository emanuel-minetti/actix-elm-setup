use actix_web::web::{Data, ReqData};
use actix_web::HttpResponse;
use serde::{Deserialize, Serialize};
use sqlx::{query, PgPool};

use crate::authorisation::{ApiResponse, ServerSession};

#[derive(sqlx::Type, Serialize, Debug, Deserialize)]
#[sqlx(type_name = "lang", rename_all = "lowercase")]
enum Lang {
    De,
    En,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SessionResponse {
    name: String,
    preferred_lang: Lang,
}

pub async fn session_handler(
    db_pool: Data<PgPool>,
    session: Option<ReqData<ServerSession>>,
) -> HttpResponse {
    let session = session.unwrap().into_inner();

    let account_row = query!(
        // language=postgresql
        r#"
           SELECT
               name,
               preferred_language AS "prefered_lang: Lang"
           FROM account WHERE id = $1
       "#,
        session
    )
    .fetch_one(&**db_pool)
    .await
    .unwrap();

    let res = ApiResponse::Session(SessionResponse {
        name: account_row.name,
        preferred_lang: account_row.prefered_lang,
    });

    HttpResponse::Ok().json(res)
}
