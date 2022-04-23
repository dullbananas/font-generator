use crate::font::{self, Font};
use crate::test_session::{TestSession};
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
    test_sessions: sled::Tree,
}

// Functions that interact with the database are async just in case sled adds async support
impl State {
    pub async fn new() -> Result<Self, E> {
        let db = sled::Config::default()
            .path("DullBananasFontGenData")
            .mode(sled::Mode::LowSpace)
            .open()?;

        Ok(State {
            glyphs: db.open_tree(b"glyphs")?,
            font_versions: db.open_tree(b"font_versions")?,
            fonts: db.open_tree(b"fonts")?,
            test_sessions: db.open_tree(b"test_sessions")?,

            // Move db into this struct after db.open_tree is no longer needed
            db,
        })
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, E> {
        let version_id = self.generate_id().await?;
        let _: font::Version = self.add_font_version(
            version_id,
            self.add_glyphs(&glyphs).await?,
        ).await?;

        let font_id = self.generate_id().await?;
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
            next_version: self.generate_id().await?,
            glyphs: glyph_ids,
        };
        self.font_versions.insert(
            id.to_bytes()?,
            version.to_bytes()?,
        )?;
        Ok(version)
    }

    pub async fn submit_time(&self, user_id: Id<User>, time: f64) -> Result<(), E> {
        if let Some(session: TestSession) = {
            let bytes = self.test_sessions.remove(user_id.to_bytes()?)?;
            DekuContainerRead::from_bytes((bytes, 0))
        } {
            let change_glyph: bool = match get_glyph_score
        }
    }

    async fn add_glyphs(&self, glyphs: &[Glyph]) -> Result<Vec<Id<Glyph>>, E> {
        let mut glyph_ids = Vec::with_capacity(glyphs.len());

        for glyph in glyphs {
            let id = self.generate_id().await?;
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
        Ok(Id::new(id))
    }
}
