use sycamore::prelude::*;

#[component]
pub fn CharInput<'a, G: Html, F>(cx: Scope<'a>, mut handler: F) -> View<G>
where
    F: FnMut(char) + 'a,
{
    let signal = create_signal(cx, String::new());

    create_effect(cx, move || {
        let string = signal.get();
        if !string.is_empty() {
            signal.set(String::new());
            string.chars().for_each(&mut handler);
        }
    });

    view! { cx,
        input(class="char-input", bind:value=signal)
    }
}
