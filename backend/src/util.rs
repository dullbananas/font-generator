#[derive(Debug)]
pub struct Error {
    message: String,
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
