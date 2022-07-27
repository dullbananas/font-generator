use crate::error::{DbError};
use deku::{DekuContainerRead, DekuContainerWrite, DekuError};
use shared::glyph::{Glyph};
use rexie::{Rexie};
use std::collections::btree_map::{BTreeMap, Entry};
use sycamore::prelude::*;
use wasm_bindgen::prelude::{wasm_bindgen};

const GLYPHS_STORE: &str = "glyphs";

#[derive(Copy, Clone)]
pub struct State<'a> {
    pub current_char: &'a Signal<char>,
    pub db_status: &'a Signal<Option<Result<(), DbError>>>,
    pub glyphs: &'a Signal<BTreeMap<char, RcSignal<Glyph>>>,
    db: &'a Signal<Option<Rexie>>,
}

#[wasm_bindgen(js_namespace = fontGeneratorImports)]
extern "C" {
    type GlyphDbObject;

    #[wasm_bindgen(constructor)]
    fn new(char: char, value: Box<[u8]>) -> GlyphDbObject;

    #[wasm_bindgen(method, getter)]
    fn value(this: &GlyphDbObject) -> Box<[u8]>;
}

impl<'a> State<'a> {
    pub fn new(cx: Scope<'a>) -> Self {
        State {
            current_char: create_signal(cx, 'a'),
            db: create_signal(cx, None),
            db_status: create_signal(cx, None),
            glyphs: create_signal(cx, BTreeMap::new()),
        }
    }

    pub async fn init(self) {
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
                    Ok((glyph.char, create_rc_signal(glyph)))
                })
                .collect::<Result<BTreeMap<_, _>, DekuError>>()?
        );

        self.db.set(Some(db));

        Ok(())
    }

    /// Adds a glyph for the given character if it doesn't already exist
    pub fn add_glyph(&self, char: char) {
        let mut glyphs = self.glyphs.modify();

        if let Entry::Vacant(entry) = glyphs.entry(char) {
            entry.insert(create_rc_signal(Glyph::new(char)));
        }
    }
}
