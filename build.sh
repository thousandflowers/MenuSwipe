#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/MenuSwipe.app"

swift build -c release --package-path "$ROOT"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/MenuSwipe" "$APP/Contents/MacOS/MenuSwipe"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

# Ad-hoc sign so the Accessibility grant sticks to a stable identity.
codesign --force --sign - "$APP"

echo "Built $APP"
