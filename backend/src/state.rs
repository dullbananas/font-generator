use crate::font::{self, Font};
use crate::util::{Error as E};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::id::{Id};

#[derive(Clone)]
pub struct State {
    db: sled::Db,
    glyphs: sled::Tree,
    font_versions: sled::Tree,
}

impl State {
    pub async fn new() -> Self {
        let db = sled::Config::default()
            .path("DullBananasFontGenData")
            .mode(sled::Mode::LowSpace)
            .open()
            .unwrap();

        let glyphs = db.open_tree(b"glyphs").unwrap();
        let font_versions = db.open_tree(b"font_versions").unwrap();

        State {
            db: db,
            glyphs: glyphs,
        }
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, E> {
        let font_id = Id::<Glyph>::new(self.)
    }

    async fn mutate_font_version(&self, id: Id<font::Version>) -> Result<Vec<Glyph>, E> {
        //let bytes = self.font_versions.get(id.to_bytes()?)?;
        todo!()
    }

    async fn add_glyph(&self, glyph: Glyph) -> Result<Id<Glyph>, E> {
        let id = self.generate_id::<Glyph>();
        let _old_value = self.glyphs.insert(
            id.to_bytes()?,
            glyph.to_bytes()?,
        );
        Ok(id)
    }

    async fn generate_id<T>(&self) -> Result<Id<T>, E> {
        Id::<T>::new(self.db.generate_id()?)
    }
}
