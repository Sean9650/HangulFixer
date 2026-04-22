#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="HangulFixer"
APP_DIR="$ROOT/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SDK_PATH="$(xcrun --show-sdk-path --sdk macosx)"
ICON_SOURCE="$ROOT/icon.png"
ICONSET_DIR="$ROOT/AppIcon.iconset"
ICON_PREVIEW="$ROOT/AppIconPreview.png"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc \
  -parse-as-library \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework UniformTypeIdentifiers \
  "$ROOT/Sources/HangulFixer.swift" \
  -o "$MACOS_DIR/$APP_NAME"

cp "$ROOT/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT/Resources/zip_utf8.py" "$RESOURCES_DIR/zip_utf8.py"

python3 - <<'PY' "$ICON_SOURCE" "$ICON_PREVIEW"
from PIL import Image, ImageDraw, ImageOps
from pathlib import Path
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

image = Image.open(src).convert("RGBA")
rgb = image.convert("RGB")
width, height = image.size

threshold = 245
min_x, min_y = width, height
max_x, max_y = 0, 0
found = False

for y in range(height):
    for x in range(width):
        r, g, b = rgb.getpixel((x, y))
        if not (r >= threshold and g >= threshold and b >= threshold):
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            found = True

if found:
    padding = 24
    crop_box = (
        max(min_x - padding, 0),
        max(min_y - padding, 0),
        min(max_x + padding + 1, width),
        min(max_y + padding + 1, height),
    )
    image = image.crop(crop_box)

canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
fitted = ImageOps.fit(image, (1024, 1024), method=Image.Resampling.LANCZOS)

mask = Image.new("L", (1024, 1024), 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle((0, 0, 1023, 1023), radius=230, fill=255)
fitted.putalpha(mask)
fitted.save(dst)
PY

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

sips -z 16 16 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_PREVIEW" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_PREVIEW" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"
cp "$ICON_PREVIEW" "$RESOURCES_DIR/AppIconPreview.png"

echo "Built: $APP_DIR"
