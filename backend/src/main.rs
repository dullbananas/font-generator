mod active_test;
mod database;
mod endpoints;
mod error;
mod font;
mod state;
mod user;

use crate::state::{State};
use crate::error::{Error};

fn main() {
    async_std::task::block_on(run_server())
        .unwrap();
}

async fn run_server() -> Result<(), Error> {
    let address: Box<str> = std::env::var("ADDRESS")
        .map(String::into_boxed_str)
        .unwrap_or(Box::from("127.0.0.1:8080"));

    let mut server = tide::with_state(State::new().await?);
    endpoints::init(&mut server)?;
    println!("Running server at {}", address);
    server.listen(&*address).await?;

    Ok(())
}
