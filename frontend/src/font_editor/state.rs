use crate::error::{DbError};
use deku::{DekuContainerRead, DekuContainerWrite, DekuError};
use shared::glyph::{Glyph};
use rexie::{Rexie};
use std::collections::{BTreeMap};
use std::cell::{RefCell};
use std::rc::{Rc};
use sycamore::reactive::{Signal};
use wasm_bindgen::prelude::{wasm_bindgen};

const GLYPHS_STORE: &str = "glyphs";

#[derive(Clone)]
pub struct State {
    pub current_char: Signal<char>,
    pub db_status: Signal<Option<Result<(), DbError>>>,
    pub glyphs: Signal<BTreeMap<char, Signal<Glyph>>>,
    db: Rc<RefCell<Option<Rexie>>>,
}

#[wasm_bindgen(js_namespace = fontGeneratorImports)]
extern "C" {
    type GlyphDbObject;

    #[wasm_bindgen(constructor)]
    fn new(char: char, value: Box<[u8]>) -> GlyphDbObject;

    #[wasm_bindgen(method, getter)]
    fn value(this: &GlyphDbObject) -> Box<[u8]>;
}

impl Default for State {
    fn default() -> Self {
        State {
            current_char: Signal::new('a'),
            db: Rc::default(),
            db_status: Signal::default(),
            glyphs: Signal::default(),
        }
    }
}

impl State {
    pub async fn init(&self) {
        self.db_status.set(Some(self.init_db().await));
    }

    async fn init_db(&self) -> Result<(), DbError> {
        let db = Rexie::builder("font-editor")
            .version(1)
            .add_object_store(
                rexie::ObjectStore::new(GLYPHS_STORE)
                    .key_path("char")
            )
            .build()
            .await?;

        self.glyphs.set(
            db.transaction(&[GLYPHS_STORE], rexie::TransactionMode::ReadOnly)?
                .store(GLYPHS_STORE)?
                .get_all(None, None, None, None)
                .await?
                .into_iter()
                .map(|(_key, item)| {
                    let glyph: Glyph = {
                        let bytes = wasm_bindgen::JsCast::dyn_into::<GlyphDbObject>(item)
                            .unwrap()
                            .value();
                        DekuContainerRead::from_bytes((&bytes, 0))?.1
                    };
                    Ok((glyph.char(), Signal::new(glyph)))
                })
                .collect::<Result<BTreeMap<char, Signal<Glyph>>, DekuError>>()?
        );

        self.db.replace(Some(db));

        Ok(())
    }
}
