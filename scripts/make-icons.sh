#!/bin/sh
# Regenerates assets/AppIcon.icns from assets/app-icon-macos.svg.
# Requires librsvg (brew install librsvg); iconutil ships with macOS.
set -eu

cd "$(dirname "$0")/.."

command -v rsvg-convert >/dev/null 2>&1 || {
    echo "rsvg-convert not found. Install it with: brew install librsvg" >&2
    exit 1
}

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"

for size in 16 32 128 256 512; do
    double=$((size * 2))
    rsvg-convert -w "$size" -h "$size" assets/app-icon-macos.svg -o "$ICONSET/icon_${size}x${size}.png"
    rsvg-convert -w "$double" -h "$double" assets/app-icon-macos.svg -o "$ICONSET/icon_${size}x${size}@2x.png"
done

iconutil -c icns "$ICONSET" -o assets/AppIcon.icns
echo "Wrote assets/AppIcon.icns"
