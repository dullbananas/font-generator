use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_name = showStatus)]
    pub fn show_status(status: &str);
}
