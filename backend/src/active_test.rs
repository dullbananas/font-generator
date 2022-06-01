use crate::database::{Id};
use crate::font::{Font};
use deku::prelude::*;
use shared::glyph::{Glyph};

// A "test" begins when a glyph is shown to the user, and usually ends when the correct character is typed
#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct ActiveTest {
    pub font: Id<Font>,
    pub glyph: Id<Glyph>,
}
