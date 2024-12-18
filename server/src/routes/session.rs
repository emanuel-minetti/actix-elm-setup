use actix_web::web::{Data, Json};
use actix_web::{web, HttpRequest, HttpResponse};
use log::{log, Level};
use serde::{Deserialize, Serialize};
use sqlx::{query, PgPool};
use crate::api_error::{return_early, ApiError, ApiErrorType};
use crate::authorisation::{HandlerResponse, SessionId};

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

#[derive(Deserialize)]
pub struct SessionRequest {
    preferred_lang: String,
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
               preferred_language AS "preferred_lang: Lang"
           FROM account WHERE id = $1
       "#,
        *session_id
    )
    .fetch_one(&**db_pool)
    .await
    {
        Ok(row) => row,
        Err(error) => {
            log!(
                Level::Error,
                "Error: {}, while retrieving account, Data: {:?}",
                error,
                session_id
            );
            return return_early(into_api_error(error.into()));
        }
    };

    let res = HandlerResponse::Session(SessionResponse {
        name: account_row.name,
        preferred_lang: account_row.preferred_lang,
    });

    HttpResponse::Ok().json(res)
}

pub async fn set_user_language_handler(
    db_pool: Data<PgPool>,
    req_json_body: Json<SessionRequest>,
    session_id: SessionId,
    request: HttpRequest,
) -> HttpResponse {
    let into_api_error = ApiError::get_into(&request);
    let preferred_lang_data  = match NewLangData::parse(req_json_body) {
        Ok(data) => data,
        Err(_) => {
            return return_early(into_api_error(ApiErrorType::BadRequest));
        }
    };
    let update_result = match query!(
        r#"
        UPDATE account SET
            preferred_language = $1::lang
        WHERE id = $2
        RETURNING
            name,
            preferred_language AS "preferred_lang: Lang"
        "#,
        preferred_lang_data.into_inner() as Lang,
        *session_id,)
            .fetch_one(&**db_pool).await {
        Ok(row) => row,
        Err(_error) => {
            return return_early(into_api_error(ApiErrorType::DbError));
        }

    };
    let res = HandlerResponse::Session(SessionResponse {
        name: update_result.name,
        preferred_lang: update_result.preferred_lang,
    });

    HttpResponse::Ok().json(res)
}

#[derive(Debug)]
struct NewLangData(Lang);

impl NewLangData {
    pub fn into_inner(self) -> Lang {
        self.0
    }
}

#[derive(Debug)]
pub struct NewLangDataError(String);

impl NewLangData {
    pub fn parse(req: Json<SessionRequest>) -> Result<NewLangData, NewLangDataError> {
        let lang = &req.preferred_lang;
        if lang.to_lowercase().eq("de") {
            Ok(Self(Lang::De))
        } else if lang.to_lowercase().eq("en") {
            Ok(Self(Lang::En))
        } else {
            Err(NewLangDataError("Unknown or missing option".to_string()))
        }

    }
}
