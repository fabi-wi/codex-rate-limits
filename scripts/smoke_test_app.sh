#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:?Usage: smoke_test_app.sh APP_DIR BIN_DIR}"
BIN_DIR="${2:?Usage: smoke_test_app.sh APP_DIR BIN_DIR}"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-rate-limits-smoke.XXXXXX")"
RESOURCE_BUNDLE="$BIN_DIR/CodexRateLimits_CodexRateLimitsApp.bundle"
APP_PID=""

cleanup() {
  if [[ -n "$APP_PID" ]]; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  if [[ -d "$TEST_DIR/build-resources.bundle" ]]; then
    mv "$TEST_DIR/build-resources.bundle" "$RESOURCE_BUNDLE"
  fi
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

ditto "$APP_DIR" "$TEST_DIR/CodexRateLimits.app"

# A relocated app must work without SwiftPM's development resource fallback.
if [[ -d "$RESOURCE_BUNDLE" ]]; then
  mv "$RESOURCE_BUNDLE" "$TEST_DIR/build-resources.bundle"
fi

"$TEST_DIR/CodexRateLimits.app/Contents/MacOS/CodexRateLimits" \
  --source local --data-file "$TEST_DIR/fresh-data/ratelimits.json" \
  >"$TEST_DIR/app.log" 2>&1 &
APP_PID=$!

for _ in {1..30}; do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    cat "$TEST_DIR/app.log" >&2
    echo "Relocated app exited before loading its bundled sample." >&2
    exit 1
  fi
  if [[ -s "$TEST_DIR/fresh-data/ratelimits.json" ]]; then
    cmp "$TEST_DIR/fresh-data/ratelimits.json" "$(dirname "$0")/../App/Resources/ratelimits.sample.json"
    echo "Relocated app loaded bundled resources and created fresh local data."
    exit 0
  fi
  sleep 0.2
done

cat "$TEST_DIR/app.log" >&2
echo "Relocated app did not create local sample data." >&2
exit 1
