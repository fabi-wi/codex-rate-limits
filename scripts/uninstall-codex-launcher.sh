#!/usr/bin/env bash
set -euo pipefail

LABEL="local.codex-rate-limits.watcher"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
USER_DOMAIN="gui/$(id -u)"

launchctl bootout "$USER_DOMAIN" "$PLIST" 2>/dev/null || true
rm -f "$PLIST"

echo "Removed $LABEL"

if [[ "${1:-}" == "--quit-app" ]]; then
  pkill -if "CodexRateLimits.app/Contents/MacOS/CodexRateLimits" 2>/dev/null || true
  echo "Quit Codex Rate Limits if it was running."
fi
