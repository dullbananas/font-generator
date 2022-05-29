// Functions are async for future-proofing

use crate::util::{Error as E};
use deku::prelude::*;
use shared::id::{Id};
use shared::util::{DekuRW};
use std::marker::{PhantomData};

/// Manages all stored data.
#[derive(Clone)]
pub struct Database {
    db: sled::Db,
}

impl Database {
    /// Open the DullBananasFontGenData directory, which contains all trees.
    pub async fn open() -> Result<Self, E> {
        Ok(Database {
            db: sled::Config::default()
                .path("DullBananasFontGenData")
                .mode(sled::Mode::LowSpace)
                .open()?,
        })
    }

    /// Open the named tree. `T` must be specified.
    pub async fn tree<T, Key>(&self, name: &'static [u8]) -> Result<Tree<T, Key>, E> {
        Ok(Tree {
            db: self.db.clone(),
            tree: self.db.open_tree(name)?,
            phantom: PhantomData,
        })
    }

    /// Reserve an `Id` for any type. If the returned `Id` will be used immediately, use `Tree::insert` instead.
    pub async fn generate_id<T>(&self) -> Result<Id<T>, E> {
        Ok(Id::new(
            self.db.generate_id()?,
        ))
    }
}

/// Stores items similarly to `std::collections::BTreeMap<Key, T>`.
pub struct Tree<T, Key = Id<T>> {
    db: sled::Db,
    tree: sled::Tree,
    phantom: PhantomData<(T, Key)>,
}

impl<'deku, T, Key> Tree<T, Key>
where
    T: DekuRW<'deku>,
    Key: DekuRW<'deku>,
{
    /// Insert a value with the specified key.
    pub async fn insert_with_key(&self, key: Key, value: &T) -> Result<(), E> {
        self.tree.insert(
            key.to_bytes()?,
            value.to_bytes()?,
        )?;
        Ok(())
    }
}

impl<'deku, T> Tree<T, Id<T>>
where
    T: DekuRW<'deku>,
{
    /// Insert a value with an automatically chosen key that hasn't been used yet, and return the key.
    pub async fn insert(&self, value: &T) -> Result<Id<T>, E> {
        let key = Id::new(self.db.generate_id()?);
        self.insert_with_key(key, value).await?;
        Ok(key)
    }

    /// Insert multiple values, and return the new keys.
    pub async fn insert_each<'a, Iter>(&self, values: Iter) -> Result<Vec<Id<T>>, E>
    where
        Iter: Iterator<Item = &'a T> + 'a,
        T: 'a,
    {
        let mut keys = Vec::with_capacity(values.size_hint().0);

        for value in values {
            let id = self.insert(value).await?;
            keys.push(id);
        }

        Ok(keys)
    }
}

// T and Key don't need to be clonable
impl<T, Key> Clone for Tree<T, Key> {
    fn clone(&self) -> Tree<T, Key> {
        Tree {
            db: self.db.clone(),
            tree: self.tree.clone(),
            phantom: PhantomData,
        }
    }
}
