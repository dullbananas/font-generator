use crate::active_test::{ActiveTest};
use crate::database::{Database, Tree};
use crate::font::{self, Font};
use crate::user::{User};
use crate::util::{Error as E};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::id::{Id};

pub type Request = tide::Request<State>;

#[derive(Clone)]
pub struct State {
    db: Database,
    glyphs: Tree<Glyph>,
    font_versions: Tree<font::Version>,
    fonts: Tree<Font>,
    active_tests: Tree<ActiveTest, Id<User>>,
}

impl State {
    pub async fn new() -> Result<Self, E> {
        let db = Database::open().await?;

        Ok(State {
            glyphs: db.tree(b"glyphs").await?,
            font_versions: db.tree(b"font_versions").await?,
            fonts: db.tree(b"fonts").await?,
            active_tests: db.tree(b"test_sessions").await?,

            // Move db into this struct after db.tree is no longer needed
            db,
        })
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, E> {
        let first_version_id = self.db.generate_id().await?;
        let _: font::Version = self.add_font_version(
            first_version_id,
            self.glyphs.insert_each(glyphs.iter()).await?,
        ).await?;

        let font = Font {
            first_version: first_version_id,
            current_version: first_version_id,
            candidates: self.glyphs.insert_each({
                let iter = glyphs
                    .clone()
                    .into_iter()
                    .map(Result::<_, std::convert::Infallible>::Ok);
                match Glyph::generate_variants(iter) {
                    Ok(candidates) => candidates,
                    Err(never) => match never {},
                }.iter()
            }).await?,
        };
        let font_id = self.fonts.insert(&font).await?;

        Ok(font_id)
    }

    async fn add_font_version(
        &self,
        id: Id<font::Version>,
        glyph_ids: Vec<Id<Glyph>>,
    ) -> Result<font::Version, E> {
        let version = font::Version {
            next_version: self.db.generate_id().await?,
            glyphs: glyph_ids,
        };
        self.font_versions.insert_with_key(id, &version).await?;
        Ok(version)
    }

    pub async fn submit_time(&self, user_id: Id<User>, time: f64) -> Result<(), E> {
        todo!()
    }
}
