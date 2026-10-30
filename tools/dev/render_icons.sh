#!/usr/bin/env bash
# Renders the app icon masters in packages/design/brand/png from coin.svg
# with headless Chrome, which draws the gradients, the blur and the Manrope
# letter the same way on every run. Run it after a change to coin.svg, then
# `make icons`. CHROME points to another Chrome binary; PORT picks the port
# of the local server that serves the SVG and the font.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$root/packages/design/brand/png"
chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port="${PORT:-8765}"
profile="$(mktemp -d)"

if [ ! -x "$chrome" ]; then
  echo "Chrome not found at $chrome. Set CHROME to its binary." >&2
  exit 1
fi

python3 -m http.server "$port" --bind 127.0.0.1 \
  --directory "$root/packages/design" >/dev/null 2>&1 &
server=$!
cleanup() {
  kill "$server" 2>/dev/null || true
  wait "$server" 2>/dev/null || true
  rm -rf "$profile"
}
trap cleanup EXIT
until curl -fs -o /dev/null "http://127.0.0.1:$port/brand/coin.svg"; do
  sleep 0.2
done

# render <variant> <size> <file>
render() {
  "$chrome" --headless=new --user-data-dir="$profile" --no-first-run \
    --no-default-browser-check --disable-extensions --hide-scrollbars \
    --default-background-color=00000000 --force-device-scale-factor=1 \
    --window-size="$2,$2" --virtual-time-budget=10000 \
    --screenshot="$out/$3" \
    "http://127.0.0.1:$port/brand/render.html?variant=$1" >/dev/null 2>&1
}

mkdir -p "$out"
render ios 1024 icon.png
render dark 1024 icon-dark.png
render foreground 1024 icon-foreground.png
render background 1024 icon-background.png
render monochrome 1024 icon-monochrome.png
render macos 1024 icon-macos.png
render launch 1024 launch.png
# Android 12 shows its launch icon in a circle of 768 out of 1152 pixels.
render launch-android-12 1152 launch-android-12.png
echo "Rendered the icon masters into packages/design/brand/png."
