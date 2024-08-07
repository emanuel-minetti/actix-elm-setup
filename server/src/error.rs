#[derive(Clone, Copy)]
pub enum ApiError {
    DbError,
    NotFoundError,
    Unauthorized,
}

impl Into<&str> for ApiError {
    fn into(self) -> &'static str {
        match self {
            ApiError::DbError => "DB Error",
            ApiError::NotFoundError => "Not DFound",
            ApiError::Unauthorized => "Unauthorized",
        }
    }
}
