use log::{debug};
use sauron::*;

struct App {
    count: i32,
}


enum Msg {
    Increment,
    Decrement,
    Reset,
}

impl Application for App {
    type MSG = Msg;

    fn update(&mut self, msg: Msg) -> Cmd<Msg> {
        match msg {
            Msg::Increment => self.count += 1,
            Msg::Decrement => self.count -= 1,
            Msg::Reset => self.count = 0,
        }
        Cmd::none()
    }
    fn view(&self) -> Node<Msg> {
        node! {
            <main>
                <input type="button"
                    value="+"
                    on_click=|_| {
                        Msg::Increment
                    }
                />
                <button class="count" on_click=|_|{Msg::Reset} >{text(self.count)}</button>
                <input type="button"
                    value="-"
                    on_click=|_| {
                        Msg::Decrement
                    }
                />
            </main>
        }
    }
}

#[wasm_bindgen(start)]
pub fn main() {
    console_log::init_with_level(log::Level::Debug).unwrap();
    debug!("Can debug and build.");
    Program::mount_to_body(App{ count: 0 });
}