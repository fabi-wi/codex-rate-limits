#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${CODEX_RATE_LIMITS_APP_BUNDLE:-"$ROOT_DIR/.build/release/CodexRateLimits.app"}"
SOURCE="${CODEX_RATE_LIMITS_SOURCE:-codex}"
DATA_FILE="${CODEX_RATE_LIMITS_FILE:-"$ROOT_DIR/Data/ratelimits.json"}"
AUTH_FILE="${CODEX_AUTH_FILE:-"$HOME/.codex/auth.json"}"
CODEX_MATCH_PATTERN="${CODEX_APP_MATCH_PATTERN:-/Applications/Codex.app/}"
CODEX_MAIN_PATTERN="/Applications/Codex.app/Contents/MacOS/Codex"
APP_PROCESS_PATTERN="CodexRateLimits.app/Contents/MacOS/CodexRateLimits"
SUPPRESS_FILE="${CODEX_RATE_LIMITS_SUPPRESS_FILE:-"$HOME/Library/Application Support/CodexRateLimits/launch-suppressed-codex.pid"}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  APP_BUNDLE="$ROOT_DIR/.build/arm64-apple-macosx/release/CodexRateLimits.app"
fi

APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/CodexRateLimits"
CODEX_PID="$(
  ps -axo pid=,args= \
    | grep -F "$CODEX_MAIN_PATTERN" \
    | grep -Fv "grep" \
    | awk 'NR == 1 { print $1 }' \
    || true
)"

if [[ -z "$CODEX_PID" ]] || ! pgrep -if "$CODEX_MATCH_PATTERN" >/dev/null; then
  rm -f "$SUPPRESS_FILE"
  pkill -if "$APP_PROCESS_PATTERN" 2>/dev/null || true
  exit 0
fi

if [[ -f "$SUPPRESS_FILE" ]] && [[ "$(tr -d '[:space:]' < "$SUPPRESS_FILE")" == "$CODEX_PID" ]]; then
  exit 0
fi

if [[ ! -x "$APP_EXECUTABLE" ]]; then
  echo "CodexRateLimits app executable not found at $APP_EXECUTABLE" >&2
  exit 1
fi

if pgrep -if "$APP_PROCESS_PATTERN" >/dev/null; then
  exit 0
fi

ARGS=(--source "$SOURCE")

if [[ "$SOURCE" == "local" ]]; then
  ARGS+=(--data-file "$DATA_FILE")
else
  ARGS+=(--auth-file "$AUTH_FILE")
fi

open -g "$APP_BUNDLE" --args "${ARGS[@]}"
