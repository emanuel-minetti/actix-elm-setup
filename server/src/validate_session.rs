use actix_web::dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform};
use actix_web::{web, Error, HttpMessage};
use base64::engine::general_purpose;
use base64::Engine;
use bytes::Bytes;
use futures_util::future::LocalBoxFuture;
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

            let session_token = req
                .cookie("session_token")
                .expect("Failed to get session token from cookie.")
                .value()
                .to_string();
            let session_token_bytes = general_purpose::URL_SAFE
                .decode(&session_token)
                .expect("Failed decoding base64 encoded session token.");
            let session_id_bytes =
                simple_crypt::decrypt(session_token_bytes.as_ref(), &session_secret)
                    .expect("Failed decrypting session token.");
            let session_id = Uuid::from_slice(session_id_bytes.as_ref()).unwrap();

            let session_row = query!(
                // language=postgresql
                r#"
                    SELECT * FROM session WHERE id = $1
                "#,
                session_id
            )
            .fetch_optional(&***db_pool)
            .await
            .expect("Failed to read session from database.");

            let logged_in = session_row.is_some()
                && session_row
                    .as_ref()
                    .expect("Failed to get session row from database.")
                    .expires_at
                    >= Utc::now().naive_utc();

            if logged_in {
                let new_session_row = query!(
                    // language=postgresql
                    r#"
                        UPDATE session SET expires_at = DEFAULT
                            WHERE id = $1 RETURNING account_id, expires_at
                    "#,
                    session_id
                )
                .fetch_one(&***db_pool)
                .await
                .expect("");

                req.extensions_mut().insert(Some(ServerSession {
                    account_id: new_session_row.account_id,
                    expires_at: new_session_row.expires_at,
                }));
            } else {
                req.extensions_mut().insert(None::<ServerSession>);
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
            .expect("Failed to read session from database.");

            let res = srv.call(req).await?;

            Ok(res)
        })
    }
}
