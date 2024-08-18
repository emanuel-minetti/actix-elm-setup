use crate::routes::LoginRequest;
use actix_web::web::Json;
use unicode_segmentation::UnicodeSegmentation;

pub struct LoginData {
    pub account_name: AccountName,
    pub password: AccountPassword,
}

impl LoginData {
    pub fn parse(req: Json<LoginRequest>) -> Result<LoginData, LoginDataError> {
        let account_name = AccountName::parse(req.account.to_string())?;
        let password = AccountPassword::parse(req.pw.to_string())?;
        Ok(LoginData {
            account_name,
            password,
        })
    }
}

#[derive(Debug)]
pub struct LoginDataError(String);

pub struct AccountName(String);

impl AccountName {
    pub fn parse(s: String) -> Result<AccountName, LoginDataError> {
        let is_empty_or_whitespace = s.trim().is_empty();
        let is_too_long = s.graphemes(true).count() > 20;
        let forbidden_characters = ['/', '(', ')', '"', '<', '>', '\\', '{', '}', ';'];
        let contains_forbidden_characters = s.chars().any(|g| forbidden_characters.contains(&g));
        if is_empty_or_whitespace || is_too_long || contains_forbidden_characters {
            Err(LoginDataError("Invalid account name".to_string()))
        } else {
            Ok(Self(s))
        }
    }
}

impl AsRef<str> for AccountName {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

pub struct AccountPassword(String);

impl AccountPassword {
    pub fn parse(s: String) -> Result<AccountPassword, LoginDataError> {
        let is_empty_or_whitespace = s.trim().is_empty();
        let is_too_long = s.graphemes(true).count() > 48;
        let is_too_short = s.graphemes(true).count() < 8;
        if is_empty_or_whitespace || is_too_long || is_too_short {
            Err(LoginDataError("Invalid password".to_string()))
        } else {
            Ok(Self(s))
        }
    }
}

impl AsRef<[u8]> for AccountPassword {
    fn as_ref(&self) -> &[u8] {
        &self.0.as_bytes()
    }
}
