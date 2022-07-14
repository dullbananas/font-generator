use async_std::stream::{Stream, StreamExt};
use crate::active_test::{ActiveTest};
use crate::database::{Database, Id, Tree};
use crate::font::{self, Font};
use crate::user::{User};
use crate::error::{Error as E};
use shared::glyph::{Glyph};

#[derive(Clone)]
pub struct State {
    active_tests: Tree<ActiveTest, Id<User>>,
    font_version_glyphs: Tree<font::VersionGlyph, font::VersionGlyphKey>,
    font_versions: Tree<font::Version>,
    fonts: Tree<Font>,
    glyphs: Tree<Glyph>,
}

impl State {
    pub async fn new() -> Result<Self, E> {
        let db = Database::open().await?;

        Ok(State {
            active_tests: db.tree(b"test_sessions").await?,
            font_version_glyphs: db.tree(b"scores").await?,
            font_versions: db.tree(b"font_versions").await?,
            fonts: db.tree(b"fonts").await?,
            glyphs: db.tree(b"glyphs").await?,
        })
    }

    pub async fn add_font(&self, glyphs: Vec<Glyph>) -> Result<Id<Font>, E> {
        let first_version_id = Id::generate(&self.font_versions).await?;
        let _: font::Version = self.add_font_version(
            first_version_id,
            self.glyphs
                .insert_each(glyphs.iter()).await?
                .into_iter()
                .map(|id| font::VersionGlyph {
                    glyph: id,
                    score: None,
                })
                // Convert items to borrowed items
                .collect::<Vec<_>>()
                .iter(),
        ).await?;

        let font = Font {
            first_version: first_version_id,
            current_version: first_version_id,
            candidates: self.glyphs.insert_each(
                Glyph::generate_variants(glyphs.iter()).iter()
            ).await?,
        };
        let font_id = self.fonts.insert(&font).await?;

        Ok(font_id)
    }

    async fn add_font_version(
        &self,
        id: Id<font::Version>,
        version_glyphs: impl Iterator<Item = &font::VersionGlyph>,
    ) -> Result<font::Version, E> {
        let version = font::Version {
            next_version: Id::generate(&self.font_versions).await?,
        };
        self.font_versions.insert_with_key(id, &version).await?;

        for version_glyph in version_glyphs {
            self.font_version_glyphs.insert_with_key(
                font::VersionGlyphKey {
                    font_version: id,
                    char: self.get_glyph_char(version_glyph.glyph).await?,
                },
                &version_glyph,
            ).await?;
        }

        Ok(version)
    }

    pub async fn submit_time(
        &self,
        user_id: Id<User>,
        new_time: f64,
    ) -> Result<(), E> {
        let test = match self.active_tests.remove(user_id).await? {
            Some(removed_value) => removed_value,
            None => return Ok(()),
        };

        let font = E::expect_db_item(self.fonts.get(test.font).await?)?;

        let version_glyph_key = font::VersionGlyphKey {
            font_version: font.current_version,
            char: self.get_glyph_char(test.glyph).await?,
        };

        match self.font_version_glyphs.get(version_glyph_key).await? {
            Some(font::VersionGlyph {
                score: Some(font::Score { time, .. }),
                ..
            }) if new_time > time => {},
            _ => {
                self.font_version_glyphs.insert_with_key(
                    version_glyph_key,
                    &font::VersionGlyph {
                        glyph: test.glyph,
                        score: Some(font::Score {
                            time: new_time,
                            user: user_id,
                        }),
                    },
                ).await?;
            },
        };
        Ok(())
    }

    pub async fn add_next_test(
        &self,
        font_id: Id<Font>,
        user_id: Id<User>,
    ) -> Result<(), E> {
        let mut font = E::expect_db_item(self.fonts.get(font_id).await?)?;

        if font.candidates.is_empty() {
            // Get from the current font version
            let version_glyphs: Vec<font::VersionGlyph> = {
                let mut stream = self.font_version_glyphs.scan_prefix(font.current_version)?;
                let mut vec = Vec::with_capacity(stream.size_hint().0);
                while let Some(result) = stream.next().await {
                    vec.push(result?.1);
                }
                vec
            };

            // Duplicate the current font version, with the same `font::VersionGlyph`s being included
            font.current_version = {
                let id = E::expect_db_item(
                    self.font_versions.get(font.current_version).await?
                )?.next_version;
                let _: font::Version = self.add_font_version(id, version_glyphs.iter()).await?;
                id
            };

            // Add candidates
            font.candidates = {
                let mut glyphs = Vec::with_capacity(version_glyphs.len());
                for font::VersionGlyph { glyph, .. } in version_glyphs {
                    glyphs.push(
                        E::expect_db_item(self.glyphs.get(glyph).await?)?
                    );
                }
                self.glyphs.insert_each(
                    Glyph::generate_variants(glyphs.iter()).iter()
                ).await?
            };

            // Save the modified font
            self.fonts.insert_with_key(font_id, &font).await?;
        }

        if let Some(&glyph_id) = font.candidates.first() {
            self.active_tests.insert_with_key(
                user_id,
                &ActiveTest {
                    font: font_id,
                    glyph: glyph_id,
                },
            ).await?;
        }

        Ok(())
    }

    pub async fn get_test_glyph(
        &self,
        user_id: Id<User>,
    ) -> Result<Option<Glyph>, E> {
        Ok(match self.active_tests.get(user_id).await? {
            Some(test) => self.glyphs.get(test.glyph).await?,
            None => None,
        })
    }

    async fn get_glyph_char(&self, glyph_id: Id<Glyph>) -> Result<char, E> {
        Ok(E::expect_db_item(self.glyphs.get(glyph_id).await?)?.char())
    }
}
