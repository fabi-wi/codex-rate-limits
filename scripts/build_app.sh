#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$BIN_DIR/CodexRateLimits.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BIN_DIR/CodexRateLimitsApp" "$APP_DIR/Contents/MacOS/CodexRateLimits"

find "$BIN_DIR" -maxdepth 1 -name "*.bundle" -exec cp -R {} "$APP_DIR/Contents/Resources/" \;

echo "Built $APP_DIR"
