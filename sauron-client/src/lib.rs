use sauron::web_sys::Window;
use log::{debug};
use sauron::*;

struct App {
    url: String,
    lang: Option<String>,
    token: Option<String>,
    expires: Option<u32>,
}


enum Msg { }

impl Default for App {
    fn default() -> Self {
        Self {
            url: String::new(),
            lang: None,
            token: None,
            expires: None,
        }
    }
}

impl Application for App {
    type MSG = Msg;

    fn init(&mut self) -> Cmd<Self::MSG> {
        let window: Window = web_sys::window().expect("no global `window` exists");
        let location = window.location();
        self.url = location.pathname().expect("can't get location").to_owned();
        let storage = window.local_storage()
            .expect("can't get local storage")
            .expect("can't get local storage");
        self.lang = storage.get_item("lang").expect("can't read lang from storage");
        self.token = storage.get_item("token").expect("can't read token from storage");
        let expires_string_option =
            storage.get_item("expires").expect("can't read from expires");
        self.expires = match expires_string_option {
            None => None,
            Some(string) => { match  string.parse::<u32>() {
                Ok(u32) => Some(u32),
                Err(_) => None
            }},
        };
        Cmd::none()
    }

    fn update(&mut self, _msg: Msg) -> Cmd<Msg> {
        Cmd::none()
    }
    fn view(&self) -> Node<Msg> {
        node! {
            <main>
                {text(format!("Die URL ist: {}", self.url))}
                <br/>
                {text(format!("Lang: {}", self.lang.as_ref().unwrap_or(&"".to_string())))}
                <br/>
                {text(format!("Token: {}", self.token.as_ref().unwrap_or(&"".to_string())))}
                <br/>
                {text(format!("Expires: {}", self.expires.as_ref().unwrap_or(&0)))}
                <br/>
            </main>
        }
    }
}

#[wasm_bindgen(start)]
pub fn main() {
    console_log::init_with_level(log::Level::Trace).unwrap();
        debug!("Can debug and build.");
    let mut app = App::default();
    app.init();
    Program::mount_to_body(app);
}