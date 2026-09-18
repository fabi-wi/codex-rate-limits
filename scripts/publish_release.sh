#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
VERSION="${1:-$APP_VERSION}"
OWNER="${GITHUB_OWNER:-fabi-wi}"
REPO="${GITHUB_REPO:-codex-rate-limits}"
RELEASE_NOTES="$ROOT_DIR/docs/releases/v$VERSION.md"
ZIP="$ROOT_DIR/dist/CodexRateLimits-v$VERSION-macos-arm64.zip"
CHECKSUM="$ZIP.sha256"

cd "$ROOT_DIR"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || "$VERSION" != "$APP_VERSION" ]]; then
  echo "Release version must match Info.plist ($APP_VERSION)." >&2
  exit 1
fi
if [[ ! -f "$RELEASE_NOTES" ]]; then
  echo "Missing release notes: $RELEASE_NOTES" >&2
  exit 1
fi
if [[ "$(git branch --show-current)" != "main" || -n "$(git status --porcelain)" ]]; then
  echo "Publish from a clean, committed main branch." >&2
  exit 1
fi
if git rev-parse --verify "refs/tags/v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists; refusing to reuse it." >&2
  exit 1
fi

gh auth status >/dev/null 2>&1
gh repo view "$OWNER/$REPO" >/dev/null
EXPECTED_REMOTE="$(gh repo view "$OWNER/$REPO" --json url --jq .url)"
ACTUAL_REMOTE="$(git remote get-url origin)"
if [[ "$ACTUAL_REMOTE" != "$EXPECTED_REMOTE.git" && "$ACTUAL_REMOTE" != "$EXPECTED_REMOTE" && "$ACTUAL_REMOTE" != "git@github.com:$OWNER/$REPO.git" ]]; then
  echo "Origin does not match the release repository." >&2
  exit 1
fi
git fetch origin main --tags
git merge-base --is-ancestor origin/main HEAD
if git rev-parse --verify "refs/tags/v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists on origin." >&2
  exit 1
fi

# Always rebuild from the reviewed commit; never reuse an old archive.
./scripts/package_release.sh "$VERSION"
git push origin HEAD:main
git tag -a "v$VERSION" -m "Codex Rate Limits $VERSION"
git push origin "v$VERSION"
gh release create "v$VERSION" "$ZIP" "$CHECKSUM" \
  --repo "$OWNER/$REPO" --verify-tag \
  --title "Codex Rate Limits $VERSION" --notes-file "$RELEASE_NOTES"

echo "Published: https://github.com/$OWNER/$REPO/releases/tag/v$VERSION"
