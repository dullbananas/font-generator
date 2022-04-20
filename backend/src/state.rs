use crate::font::{self, Font};
use crate::user::{User};
use crate::util::{Error as E};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::id::{Id};
use std::convert::{Infallible};

#[derive(Clone)]
pub struct State {
    db: sled::Db,
    glyphs: sled::Tree,
    font_versions: sled::Tree,
    fonts: sled::Tree,
}

// Functions that interact with the database are async just in case sled adds async support
impl State {
    pub async fn new() -> Self {
        let db = sled::Config::default()
            .path("DullBananasFontGenData")
            .mode(sled::Mode::LowSpace)
            .open()
            .unwrap();

        State {
            glyphs: db.open_tree(b"glyphs").unwrap(),
            font_versions: db.open_tree(b"font_versions").unwrap(),
            fonts: db.open_tree(b"fonts").unwrap(),

            db,
        }
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, E> {
        let version_id = self.generate_id::<font::Version>().await?;
        let _: font::Version = self.add_font_version(
            version_id,
            self.add_glyphs(&glyphs).await?,
        ).await?;

        let font_id = self.generate_id::<Font>().await?;
        let font = Font {
            first_version: version_id,
            current_version: version_id,
            candidates: {
                let iter = glyphs
                    .clone()
                    .into_iter()
                    .map(Result::<_, Infallible>::Ok);
                self.add_glyphs(
                    &match Glyph::generate_variants(iter) {
                        Ok(candidates) => candidates,
                        Err(never) => match never {},
                    }
                ).await?
            },
        };
        self.fonts.insert(
            font_id.to_bytes()?,
            font.to_bytes()?,
        )?;

        Ok(font_id)
    }

    async fn add_font_version(
        &self,
        id: Id<font::Version>,
        glyph_ids: Vec<Id<Glyph>>,
    ) -> Result<font::Version, E> {
        let version = font::Version {
            next_version: self.generate_id::<font::Version>().await?,
            glyphs: glyph_ids,
        };
        self.font_versions.insert(
            id.to_bytes()?,
            version.to_bytes()?,
        )?;
        Ok(version)
    }

    pub async fn submit_time(&self, user_id: Id<User>, time: f64) {
    }

    async fn add_glyphs(&self, glyphs: &[Glyph]) -> Result<Vec<Id<Glyph>>, E> {
        let mut glyph_ids = Vec::<Id<Glyph>>::with_capacity(glyphs.len());

        for glyph in glyphs {
            let id = self.generate_id::<Glyph>().await?;
            glyph_ids.push(id);

            self.glyphs.insert(
                id.to_bytes()?,
                glyph.to_bytes()?,
            )?;
        }

        Ok(glyph_ids)
    }

    async fn generate_id<T>(&self) -> Result<Id<T>, E> {
        let id = self.db.generate_id()?;
        Ok(Id::<T>::new(id))
    }
}
