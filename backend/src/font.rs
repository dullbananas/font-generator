use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::util::{char_map, char_write};
use shared::id::{Id};

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct Font {
    next_version: Id<Version>,
    #[deku(bits_read = "deku::rest.len()")]
    remaining_glyphs: Vec<Id<Glyph>>
}

pub struct Version;

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct VersionItemKey {
    font_id: Id<Font>,
    version_id: Id<Version>,
    #[deku(map = "char_map", writer = "char_write(deku::output, item_char)")]
    item_char: char,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct VersionItem {
    glyph: Id<Glyph>,
    #[deku(cond = "deku::rest.len() > 0")]
    score: Option<f64>,
}
