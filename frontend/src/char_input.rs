use sycamore::prelude::*;

#[component(CharInput<G>)]
pub fn char_input<F>(mut handler: F) -> View<G>
where
    F: FnMut(char) + 'static,
{
    let signal = Signal::new(String::new());

    create_effect(cloned!(signal => move || {
        let string = signal.get();
        if !string.is_empty() {
            signal.set(String::new());
            string.chars().for_each(&mut handler);
        }
    }));

    view! {
        input(class="char-input", bind:value=signal)
    }
}
