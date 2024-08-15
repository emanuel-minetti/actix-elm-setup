use crate::authorisation::{ApiResponse, HandlerResponse};
use crate::routes::ExpiresAt;
use actix_web::body::BoxBody;
use actix_web::http::StatusCode;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, ResponseError};
use anyhow::Error;
use base64::DecodeError;
use std::fmt::{Display, Formatter};

pub fn return_early(error: ApiError) -> HttpResponse {
    let request = error.req.clone();
    error.req.extensions_mut().insert(error.clone());
    if request.path().split("/").last().unwrap() == "login" {
        request.extensions_mut().insert::<ExpiresAt>(0);
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

#[derive(Debug, Clone)]
pub struct ApiError {
    pub req: HttpRequest,
    pub error: ApiErrorType,
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
// impl From<DecodeError> for ApiError {
//     fn from(_: DecodeError) -> Self {
//         ApiError::Unauthorized
//     }
// }
//
impl From<sqlx::Error> for ApiErrorType {
    fn from(_: sqlx::Error) -> Self {
        ApiErrorType::DbError
    }
}
//
// impl From<Error> for ApiError {
//     fn from(error: Error) -> Self {
//         ApiError::Unexpected(error.to_string().leak())
//     }
// }

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
