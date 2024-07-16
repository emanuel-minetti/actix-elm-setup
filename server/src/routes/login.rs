use actix_web::{HttpResponse, web};
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, query};

#[derive(Serialize)]
struct LoginResponse {
    name: String,
    token: String
}

#[derive(Deserialize)]
pub struct LoginRequest {
    account: String,
    pw: String
}

pub async fn login(req: web::Json<LoginRequest>, db_pool: web::Data<PgPool>) -> HttpResponse {

    let row = query!(r#"
            SELECT pw_hash, name
            FROM account
            WHERE account_name = $1
        "#, req.account)
        .fetch_one(&**db_pool).await.unwrap();

    let authenticated = bcrypt::verify(&req.pw, row.pw_hash.as_str()).unwrap();
    let res: LoginResponse;

    if authenticated {
        res = LoginResponse {
            name: row.name,
            token: "".to_string()
        };
    }
    else {
        res = LoginResponse {
        name: "".to_string(),
        token: "You are not logged in".to_string()
    }; }

//     let client: Client = db_pool.get().await.unwrap();
//     let stmt = client.prepare(
//         r#"
//             SELECT pw_hash, name
//             FROM account
//             WHERE account_name = $1
//         "#
//     ).await.unwrap();
//
//     let rows = client.query(&stmt, &[&req.account]).await.unwrap();
//
//     let authenticated = bcrypt::verify(&req.pw, rows[0].get(0)).unwrap();
//     let mut res = LoginResponse {
//         name: "".to_string(),
//         token: "".to_string()
//     };
//
//     if authenticated {
//         let stmt = client.prepare(
//             r#"
//             INSERT INTO session (id, name) VALUES (DEFAULT, 'test') RETURNING id::varchar
//         "#).await.unwrap();
//         let session_rows = client.query(&stmt, &[&rows[0].get::<usize, String>(1)]).await.unwrap();
//         res = LoginResponse  {
//             name: rows[0].get(1),
//             token: session_rows[0].get(0)
//         };
//     } else {
//         res = LoginResponse  {
//             name: req.account.to_string(),
//             token: "Not logged in".to_string()
//         };
//     }
//
    HttpResponse::Ok().body(serde_json::to_string(&res).unwrap())

}