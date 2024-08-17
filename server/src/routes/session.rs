use actix_web::web::Data;
use actix_web::{HttpRequest, HttpResponse};
use serde::{Deserialize, Serialize};
use sqlx::{query, PgPool};

use crate::authorisation::{HandlerResponse, SessionId};
use crate::error::{return_early, ApiError};

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
    session_id: SessionId,
    request: HttpRequest,
) -> HttpResponse {
    let into_api_error = ApiError::get_into(&request);
    let account_row = match query!(
        // language=postgresql
        r#"
           SELECT
               name,
               preferred_language AS "prefered_lang: Lang"
           FROM account WHERE id = $1
       "#,
        *session_id
    )
    .fetch_one(&**db_pool)
    .await
    {
        Ok(row) => row,
        Err(error) => {
            return return_early(into_api_error(error.into()));
        }
    };

    let res = HandlerResponse::Session(SessionResponse {
        name: account_row.name,
        preferred_lang: account_row.prefered_lang,
    });

    HttpResponse::Ok().json(res)
}
