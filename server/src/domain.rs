use unicode_segmentation::UnicodeSegmentation;
use crate::routes::LoginRequest;

pub struct LoginData {
    pub account_name: AccountName,
    pub password: AccountPassword,
}

impl LoginData {
    pub fn parse(req: LoginRequest) -> LoginData {
        LoginData {
            account_name: AccountName::parse(req.account.to_string()),
            password: AccountPassword::parse(req.pw.to_string())
        }
    }
}

pub struct AccountName(String);

impl AccountName {
    pub fn parse(s: String) -> AccountName {
        let is_empty_or_whitespace = s.trim().is_empty();
        let is_too_long = s.graphemes(true).count() > 20;
        let forbidden_characters = ['/', '(', ')', '"', '<', '>', '\\', '{', '}', ';'];
        let contains_forbidden_characters = s.chars().any(|g| forbidden_characters.contains(&g));
        if is_empty_or_whitespace || is_too_long || contains_forbidden_characters {
            panic!("{} is not a valid account name", s)
        } else {
            Self(s)
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
    pub fn parse(s: String) -> AccountPassword {
        let is_empty_or_whitespace = s.trim().is_empty();
        let is_too_long = s.graphemes(true).count() > 48;
        let is_too_short = s.graphemes(true).count() < 8;
        if is_empty_or_whitespace || is_too_long || is_too_short {
            panic!("{} is not a valid account password", s)
        } else {
            Self(s)
        }
    }
}

impl AsRef<[u8]> for AccountPassword {
    fn as_ref(&self) -> &[u8] {
        &self.0.as_bytes()
    }
}
