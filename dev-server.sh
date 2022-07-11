# Exit this script if any command fails
set -e

wasm-pack build --dev --no-typescript --target no-modules --out-dir static/target --out-name wasm frontend

cargo run --profile dev --package backend
