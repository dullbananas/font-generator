mod glyph_list;
mod state;

use self::glyph_list::{GlyphList};
use self::state::{State};
use sycamore::prelude::*;

#[component]
pub fn Body<G: Html>(cx: Scope) -> View<G> {
    let state = State::new(cx);

    sycamore::futures::spawn_local_scoped(cx, state.init());

    let db_status_string = create_memo(cx, ||
        match *state.db_status.get() {
            None => Box::from("Syncing with browser storage..."),
            Some(Ok(())) => Box::from("\u{00A0}"),
            Some(Err(ref error)) => format!("Error: {}", error).into_boxed_str(),
        }
    );

    view! { cx,
        div(class="box") {
            (db_status_string.get())
        }
        div(class="row fill") {
            GlyphList(state)
        }
    }
}
