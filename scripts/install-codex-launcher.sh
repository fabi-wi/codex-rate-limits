#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="local.codex-rate-limits.watcher"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/CodexRateLimits"
USER_DOMAIN="gui/$(id -u)"

cd "$ROOT_DIR"
./scripts/build_app.sh

mkdir -p "$(dirname "$PLIST")" "$LOG_DIR"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ROOT_DIR/scripts/codex-app-watcher.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/watcher.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/watcher-error.log</string>
</dict>
</plist>
PLIST

launchctl bootout "$USER_DOMAIN" "$PLIST" 2>/dev/null || true
launchctl bootstrap "$USER_DOMAIN" "$PLIST"
launchctl enable "$USER_DOMAIN/$LABEL"
launchctl kickstart -k "$USER_DOMAIN/$LABEL"

echo "Installed $LABEL"
echo "LaunchAgent: $PLIST"
echo "The Codex Rate Limits app will open automatically when /Applications/Codex.app is running."
