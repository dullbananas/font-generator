use std::fmt::{self, Display, Formatter}; // includes `Display::fmt` method

#[derive(Debug)]
pub enum DbError {
    DekuRead(deku::error::DekuError),
    Rexie(rexie::Error),
}

impl From<deku::error::DekuError> for DbError {
    fn from(error: deku::error::DekuError) -> Self {
        DbError::DekuRead(error)
    }
}

impl From<rexie::Error> for DbError {
    fn from(error: rexie::Error) -> Self {
        DbError::Rexie(error)
    }
}

impl Display for DbError {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result {
        match self {
            DbError::DekuRead(_) => "database is corrupted".fmt(f),
            DbError::Rexie(error) => error.fmt(f),
        }
    }
}
