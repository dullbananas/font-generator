use crate::state::{State};
use crate::error::{InitError};

type Request = tide::Request<State>;

pub fn init(server: &mut tide::Server<State>) -> Result<(), InitError> {
    server.at("/style.css").serve_file("frontend/static/style.css")?;
    server.at("/target/wasm.js").serve_file("frontend/static/target/wasm.js")?;
    server.at("/target/wasm_bg.wasm").serve_file("frontend/static/target/wasm_bg.wasm")?;
    server.at("/").serve_file("index.html")?;
    server.at("/*").serve_file("index.html")?;

    Ok(())
}
