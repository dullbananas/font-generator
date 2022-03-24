use crate::font::{Font};
use crate::util::{Error};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::id::{Id};

#[derive(Clone)]
pub struct State {
    db: sled::Db,
    glyphs_table: sled::Tree,
}

impl State {
    pub async fn new() -> Self {
        let db = sled::Config::default()
            .path("DullBananasFontGenData")
            .mode(sled::Mode::LowSpace)
            .open()
            .unwrap();

        let glyphs = db.open_tree(b"glyphs").unwrap();

        State {
            db: db,
            glyphs_table: glyphs,
        }
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, Error> {
        todo!()
    }

    async fn add_glyph(&self, glyph: Glyph) -> Result<Id<Glyph>, Error> {
        let id = Id::<Glyph>::new(self.db.generate_id()?);
        let _old_value = self.glyphs_table.insert(
            id.to_bytes()?,
            glyph.to_bytes()?,
        );
        Ok(id)
    }
}
