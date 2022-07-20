use crate::char_input::{CharInput};
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
            div {
                label {
                    "Add glyph "
                    CharInput(add_glyph)
                }
            }
            Keyed(KeyedProps {
                iterable: glyphs_vec,
                template: |glyph| view! {
                    div {
                        (glyph.get().char())
                    }
                },
                key: |glyph| glyph.get().char(),
            })
        }
    }
}
