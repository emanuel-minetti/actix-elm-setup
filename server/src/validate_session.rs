use actix_web::body::EitherBody;
use actix_web::dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform};
use actix_web::http::{header, StatusCode};
use actix_web::{web, Error, HttpMessage, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use futures_util::future::LocalBoxFuture;
use regex::Regex;
use sqlx::types::chrono::{NaiveDateTime, Utc};
use sqlx::{query, PgPool};
use std::future::{ready, Ready};
use std::rc::Rc;
use uuid::Uuid;

pub struct ValidateSession;

#[derive(Clone)]
pub struct ServerSession {
    pub account_id: Uuid,
    pub expires_at: NaiveDateTime,
}

impl<S, B> Transform<S, ServiceRequest> for ValidateSession
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, &'static str>>;
    type Error = Error;
    type Transform = ValidateSessionMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(ValidateSessionMiddleware {
            service: service.into(),
        }))
    }
}

pub struct ValidateSessionMiddleware<S> {
    // wrap with Rc to get static lifetime
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for ValidateSessionMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, &'static str>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // to use it in the closure
        let srv = self.service.clone();

        fn return_early<B>(
            req: ServiceRequest,
            status_code: StatusCode,
            body: &str,
        ) -> Result<ServiceResponse<EitherBody<B, &str>>, Error> {
            let res = HttpResponse::with_body(status_code, body);
            Ok(req.into_response(res.map_into_right_body()))
        }

        Box::pin(async move {
            let session_secret = req.app_data::<web::Data<Bytes>>().unwrap();
            let db_pool = req.app_data::<web::Data<PgPool>>().unwrap();

            let authorisation_header = req.headers().get(header::AUTHORIZATION);
            if authorisation_header.is_none() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let authorisation_header_value = authorisation_header.unwrap().to_str();
            if authorisation_header_value.is_err() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let match_token = Regex::new(r"Bearer (.+)").unwrap();
            let session_token_capture = match_token.captures(authorisation_header_value.unwrap());
            if session_token_capture.is_none() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let session_token_match = session_token_capture.unwrap().get(1);
            if session_token_match.is_none() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let session_token = session_token_match.unwrap().as_str().to_string();
            let session_token_decode_result = general_purpose::URL_SAFE.decode(&session_token);
            if session_token_decode_result.is_err() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let session_token_bytes = session_token_decode_result.unwrap();
            let session_id_bytes_result =
                simple_crypt::decrypt(session_token_bytes.as_ref(), &session_secret);
            if session_id_bytes_result.is_err() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let session_id = Uuid::from_slice(session_id_bytes_result.unwrap().as_ref()).unwrap();

            let session_row_result_option = query!(
                // language=postgresql
                r#"
                    SELECT * FROM session WHERE id = $1
                "#,
                session_id
            )
            .fetch_optional(&***db_pool)
            .await;
            //TODO handle db error and authentication error differently
            if session_row_result_option.is_err() {
                return return_early(req, StatusCode::INTERNAL_SERVER_ERROR, "No DB connection");
            } else if session_row_result_option.as_ref().unwrap().is_none() {
                return return_early(req, StatusCode::UNAUTHORIZED, "");
            }
            let session_row = session_row_result_option.unwrap().unwrap();
            let expired = session_row.expires_at < Utc::now().naive_utc();
            if expired {
                return return_early(req, StatusCode::UNAUTHORIZED, "Session expired.");
            } else {
                let new_session_row = query!(
                    // language=postgresql
                    r#"
                        UPDATE session SET expires_at = DEFAULT
                            WHERE id = $1 RETURNING account_id, expires_at
                    "#,
                    session_id
                )
                .fetch_one(&***db_pool)
                .await;
                if new_session_row.is_err() {
                    return return_early(
                        req,
                        StatusCode::INTERNAL_SERVER_ERROR,
                        "No DB connection",
                    );
                }

                req.extensions_mut().insert(Some(ServerSession {
                    account_id: new_session_row.as_ref().unwrap().account_id,
                    expires_at: new_session_row.unwrap().expires_at,
                }));
            }

            //deleting outdated
            query!(
                // language=postgresql
                r#"
                        DELETE FROM session WHERE expires_at < CURRENT_TIMESTAMP
                    "#
            )
            .execute(&***db_pool)
            .await
            //expecting because no other client or server actions are affected
            .expect("Failed to delete outdated sessions from database.");

            let res = srv.call(req).await?;

            Ok(res.map_into_left_body())
        })
    }
}
