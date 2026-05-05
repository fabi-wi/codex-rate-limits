#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 WEEK_USED WEEK_LIMIT FIVE_HOUR_USED FIVE_HOUR_LIMIT" >&2
  exit 64
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_FILE="${CODEX_RATE_LIMITS_FILE:-"$ROOT_DIR/Data/ratelimits.json"}"
UPDATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
WEEK_RESET="$(date -u -v+7d +"%Y-%m-%dT%H:%M:%SZ")"
FIVE_HOUR_RESET="$(date -u -v+5H +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "$DATA_FILE")"

cat > "$DATA_FILE" <<JSON
{
  "fiveHourLimit": {
    "label": "5 Hour Limit",
    "limit": $4,
    "resetAt": "$FIVE_HOUR_RESET",
    "used": $3
  },
  "updatedAt": "$UPDATED_AT",
  "weekLimit": {
    "label": "Week Limit",
    "limit": $2,
    "resetAt": "$WEEK_RESET",
    "used": $1
  }
}
JSON

echo "Updated $DATA_FILE"
