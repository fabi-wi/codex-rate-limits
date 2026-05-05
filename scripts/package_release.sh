#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$ROOT_DIR/.build/release/CodexRateLimits.app"
ARCHIVE_NAME="CodexRateLimits-v$VERSION-macos-arm64.zip"

cd "$ROOT_DIR"

swift test
./scripts/build_app.sh

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
fi

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$ARCHIVE_NAME" "$DIST_DIR/$ARCHIVE_NAME.sha256"

ditto -c -k --keepParent "$APP_DIR" "$DIST_DIR/$ARCHIVE_NAME"
(
  cd "$DIST_DIR"
  shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
)

echo "Release assets:"
echo "$DIST_DIR/$ARCHIVE_NAME"
echo "$DIST_DIR/$ARCHIVE_NAME.sha256"
