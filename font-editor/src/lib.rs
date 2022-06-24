mod state;
mod ui;

use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn init() {
    std::panic::set_hook(Box::new(console_error_panic_hook::hook));
}
