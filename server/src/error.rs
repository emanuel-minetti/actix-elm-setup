#[derive(Clone, Copy, Debug)]
pub enum ApiError {
    DbError,
    NotFoundError,
    Unauthorized,
    Expired,
}

impl Into<&str> for ApiError {
    fn into(self) -> &'static str {
        match self {
            ApiError::DbError => "DB Error",
            ApiError::NotFoundError => "Not DFound",
            ApiError::Unauthorized => "Unauthorized",
            ApiError::Expired => "Expired",
        }
    }
}

impl Into<String> for ApiError {
    fn into(self) -> String {
        match self {
            ApiError::DbError => "DB Error".to_string(),
            ApiError::NotFoundError => "Not DFound".to_string(),
            ApiError::Unauthorized => "Unauthorized".to_string(),
            ApiError::Expired => "Expired".to_string(),
        }
    }
}
