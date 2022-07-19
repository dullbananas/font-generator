use std::fmt::{self, Display, Formatter}; // includes `Display::fmt` method
use std::io::{self};

#[derive(Debug)]
pub enum InitError {
    Io(io::Error),
    Sled(sled::Error),
}

impl From<io::Error> for InitError {
    fn from(error: io::Error) -> Self {
        InitError::Io(error)
    }
}

impl From<sled::Error> for InitError {
    fn from(error: sled::Error) -> Self {
        InitError::Sled(error)
    }
}

impl Display for InitError {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result {
        match self {
            InitError::Io(error) => match error.kind() {
                io::ErrorKind::AddrInUse => "address or port is already taken (set the ADDRESS environment variable to change it)".fmt(f),
                io::ErrorKind::AddrNotAvailable => "address is invalid".fmt(f),
                _ => error.fmt(f),
            },
            InitError::Sled(error) => error.fmt(f),
        }
    }
}

#[derive(Debug)]
pub struct Error {
    message: String,
}

impl Error {
    pub fn expect_db_item<T>(result: Option<T>) -> Result<T, Error> {
        result.ok_or(Error {
            message: format!(
                "Could not find a value of type \"{}\" in the database.",
                std::any::type_name::<T>(),
            ),
        })
    }
}

impl From<std::io::Error> for Error {
    fn from(error: std::io::Error) -> Self {
        use std::io::ErrorKind::*;

        Error {
            message: match error.kind() {
                TimedOut =>
                    "The server took too long to do something."
                        .to_owned(),

                _ =>
                    format!(
                        "This IO error happened on the server: {}",
                        error,
                    ),
            },
        }
    }
}

impl From<sled::Error> for Error {
    fn from(error: sled::Error) -> Self {
        use sled::Error::*;

        match error {
            Io(error) =>
                Error::from(error),

            _ =>
                Error {
                    message: format!(
                        "A problem occured with the server's database: {}",
                        error,
                    ),
                },
        }
    }
}

impl From<deku::DekuError> for Error {
    fn from(error: deku::DekuError) -> Self {
        Error {
            message: format!(
                "Could not deserialize/serialize data: {}",
                error,
            ),
        }
    }
}
