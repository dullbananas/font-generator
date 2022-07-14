mod state;

use self::state::{State};
use sycamore::prelude::*;

#[component(Body<G>)]
pub fn body() -> View<G> {
    let state = State::default();

    wasm_bindgen_futures::spawn_local(cloned!(state => async move {
        state.init().await;
    }));

    let db_status_string = create_memo(cloned!(state => move ||
        match *state.db_status.clone().get() {
            None => Box::from("Syncing with browser storage..."),
            Some(Ok(())) => Box::from("\u{00A0}"),
            Some(Err(ref error)) => format!("Error: {}", error).into_boxed_str(),
        }
    ));

    view! {
        p {
            (db_status_string.get())
        }
    }
}
