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
    #[deku(bits_read = "deku::rest.len()")]
    pub glyphs: Vec<Id<Glyph>>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct ScoreKey {
    font_version: Id<Version>,
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
    char: char,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct Score {
    score: f64,
    user: Id<User>,
}

/*#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct GlyphVersionKey {
    font: Id<Font>,
    version: Id<Version>,
    item_char: char,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct GlyphVersion {
    glyph: Id<Glyph>,
    #[deku(cond = "deku::rest.len() > 0")]
    score: Option<f64>,
}*/
