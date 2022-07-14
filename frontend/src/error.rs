use std::fmt::{self};

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

impl fmt::Display for DbError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            DbError::DekuRead(_) => write!(f, "database is corrupted"),
            DbError::Rexie(error) => write!(f, "{}", error),
        }
    }
}
