# Exit this script if any command fails
set -e

wasm-pack build --dev --no-typescript --target no-modules --out-dir static --out-name wasm font-editor
rm font-editor/static/.gitignore
rm font-editor/static/package.json

cargo run --profile dev --package backend
