use rexie::{ObjectStore, Rexie};
use shared::glyph::{Glyph};
use std::collections::{BTreeMap};
use std::cell::{RefCell};
use std::rc::{Rc};
use sycamore::prelude::*;

const GLYPHS_STORE: &str = "glyphs";

#[derive(Clone)]
struct State {
    current_char: Signal<char>,
    db: Rc<RefCell<Option<Rexie>>>,
    db_status: Signal<Option<Result<(), rexie::Error>>>,
    glyphs: Signal<BTreeMap<char, Signal<Glyph>>>,
}

impl Default for State {
    fn default() -> Self {
        State {
            current_char: Signal::new('a'),
            db: Rc::default(),
            db_status: Signal::default(),
            glyphs: Signal::default(),
        }
    }
}

impl State {
    async fn init(&self) {
        self.db_status.set(Some(self.init_db().await));
    }

    async fn init_db(&self) -> Result<(), rexie::Error> {
        let db = Rexie::builder("font-editor")
            .version(1)
            .add_object_store(
                ObjectStore::new(GLYPHS_STORE)
                    .key_path("char")
            )
            .build()
            .await?;

        todo!("load glyphs");

        self.db.replace(Some(db));

        Ok(())
    }
}

#[component(Body<G>)]
pub fn body() -> View<G> {
    let state = State::default();

    wasm_bindgen_futures::spawn_local(cloned!(state => async move {
        state.init().await;
    }));

    let db_status_string = create_memo(cloned!(state => move ||
        match *state.db_status.clone().get() {
            None => Box::from("Syncing with browser storage..."),
            Some(Ok(())) => Box::from(""),
            Some(Err(ref error)) => format!("Error: {}", error).into_boxed_str(),
        }
    ));

    view! {
        p {
            (db_status_string.get())
        }
    }
}
