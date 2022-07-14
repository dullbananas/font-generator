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
    let address = format!(
        "127.0.0.1:{}",
        std::env::var("PORT")
            .unwrap_or("8080".to_owned()),
    );

    let mut server = tide::with_state(State::new().await?);
    endpoints::init(&mut server)?;
    println!("Running server at {}", address);
    server.listen(address).await?;

    Ok(())
}
