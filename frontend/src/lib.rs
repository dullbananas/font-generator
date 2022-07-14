mod error;
mod font_editor;

use sycamore::prelude::*;
use sycamore_router::{HistoryIntegration, Route, Router, RouterProps};
use wasm_bindgen::prelude::{wasm_bindgen};

#[derive(Route)]
enum PageRoute {
    #[to("/editor.html")]
    FontEditor,
    #[not_found]
    NotFound,
}

#[wasm_bindgen(start)]
pub fn init() {
    std::panic::set_hook(Box::new(console_error_panic_hook::hook));

    sycamore::render(|| view! {
        Router(RouterProps::new(
            HistoryIntegration::new(),
            |route: ReadSignal<PageRoute>| {
                let body = create_memo(move || match route.get().as_ref() {
                    PageRoute::FontEditor => view! {
                        font_editor::Body()
                    },
                    PageRoute::NotFound => view! {
                        "The requested page does not exist."
                    },
                });

                view! {
                    div {
                        (body.get().as_ref().clone())
                    }
                }
            },
        ))
    });
}
