use crate::authorisation::{ApiResponse, HandlerResponse};
use crate::domain::LoginDataError;
use crate::routes::ExpiresAt;
use actix_web::body::BoxBody;
use actix_web::http::StatusCode;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, ResponseError};
use anyhow::Error;
use base64::DecodeError;
use std::fmt::{Display, Formatter};

pub fn return_early(error: ApiError) -> HttpResponse {
    error.req.extensions_mut().insert(error.clone());
    if error.req.path().split("/").last().unwrap() == "login" {
        error.req.extensions_mut().insert::<ExpiresAt>(0);
    }
    HttpResponse::Ok().json(HandlerResponse::None())
}

#[derive(Clone, Copy, Debug)]
pub enum ApiErrorType {
    DbError,
    NotFoundError,
    Unauthorized,
    Unexpected(&'static str),
    Expired,
}

impl Into<&str> for ApiErrorType {
    fn into(self) -> &'static str {
        match self {
            ApiErrorType::DbError => "DB Error",
            ApiErrorType::NotFoundError => "Not DFound",
            ApiErrorType::Unauthorized => "Unauthorized",
            ApiErrorType::Expired => "Expired",
            ApiErrorType::Unexpected(message) => {
                let msg = message.to_owned();
                if msg.starts_with("Failed to encrypt data") {
                    "Unauthorized"
                } else {
                    let new_msg = format!("Unexpected Error: {}", msg);
                    let text = new_msg.leak();
                    text
                }
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

// all following is needed for middleware
impl From<DecodeError> for ApiErrorType {
    fn from(_: DecodeError) -> Self {
        ApiErrorType::Unauthorized
    }
}

impl From<sqlx::Error> for ApiErrorType {
    fn from(_: sqlx::Error) -> Self {
        ApiErrorType::DbError
    }
}

impl From<LoginDataError> for ApiErrorType {
    fn from(_: LoginDataError) -> Self {
        ApiErrorType::Unauthorized
    }
}

impl From<Error> for ApiErrorType {
    fn from(error: Error) -> Self {
        ApiErrorType::Unexpected(error.to_string().leak())
    }
}

#[derive(Debug, Clone)]
pub struct ApiError {
    pub req: HttpRequest,
    pub error: ApiErrorType,
}

impl Display for ApiError {
    fn fmt(&self, _f: &mut Formatter<'_>) -> std::fmt::Result {
        Ok(println!("{:?}", self))
    }
}

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
