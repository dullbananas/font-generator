mod endpoint;
mod font;
mod state;
mod user;
mod util;

use crate::state::{State};
use crate::util::{Error};

fn main() {
    async_std::task::block_on(run_server())
        .unwrap();
}

async fn run_server() -> Result<(), Error> {
    let mut app = tide::with_state(State::new().await);
    app.at("/font/:id/test").get(endpoint::test);
    app.at("/font/:id/edit").get(endpoint::edit);
    app.listen("127.0.0.1:8080").await?;
    Ok(())
}
