mod char_input;
mod error;
mod font_editor;
mod glyph_svg;

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

    sycamore::render(|cx| view! { cx,
        Router(RouterProps::new(
            HistoryIntegration::new(),
            |cx, route: &ReadSignal<PageRoute>| {
                view! { cx,
                    div(class="col fill") {
                        (match *route.get() {
                            PageRoute::FontEditor => view! { cx,
                                font_editor::Body()
                            },
                            PageRoute::NotFound => view! { cx,
                                "The requested page does not exist."
                            },
                        })
                    }
                }
            },
        ))
    });
}
