use crate::{ui};
use rexie::{ObjectStore, Rexie};
use shared::glyph::{Glyph};
use std::collections::{BTreeMap};
use wasm_bindgen::prelude::*;

const GLYPHS_STORE: &str = "glyphs";

#[wasm_bindgen]
pub struct State {
    current_char: char,
    db: Option<Rexie>,
    glyphs: BTreeMap<char, Glyph>,
}

#[wasm_bindgen]
impl State {
    #[wasm_bindgen(js_name = init)]
    pub async fn init() -> Self {
        let mut state = State::new();

        state.init_db().await;
        if let Some(db) = state.db {
            todo!("load data");
            ui::show_status("");
        }

        state
    }
}

impl State {
    pub fn new() -> Self {
        State {
            current_char: 'a',
            db: None,
            glyphs: BTreeMap::new(),
        }
    }

    pub async fn init_db(&mut self) {
        let db_result = Rexie::builder("font-editor")
            .version(1)
            .add_object_store(
                ObjectStore::new(GLYPHS_STORE)
                    .key_path("char")
            )
            .build()
            .await;

        match db_result {
            Ok(db) => self.db = Some(db),
            Err(error) => ui::show_status(&format!("Error: {}", error)),
        }
    }
}
