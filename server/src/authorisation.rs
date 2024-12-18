use actix_web::body::{EitherBody, MessageBody};
use actix_web::dev::{forward_ready, Payload, Service, ServiceRequest, ServiceResponse, Transform};
use actix_web::http::{header, StatusCode};
use actix_web::{web, Error, FromRequest, HttpMessage, HttpRequest, HttpResponse};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use futures_util::future::LocalBoxFuture;
use log::{log, Level};
use regex::Regex;
use serde::{Deserialize, Serialize};
use sqlx::types::chrono::Utc;
use sqlx::{query, PgPool};
use std::future::{ready, Ready};
use std::rc::Rc;
use uuid::Uuid;

use crate::api_error::{ApiError, ApiErrorType};
use crate::routes::{ExpiresAt, LoginResponse, SessionResponse};

pub struct Authorisation;

impl<S, B> Transform<S, ServiceRequest> for Authorisation
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static + MessageBody + std::fmt::Debug,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Transform = AuthorisationMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthorisationMiddleware {
            service: service.into(),
        }))
    }
}

pub struct AuthorisationMiddleware<S> {
    // wrap with Rc to get static lifetime for async function calls in `call`
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for AuthorisationMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static + MessageBody + std::fmt::Debug,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // to use it in the closure for async function calls
        let srv = self.service.clone();

        // grab url path from request to care for 'login'
        let url_path = req.path().split("/").last().unwrap().to_owned();

        async fn authorize(req: &ServiceRequest) -> Result<ExpiresAt, ApiErrorType> {
            let session_secret = req.app_data::<web::Data<Bytes>>().unwrap();
            let db_pool = req.app_data::<web::Data<PgPool>>().unwrap();

            let authorisation_header = match req.headers().get(header::AUTHORIZATION) {
                Some(header) => header,
                None => {
                        log!(
                            Level::Warn,
                            "Error: Authorization header missing, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                        return Err(ApiErrorType::Unauthorized);
                }
            };
            let authorisation_header_value = match authorisation_header.to_str() {
                Ok(value) => value,
                Err(_) => {
                        log!(
                            Level::Warn,
                            "Error: Authorization header is no UTF8-String, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                        return Err(ApiErrorType::Unauthorized);
                }
            };
            let match_token = Regex::new(r"Bearer (.+)").unwrap();
            let session_token_capture = match match_token.captures(authorisation_header_value) {
                Some(capture) => capture,
                None => {
                        log!(
                            Level::Warn,
                            "Error: Authorization header has no `Bearer` token, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                        return Err(ApiErrorType::Unauthorized);
                }
            };
            let session_token = match session_token_capture.get(1) {
                Some(capture) =>  capture.as_str().to_string(),
                None => {
                        log!(
                            Level::Warn,
                            "Error: Found no `Bearer` token, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                        return Err(ApiErrorType::Unauthorized);
                }
            };
            let session_token_bytes = match general_purpose::URL_SAFE.decode(&session_token) {
                Ok(bytes) => bytes,
                Err(_) => {
                    log!(
                            Level::Warn,
                            "Error: Failed to base64 decode session token, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                    return Err(ApiErrorType::Unauthorized);
                }
            };
            let session_id = match simple_crypt::decrypt(session_token_bytes.as_ref(), &session_secret) {
                Ok(bytes) => match Uuid::from_slice(bytes.as_ref()) {
                    Ok(uuid) => uuid,
                    Err(_) => {
                        log!(
                            Level::Error,
                            "Error: Failed to find Uuid in session id, data: {:?}",
                            session_token_bytes
                        );
                        return Err(ApiErrorType::Unauthorized);
                    }
                },
                Err(_) => {
                    log!(
                            Level::Warn,
                            "Error: Failed to decrypt session token, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                    return Err(ApiErrorType::Unauthorized);
                }
            };
            let session_row = match query!(
                // language=postgresql
                r#"
                    SELECT * FROM session WHERE id = $1
                "#,
                session_id
            )
            .fetch_optional(&***db_pool)
            .await {
                Ok(Some(row)) => row,
                Ok(None) => {
                    log!(
                            Level::Warn,
                            "Error: Failed to find session, IP: {:?}",
                            req.peer_addr().unwrap().ip()
                        );
                    return Err(ApiErrorType::Unauthorized);
                }
                Err(error) => {
                    log!(
                    Level::Error,
                    "Error: {}, while finding session, Data: {:?}",
                    error,
                    session_id
                );
                    return Err(ApiErrorType::DbError);
                }
            };
            let expired = session_row.expires_at < Utc::now().naive_utc();
            if expired {
                Err(ApiErrorType::Expired)
            } else {
                let updated_session_row = match query!(
                    // language=postgresql
                    r#"
                        UPDATE session SET expires_at = DEFAULT
                            WHERE id = $1 RETURNING account_id, expires_at
                    "#,
                    session_id
                )
                .fetch_one(&***db_pool)
                .await {
                    Ok(row) => row,
                    Err(error) => {
                        log!(
                    Level::Error,
                    "Error: {}, while updating session, Data: {:?}",
                    error,
                    session_id
                );
                        return Err(ApiErrorType::DbError);
                    }
                };

                req.extensions_mut()
                    .insert(DBId(updated_session_row.account_id));

                Ok(updated_session_row.expires_at.and_utc().timestamp() as ExpiresAt)
            }
        }

        Box::pin(async move {
            let mut expires_at;
            if url_path != "login" {
                let auth_result = authorize(&req).await;
                if auth_result.is_err() {
                    let new_body = ApiResponse {
                        expires_at: 0,
                        error: auth_result.err().unwrap().into(),
                        data: HandlerResponse::None(),
                    };
                    let new_resp = HttpResponse::Ok().json(new_body);
                    let new_res = ServiceResponse::new(req.request().clone(), new_resp);
                    return Ok(new_res.map_into_right_body());
                } else {
                    expires_at = auth_result.unwrap()
                }
            } else {
                expires_at = 0;
            }

            //deleting outdated
            let db_pool = req.app_data::<web::Data<PgPool>>().unwrap();
            match query!(
                // language=postgresql
                r#"
                        DELETE FROM session WHERE expires_at < CURRENT_TIMESTAMP + INTERVAL '20 minutes';
                "#
                )
                .execute(&***db_pool)
                .await {
                Ok(_) => (),
                Err(error) => {
                    log!(
                    Level::Error,
                    "Error: {}, while deleting sessions",
                    error,
                );
                    let new_body = ApiResponse {
                        expires_at: 0,
                        error: ApiErrorType::DbError.into(),
                        data: HandlerResponse::None(),
                    };
                    let new_resp = HttpResponse::Ok().json(new_body);
                    let new_res = ServiceResponse::new(req.request().clone(), new_resp);
                    return Ok(new_res.map_into_right_body());
                }
            }

            //call other middleware and handler and get the response
            let res = srv.call(req).await?;
            let request = res.request().clone();

            //wrap json responses into standard response body
            if res.status() == StatusCode::OK
                && res.headers().get(header::CONTENT_TYPE).is_some()
                && res.headers().get(header::CONTENT_TYPE).unwrap() == "application/json"
            {
                if url_path == "login" {
                    let req = request.clone();
                    expires_at = *req.extensions().get::<ExpiresAt>().unwrap();
                }
                let error = match request.extensions().get::<ApiError>() {
                    Some(&ref error) => error.error.into(),
                    None => "",
                }
                .to_string();
                let res_body = res.into_body();
                let res_body_bytes = res_body.try_into_bytes().unwrap();
                let res_body_string = String::from_utf8(res_body_bytes.to_vec()).unwrap();
                let res_body_obj: HandlerResponse = res_body_string.as_str().into();
                let mod_body_obj = ApiResponse {
                    error,
                    expires_at,
                    data: res_body_obj,
                };

                let resp = HttpResponse::build(StatusCode::OK).json(mod_body_obj);
                let new_res = ServiceResponse::new(request, resp);
                Ok(new_res.map_into_right_body())
            } else {
                Ok(res.map_into_left_body())
            }
        })
    }
}

#[derive(Clone, Debug)]
pub struct DBId(Uuid);

impl FromRequest for DBId {
    type Error = ApiError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        let session_id_option: Option<DBId> = req.extensions().get().cloned();
        let result = match session_id_option {
            None => Err(ApiError {
                req: req.clone(),
                error: ApiErrorType::Unauthorized,
            }),
            Some(session_id) => Ok(session_id),
        };
        ready(result)
    }
}

impl std::ops::Deref for DBId {
    type Target = Uuid;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[derive(Deserialize, Serialize, Debug)]
pub enum HandlerResponse {
    Session(SessionResponse),
    Login(LoginResponse),
    None(),
}

impl From<&str> for HandlerResponse {
    fn from(value: &str) -> Self {
        match serde_json::from_str::<HandlerResponse>(value) {
            Ok(HandlerResponse::Session(val)) => HandlerResponse::Session(val),
            Ok(HandlerResponse::Login(val)) => HandlerResponse::Login(val),
            Ok(HandlerResponse::None()) => HandlerResponse::None(),
            Err(_) => HandlerResponse::None(),
        }
    }
}

#[derive(Serialize)]
pub struct ApiResponse {
    pub expires_at: i64,
    pub error: String,
    pub data: HandlerResponse,
}
