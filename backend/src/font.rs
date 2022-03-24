use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::util::{char_map, char_write};
use shared::id::{Id};

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct Font {
    next_version: Id<Version>,
}

pub struct Version;

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct VersionItemKey {
    id: Id<Version>,
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
    char: char,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
struct VersionItem {
    score: Option<f64>,
    glyph: Id<Glyph>,
}
