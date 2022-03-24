use deku::prelude::*;
use std::marker::{PhantomData};

#[derive(Clone, Copy, DekuRead, DekuWrite)]
#[deku(endian = "big", ctx = "endian: deku::ctx::Endian", ctx_default = "deku::ctx::Endian::Big")]
pub struct Id<T> {
    id: u64,
    #[deku(skip)]
    phantom: PhantomData<T>,
}

impl<T> Id<T> {
    pub fn new(inner: u64) -> Self {
        Id {
            id: inner,
            phantom: PhantomData,
        }
    }

    pub fn get_inner(self) -> u64 {
        self.id
    }
}
