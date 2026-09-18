#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
VERSION="${1:-$APP_VERSION}"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_NAME="CodexRateLimits-v$VERSION-macos-arm64.zip"

cd "$ROOT_DIR"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || "$VERSION" != "$APP_VERSION" ]]; then
  echo "Release version must match Info.plist ($APP_VERSION)." >&2
  exit 1
fi

swift test
./scripts/build_app.sh
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$BIN_DIR/CodexRateLimits.app"

if [[ "$(lipo -archs "$APP_DIR/Contents/MacOS/CodexRateLimits")" != "arm64" ]]; then
  echo "The release archive requires an arm64 build." >&2
  exit 1
fi

./scripts/smoke_test_app.sh "$APP_DIR" "$BIN_DIR"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
  codesign --verify --deep --strict "$APP_DIR"
fi

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$ARCHIVE_NAME" "$DIST_DIR/$ARCHIVE_NAME.sha256"

COPYFILE_DISABLE=1 ditto --norsrc --noextattr -c -k --keepParent "$APP_DIR" "$DIST_DIR/$ARCHIVE_NAME"
unzip -tq "$DIST_DIR/$ARCHIVE_NAME"
(
  cd "$DIST_DIR"
  shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
)

echo "Release assets:"
echo "$DIST_DIR/$ARCHIVE_NAME"
echo "$DIST_DIR/$ARCHIVE_NAME.sha256"
