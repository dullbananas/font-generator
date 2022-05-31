use crate::user::{User};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::util::{char_map, char_write};
use shared::id::{Id};

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct Font {
    pub first_version: Id<Version>,
    pub current_version: Id<Version>,
    // A queue of glyphs that still need to be tested
    #[deku(bits_read = "deku::rest.len()")]
    pub candidates: Vec<Id<Glyph>>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct Version {
    // An ID that might not be in use yet
    pub next_version: Id<Version>,
}

/// Identifies a `Version` and one of its glyphs.
#[derive(DekuRead, DekuWrite, Clone, Copy)]
#[deku(endian = "big")]
pub struct VersionGlyphKey {
    pub font_version: Id<Version>,
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
    pub char: char,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct VersionGlyph {
    pub glyph: Id<Glyph>,
    #[deku(cond = "deku::rest.len() != 0")]
    pub score: Option<Score>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big", ctx = "endian: deku::ctx::Endian", ctx_default = "deku::ctx::Endian::Big")]
pub struct Score {
    pub time: f64,
    pub user: Id<User>,
}
