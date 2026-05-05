#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_FILE="${CODEX_RATE_LIMITS_FILE:-"$ROOT_DIR/Data/ratelimits.json"}"

if [[ ! -f "$DATA_FILE" ]]; then
  mkdir -p "$(dirname "$DATA_FILE")"
  cp "$ROOT_DIR/App/Resources/ratelimits.sample.json" "$DATA_FILE"
fi

export CODEX_RATE_LIMITS_FILE="$DATA_FILE"
cd "$ROOT_DIR"

swift run CodexRateLimitsApp
