use actix_web::dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform};
use actix_web::{web, Error};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use futures_util::future::LocalBoxFuture;
use sqlx::{query, PgPool};
use std::future::{ready, Ready};
use std::rc::Rc;
use uuid::Uuid;

pub struct ValidateSession;

impl<S, B> Transform<S, ServiceRequest> for ValidateSession
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
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
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // to use it in the closure
        let srv = self.service.clone();

        Box::pin(async move {
            let session_secret = req.app_data::<web::Data<Bytes>>().unwrap();
            let db_pool = req.app_data::<web::Data<PgPool>>().unwrap();

            let session_token = req.cookie("session_token").unwrap().value().to_string();
            let session_token_bytes = general_purpose::URL_SAFE.decode(&session_token).unwrap();
            let session_id =
                simple_crypt::decrypt(session_token_bytes.as_ref(), &session_secret).unwrap();

            let account_id = query!(
                r#"
                    SELECT * FROM session WHERE id = $1
                "#,
                Uuid::from_slice(session_id.as_ref()).unwrap()
            )
            .fetch_optional(&***db_pool)
            .await
            .unwrap()
            .unwrap()
            .account_id
            .to_string();

            let res = srv.call(req).await?;

            println!("Hi from ValidateSession to {}", account_id);
            Ok(res)
        })
    }
}
