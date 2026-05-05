#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${CODEX_RATE_LIMITS_APP_BUNDLE:-"$ROOT_DIR/.build/release/CodexRateLimits.app"}"
DATA_FILE="${CODEX_RATE_LIMITS_FILE:-"$ROOT_DIR/Data/ratelimits.json"}"
CODEX_MATCH_PATTERN="${CODEX_APP_MATCH_PATTERN:-/Applications/Codex.app/}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  APP_BUNDLE="$ROOT_DIR/.build/arm64-apple-macosx/release/CodexRateLimits.app"
fi

APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/CodexRateLimits"

if ! pgrep -if "$CODEX_MATCH_PATTERN" >/dev/null; then
  exit 0
fi

if [[ ! -x "$APP_EXECUTABLE" ]]; then
  echo "CodexRateLimits app executable not found at $APP_EXECUTABLE" >&2
  exit 1
fi

if pgrep -if "$APP_EXECUTABLE" >/dev/null; then
  exit 0
fi

open -g "$APP_BUNDLE" --args --data-file "$DATA_FILE"
