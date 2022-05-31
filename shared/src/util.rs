use deku::bitvec::{BitVec, Msb0};
use deku::prelude::*;

pub trait DekuRW
where
    Self: for<'a> DekuContainerRead<'a> + DekuContainerWrite + Sized,
{
    fn read(bytes: &[u8]) -> Result<Self, DekuError> {
        let bit_offset = 0;
        Ok(DekuContainerRead::from_bytes((bytes, bit_offset))?.1)
    }
}

impl<T> DekuRW for T
where
    T: for<'a> DekuContainerRead<'a> + DekuContainerWrite + Sized,
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
