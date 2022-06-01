// Functions are async for future-proofing

use crate::util::{Error as E};
use deku::prelude::*;
use shared::util::{DekuRW};
use std::marker::{PhantomData};

/// Manages all stored data.
#[derive(Clone)]
pub struct Database {
    db: sled::Db,
}

/// Stores items similarly to `std::collections::BTreeMap<Key, T>`.
pub struct Tree<T, Key = Id<T>> {
    db: sled::Db,
    tree: sled::Tree,
    phantom: PhantomData<(T, Key)>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big", ctx = "endian: deku::ctx::Endian", ctx_default = "deku::ctx::Endian::Big")]
pub struct Id<T> {
    id: u64,
    #[deku(skip)]
    phantom: PhantomData<T>,
}

shared::impl_clone!(Tree<T, Key> { db, tree });
shared::impl_clone!(Id<T> { id });
impl<T> Copy for Id<T> {}

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
}

impl<T, Key> Tree<T, Key>
where
    T: DekuRW,
    Key: DekuRW,
{
    /// Insert a value with the specified key.
    pub async fn insert_with_key(&self, key: Key, value: &T) -> Result<(), E> {
        self.tree.insert(
            key.to_bytes()?,
            value.to_bytes()?,
        )?;
        Ok(())
    }

    /// Return the item's value, or `Ok(None)` if it doesn't exist.
    pub async fn get(&self, key: Key) -> Result<Option<T>, E> {
        Ok(match self.tree.get(key.to_bytes()?)? {
            Some(bytes) => Some(DekuRW::read(&bytes)?),
            None => None,
        })
    }

    pub async fn remove(&self, key: Key) -> Result<Option<T>, E> {
        Ok(match self.tree.remove(key.to_bytes()?)? {
            Some(bytes) => Some(DekuRW::read(&bytes)?),
            None => None,
        })
    }
}

impl<T> Tree<T, Id<T>>
where
    T: DekuRW,
{
    /// Insert a value with an automatically chosen key that hasn't been used yet, and return the key.
    pub async fn insert(&self, value: &T) -> Result<Id<T>, E> {
        let key = Id {
            id: self.db.generate_id()?,
            phantom: PhantomData,
        };
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

impl<T> Id<T> {
    /// Reserve an `Id` for any type. In most cases, use `Tree::insert` instead.
    pub async fn generate(tree: &Tree<T, Self>) -> Result<Self, E> {
        Ok(Id {
            id: tree.db.generate_id()?,
            phantom: PhantomData,
        })
    }
}
