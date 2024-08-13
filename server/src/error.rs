use anyhow::Error;
use base64::DecodeError;
use std::fmt::{Display, Formatter};
use actix_web::http::StatusCode;
use actix_web::{HttpResponse, ResponseError};
use actix_web::body::BoxBody;
use crate::authorisation::{ApiResponse, HandlerResponse};

#[derive(Clone, Copy, Debug)]
pub enum ApiError {
    DbError,
    NotFoundError,
    Unauthorized,
    Unexpected(&'static str),
    Expired,
}

impl Into<&str> for ApiError {
    fn into(self) -> &'static str {
        match self {
            ApiError::DbError => "DB Error",
            ApiError::NotFoundError => "Not DFound",
            ApiError::Unauthorized => "Unauthorized",
            ApiError::Expired => "Expired",
            ApiError::Unexpected(message) => {
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

impl Into<String> for ApiError {
    fn into(self) -> String {
        let string_slice: &str = self.into();
        string_slice.to_string()
    }
}

impl From<DecodeError> for ApiError {
    fn from(_: DecodeError) -> Self {
        ApiError::Unauthorized
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(_: sqlx::Error) -> Self {
        ApiError::DbError
    }
}

impl From<Error> for ApiError {
    fn from(error: Error) -> Self {
        ApiError::Unexpected(error.to_string().leak())
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
