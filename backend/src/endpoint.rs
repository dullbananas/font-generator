use crate::state::{Request};

pub async fn test(req: Request) -> tide::Result {
    let id = req.param("id")?;
    Ok("".into())
}

pub async fn edit(req: Request) -> tide::Result {
    Ok("".into())
}
