use deku::prelude::*;

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct User {
    #[deku(bytes_read = "HASH_CONFIG.hash_length")]
    password_hash: Vec<u8>,
    #[deku(bits_read = "deku::rest.len()")]
    name: Vec<u8>,
}

const HASH_CONFIG: argon2::Config = argon2::Config {
    ad: &[],
    hash_length: 16,
    lanes: 1,
    mem_cost: 4096,
    secret: &[],
    thread_mode: argon2::ThreadMode::Sequential,
    time_cost: 3,
    variant: argon2::Variant::Argon2id,
    version: argon2::Version::Version13,
};
