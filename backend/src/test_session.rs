use crate::font::{Font};
use deku::prelude::*;
use shared::glyph::{Glyph};
use shared::id::{Id};

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct TestSession {
    pub font: Id<Font>,
    pub glyph: Id<Glyph>,
}
