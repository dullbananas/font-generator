use crate::state::{State};

type Request = tide::Request<State>;

pub fn init(server: &mut tide::Server<State>) {
    server.at("/font/:id/test").get(test);
    server.at("/font/:id/edit").get(edit);
}

async fn test(req: Request) -> tide::Result {
    let id = req.param("id")?;
    Ok("".into())
}

async fn edit(req: Request) -> tide::Result {
    Ok("".into())
}
