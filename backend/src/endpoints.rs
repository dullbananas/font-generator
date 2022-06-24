use crate::state::{State};
use crate::util::{Error as E};
use typed_html::{html, text};

type Request = tide::Request<State>;

pub fn init(server: &mut tide::Server<State>) -> Result<(), E> {
    server.at("/font-editor/").get(font_editor);
    server.at("/font-editor").serve_dir("font-editor/static")?;

    server.at("/shared").serve_dir("static")?;

    Ok(())
}

async fn font_editor(_req: Request) -> tide::Result {
    Ok(page(
        "Font Editor",
        html!(
            <div>
                <p id="status">"Loading"</p>
                <div id="thumbnails"></div>
            </div>
        ),
    ))
}

fn page(title: &'static str, content: Box<typed_html::elements::div<String>>) -> tide::Response {
    let mut response: tide::Response = format!(
        "<!DOCTYPE html>{}",
        html!(
            <html>
                <head>
                    <title>{text!(title)}</title>
                    <link rel="stylesheet" href="/shared/style.css"/>
                    <link rel="stylesheet" href="style.css"/>
                </head>
                <body>
                    {content.children}
                    <script src="imports.js"></script>
                    <script src="wasm.js"></script>
                    <script src="init.js"></script>
                </body>
            </html>
        ),
    ).into();
    response.set_content_type("text/html");
    response
}
