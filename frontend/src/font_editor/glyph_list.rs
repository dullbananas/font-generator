use crate::char_input::{CharInput};
use crate::glyph_svg::{GlyphSvg};
use shared::glyph::{Glyph};
use super::state::{State};
use sycamore::prelude::*;

#[component]
pub fn GlyphList<'a, G: Html>(cx: Scope<'a>, state: State<'a>) -> View<G> {
    let glyphs_vec: &ReadSignal<Vec<_>> = create_memo(cx, ||
        state.glyphs.get().values().cloned().collect()
    );

    let char_input = create_signal(cx, String::new());

    let add_glyph = move |char| {
        state.add_glyph(char);
    };

    view! { cx,
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
            Keyed {
                iterable: glyphs_vec,
                view: |cx, glyph| {
                    let char = create_selector(cx, {
                        let glyph = glyph.clone();
                        move || (*glyph.get()).char
                    });

                    let classes = create_selector(cx, ||
                        if state.current_char.get() == char.get() {
                            "row gap selected"
                        } else {
                            "row gap"
                        }
                    );

                    let change_glyph = |_|
                        state.current_char.set_rc(char.get());

                    view! { cx,
                        div(class=classes.get(), on:click=change_glyph) {
                            div(class="thumbnail") {
                                GlyphSvg(glyph)
                            }
                            (char.get())
                        }
                    }
                },
                key: |glyph| glyph.get().char,
            }
        }
    }
}
