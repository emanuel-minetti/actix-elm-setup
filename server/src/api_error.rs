use crate::authorisation::{ApiResponse, HandlerResponse};
use crate::routes::ExpiresAt;
use actix_web::body::BoxBody;
use actix_web::http::StatusCode;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, ResponseError};
use anyhow::Error;
use std::fmt::{Display, Formatter};

pub fn return_early(error: ApiError) -> HttpResponse {
    error.req.extensions_mut().insert(error.clone());
    if error.req.path().split("/").last().unwrap() == "login" {
        error.req.extensions_mut().insert::<ExpiresAt>(0);
    }
    HttpResponse::Ok().json(HandlerResponse::None())
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum ApiErrorType {
    BadRequest,
    DbError,
    NotFoundError,
    Unauthorized,
    Unexpected(&'static str),
    Expired,
}

impl Into<&str> for ApiErrorType {
    fn into(self) -> &'static str {
        match self {
            ApiErrorType::BadRequest => "Bad Request",
            ApiErrorType::DbError => "DB Error",
            ApiErrorType::NotFoundError => "Not found requested API endpoint",
            ApiErrorType::Unauthorized => "Unauthorized",
            ApiErrorType::Expired => "Expired",
            ApiErrorType::Unexpected(message) => {
                let msg = message.to_owned();
                    let new_msg = format!("Unexpected Error: {}", msg);
                    let text = new_msg.leak();
                    text
            }
        }
    }
}

impl Into<String> for ApiErrorType {
    fn into(self) -> String {
        let string_slice: &str = self.into();
        string_slice.to_string()
    }
}

impl From<sqlx::Error> for ApiErrorType {
    fn from(_: sqlx::Error) -> Self {
        ApiErrorType::DbError
    }
}

impl From<Error> for ApiErrorType {
    fn from(error: Error) -> Self {
        ApiErrorType::Unexpected(error.to_string().leak())
    }
}

impl Display for ApiErrorType {
    fn fmt(&self, _f: &mut Formatter<'_>) -> std::fmt::Result {
        Ok(println!("{:?}", self))
    }
}

#[derive(Debug, Clone)]
pub struct ApiError {
    pub req: HttpRequest,
    pub error: ApiErrorType,
}

impl ApiError {
    pub fn get_into(req: &HttpRequest) -> impl Fn(ApiErrorType) -> ApiError + '_ {
        move |error| -> ApiError { (|req| ApiError { req, error })(req.clone()) }
    }
}

impl Display for ApiError {
    fn fmt(&self, _f: &mut Formatter<'_>) -> std::fmt::Result {
        Ok(println!("{:?}", self))
    }
}

// needed for middleware
impl ResponseError for ApiError {
    fn status_code(&self) -> StatusCode {
        StatusCode::OK
    }

    fn error_response(&self) -> HttpResponse<BoxBody> {
        let body = ApiResponse {
            expires_at: 0,
            error: self.to_string(),
            data: HandlerResponse::None(),
        };
        HttpResponse::build(self.status_code()).json(body)
    }
}

// needed for initial json validation (see login_json_config)
impl ResponseError for ApiErrorType {
    fn status_code(&self) -> StatusCode {
        StatusCode::OK
    }

    fn error_response(&self) -> HttpResponse<BoxBody> {
        let body = HandlerResponse::None();
        HttpResponse::build(self.status_code()).json(body)
    }
}
