use crate::routes::LoginRequest;
use actix_web::web::Json;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct LoginData {
    pub account_name: AccountName,
    pub password: AccountPassword,
}

impl LoginData {
    pub fn parse(req: Json<LoginRequest>) -> Result<LoginData, LoginDataError> {
        let account_name = AccountName::parse(&req.account)?;
        let password = AccountPassword::parse(&req.pw)?;
        Ok(LoginData {
            account_name,
            password,
        })
    }
}

#[derive(Debug)]
pub struct LoginDataError(String);

impl AsRef<String> for LoginDataError {
    fn as_ref(&self) -> &String {
        &self.0
    }
}

#[derive(Debug)]
pub struct AccountName(String);

impl AccountName {
    pub fn parse(s: &Option<String>) -> Result<AccountName, LoginDataError> {
        if s.is_none() {
            Err(LoginDataError("Missing account name field".to_string()))
        } else if s.as_ref().unwrap().trim().is_empty() {
            Err(LoginDataError("Missing account name".to_string()))
        } else if s.as_ref().unwrap().graphemes(true).count() > 20 {
            Err(LoginDataError("Account name too long".to_string()))
        } else {
            let forbidden_characters = ['/', '(', ')', '"', '<', '>', '\\', '{', '}', ';'];
            let contains_forbidden_characters = s
                .as_ref()
                .unwrap()
                .chars()
                .any(|g| forbidden_characters.contains(&g));
            if contains_forbidden_characters {
                Err(LoginDataError(
                    "Account name contains invalid chars".to_string(),
                ))
            } else {
                Ok(Self(s.clone().unwrap()))
            }
        }
    }
}

impl AsRef<str> for AccountName {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, Clone)]
pub struct AccountPassword(String);

impl AccountPassword {
    pub fn parse(s: &Option<String>) -> Result<AccountPassword, LoginDataError> {
        if s.is_none() {
            Err(LoginDataError("Missing pw field".to_string()))
        } else if s.as_ref().unwrap().trim().is_empty() {
            Err(LoginDataError("Missing pw".to_string()))
        } else if s.as_ref().unwrap().graphemes(true).count() > 48 {
            Err(LoginDataError("Password too long".to_string()))
        } else if s.as_ref().unwrap().graphemes(true).count() < 8 {
            Err(LoginDataError("Password too short".to_string()))
        } else {
            Ok(Self(s.clone().unwrap()))
        }
    }
}

impl AsRef<[u8]> for AccountPassword {
    fn as_ref(&self) -> &[u8] {
        &self.0.as_bytes()
    }
}
