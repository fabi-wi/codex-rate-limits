#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
OWNER="${GITHUB_OWNER:-fabi-wi}"
REPO="${GITHUB_REPO:-codex-rate-limits}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE="https://github.com/$OWNER/$REPO.git"
RELEASE_NOTES="$ROOT_DIR/docs/releases/v$VERSION.md"
ZIP="$ROOT_DIR/dist/CodexRateLimits-v$VERSION-macos-arm64.zip"
CHECKSUM="$ZIP.sha256"

cd "$ROOT_DIR"

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

if [[ ! -f "$ZIP" || ! -f "$CHECKSUM" ]]; then
  ./scripts/package_release.sh "$VERSION"
fi

if ! gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  gh repo create "$OWNER/$REPO" \
    --public \
    --source "$ROOT_DIR" \
    --description "macOS menu-bar companion for Codex rate limits" \
    --remote origin
elif ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$REMOTE"
fi

git add .github .gitignore App Data Package.swift README.md Resources Sources Tests scripts CHANGELOG.md LICENSE SECURITY.md docs
git commit -m "Release Codex Rate Limits $VERSION" || true
git branch -M main
git push -u origin main

git tag -a "v$VERSION" -m "Codex Rate Limits $VERSION" || true
git push origin "v$VERSION"

gh release create "v$VERSION" \
  "$ZIP" \
  "$CHECKSUM" \
  --repo "$OWNER/$REPO" \
  --title "Codex Rate Limits $VERSION" \
  --notes-file "$RELEASE_NOTES"

echo "Published: https://github.com/$OWNER/$REPO/releases/tag/v$VERSION"
