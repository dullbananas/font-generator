use deku::bitvec::{BitVec, Msb0};
use deku::prelude::*;

pub fn char_map(n: u32) -> Result<char, DekuError> {
    char::from_u32(n)
        .ok_or(DekuError::Parse("invalid_char".to_owned()))
}

pub fn char_write(output: &mut BitVec<Msb0, u8>, char: &char) -> Result<(), DekuError> {
    u32::from(*char)
        .write(output, ())
}
