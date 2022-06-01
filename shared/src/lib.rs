pub mod glyph;
pub mod util;

/// Implements `Clone` on a struct with a `phantom: PhantomData<T>` field, even if `T` doesn't.
/// https://github.com/rust-lang/rust/issues/26925
#[macro_export]
macro_rules! impl_clone {
    ($struct:ident <$($param:ident),*> { $($field:ident),* }) => {
        impl<$($param),*> ::std::clone::Clone for $struct<$($param),*> {
            fn clone(&self) -> Self {
                $struct {
                    $($field: self.$field.clone(),)*
                    phantom: PhantomData,
                }
            }
        }
    };
}
