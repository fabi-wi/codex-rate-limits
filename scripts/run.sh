#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${CODEX_RATE_LIMITS_SOURCE:-codex}"
DATA_FILE="${CODEX_RATE_LIMITS_FILE:-"$ROOT_DIR/Data/ratelimits.json"}"
ARGS=(--source "$SOURCE")

if [[ "$SOURCE" == "local" && ! -f "$DATA_FILE" ]]; then
  mkdir -p "$(dirname "$DATA_FILE")"
  cp "$ROOT_DIR/App/Resources/ratelimits.sample.json" "$DATA_FILE"
fi

if [[ "$SOURCE" == "local" ]]; then
  ARGS+=(--data-file "$DATA_FILE")
fi

cd "$ROOT_DIR"

swift run CodexRateLimitsApp "${ARGS[@]}"
