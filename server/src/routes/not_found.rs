use crate::error::{return_early, ApiError, ApiErrorType};
use actix_web::{HttpRequest, HttpResponse};

pub async fn not_found_handler(request: HttpRequest) -> HttpResponse {
    return_early(ApiError::get_into(&request)(ApiErrorType::NotFoundError))
}
