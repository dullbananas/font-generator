use shared::glyph::{Glyph};
use sycamore::prelude::*;

/// Displays a `Glyph`, filling the parent element's entire width or height
#[component]
pub fn GlyphSvg<'a, G: Html>(cx: Scope<'a>, glyph: RcSignal<Glyph>) -> View<G> {
    view! { cx,
        svg(xmlns="http://www.w3.org/2000/svg", viewBox="0 0 32767 32767") {
            path(fill-rule="evenodd", d=glyph.get().to_svg_path_d())
        }
    }
}
