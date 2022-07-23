use shared::glyph::{Glyph};
use sycamore::prelude::*;

/// Displays a `Glyph`, filling the parent element's entire width or height
#[component(GlyphSvg<G>)]
pub fn glyph_svg(glyph: ReadSignal<Glyph>) -> View<G> {
    view! {
        // SVG doesn't work in Sycamore 0.7
        div(dangerously_set_inner_html=&format!(
            r#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32767 32767">
                <path fillRule="evenodd" d="{}"/>
            </svg>"#,
            glyph.get().to_svg_path_d(),
        ))
    }
}
