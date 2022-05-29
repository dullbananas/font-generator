use deku::bitvec::{BitVec, Msb0};
use deku::prelude::*;

/// `DekuRW<'a>` is the same as `DekuContainerRead<'a> + DekuContainerWrite`
pub trait DekuRW<'deku>
where
    Self: DekuContainerRead<'deku> + DekuContainerWrite,
{}

impl<'deku, T> DekuRW<'deku> for T
where
    T: DekuContainerRead<'deku> + DekuContainerWrite,
{}

pub fn char_map(n: u32) -> Result<char, DekuError> {
    char::from_u32(n)
        .ok_or(DekuError::Parse("invalid_char".to_owned()))
}

pub fn char_write(output: &mut BitVec<Msb0, u8>, char: &char) -> Result<(), DekuError> {
    u32::from(*char)
        .write(output, ())
}

// For null-terminated strings
pub fn is_null(byte: &u8) -> bool {
    *byte == 0
}
