use crate::char_input::{CharInput};
use crate::glyph_svg::{GlyphSvg};
use shared::glyph::{Glyph};
use super::state::{State};
use sycamore::prelude::*;

#[component(GlyphList<G>)]
pub fn glyph_list(state: State) -> View<G> {
    let glyphs_vec: ReadSignal<Vec<Signal<Glyph>>> = create_memo(cloned!(state => move ||
        state.glyphs.get().values().cloned().collect()
    ));

    let char_input = Signal::new(String::new());

    let add_glyph = cloned!(state => move |char| {
        state.add_glyph(char);
    });

    view! {
        div(class="col box scroll") {
            h2 {
                "Glyphs"
            }
            div {
                label {
                    "New: "
                    CharInput(add_glyph)
                }
            }
            Keyed(KeyedProps {
                iterable: glyphs_vec,
                template: |glyph| view! {
                    div(class="row gap") {
                        div(class="thumbnail") {
                            GlyphSvg(glyph.handle())
                        }
                        (glyph.get().char())
                    }
                },
                key: |glyph| glyph.get().char(),
            })
        }
    }
}
