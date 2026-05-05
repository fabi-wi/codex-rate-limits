# Codex Rate Limits

Clean macOS menu-bar app for tracking two Codex rate limits:

- Week Limit
- 5 Hour Limit

The status item uses two concentric circular indicators. The outer circle is the Week Limit, and the inner circle is the 5 Hour Limit. The popover shows the same rings at a larger size, plus remaining percentage, used percentage, and reset timing.

The popover uses a native macOS translucent material, so the background naturally changes with whatever is behind the window.

This is an unofficial open-source companion app. It is not affiliated with OpenAI.

## Requirements

- macOS 14 or newer
- Xcode command line tools or Xcode
- Swift 6 compatible toolchain
- Codex signed in with ChatGPT, with `~/.codex/auth.json` present

## Run Locally

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
./scripts/run.sh
```

The app runs as an accessory/menu-bar app. It does not show a Dock icon.

By default it reads the same ChatGPT/Codex usage endpoint used by the Codex app. It reloads the local Codex auth file before each request, so refreshed Codex tokens are picked up automatically.

To work in Xcode:

```bash
open Package.swift
```

Select the `CodexRateLimitsApp` scheme and run it.

## Install From Release

Download the latest `CodexRateLimits-vX.Y.Z-macos-arm64.zip` asset from GitHub Releases, unzip it, and open `CodexRateLimits.app`.

The app is not notarized yet. If macOS blocks first launch, right-click the app and choose **Open**.

## Live Data Source

The default source is live Codex usage:

```text
~/.codex/auth.json -> https://chatgpt.com/backend-api/wham/usage
```

The app polls every 30 seconds, refreshes immediately when the popover opens, and maps Codex's `used_percent` windows like this:

- `limit_window_seconds` near `18000` -> 5 Hour Limit
- `limit_window_seconds` near `604800` -> Week Limit

Force a different auth file if needed:

```bash
CODEX_AUTH_FILE=/absolute/path/to/auth.json ./scripts/run.sh
```

## Privacy

The app reads `~/.codex/auth.json` locally and uses the access token in memory to request usage data from `https://chatgpt.com/backend-api/wham/usage`. It does not log, print, upload, or store tokens. See `SECURITY.md` for the short security note.

## Local Test Data

The bundled JSON source is still available for local testing:

```bash
CODEX_RATE_LIMITS_SOURCE=local ./scripts/run.sh
```

The local data file is:

```text
/Users/admin/Developer/my_projects/codex-rate-limits/Data/ratelimits.json
```

In local mode, the app reads this file every second and updates the rings when the values change.

Use the helper script:

```bash
./scripts/update-data.sh 62000 200000 16500 50000
```

Arguments are:

```text
WEEK_USED WEEK_LIMIT FIVE_HOUR_USED FIVE_HOUR_LIMIT
```

You can also point the app at another JSON file:

```bash
CODEX_RATE_LIMITS_FILE=/absolute/path/to/ratelimits.json ./scripts/run.sh
```

## Build an App Bundle

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
./scripts/build_app.sh
open .build/release/CodexRateLimits.app
```

The generated bundle uses `LSUIElement`, so it stays in the menu bar without a Dock icon.

## Open Automatically With Codex

Install the local LaunchAgent:

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
./scripts/install-codex-launcher.sh
```

This builds the app bundle and installs:

```text
~/Library/LaunchAgents/local.codex-rate-limits.watcher.plist
```

macOS then runs a lightweight watcher every 10 seconds. When `/Applications/Codex.app` is running, the watcher opens `CodexRateLimits.app` in live Codex mode.

When Codex quits, the app closes itself and the watcher also cleans up any remaining companion process. If you close the companion from its top-right close button while Codex is still running, it stays closed for that Codex session.

Remove the automatic launcher:

```bash
./scripts/uninstall-codex-launcher.sh
```

Remove it and quit the menu-bar app:

```bash
./scripts/uninstall-codex-launcher.sh --quit-app
```

## Local JSON Schema

```json
{
  "weekLimit": {
    "label": "Week Limit",
    "used": 62000,
    "limit": 200000,
    "resetAt": "2026-05-11T00:00:00Z"
  },
  "fiveHourLimit": {
    "label": "5 Hour Limit",
    "used": 16500,
    "limit": 50000,
    "resetAt": "2026-05-05T18:00:00Z"
  },
  "updatedAt": "2026-05-05T14:23:00Z"
}
```

Each metric may also be supplied as `remaining` plus `limit`, or as `percentRemaining` / `percentageRemaining`.

## Project Structure

```text
App/
  AppKit/        Menu-bar status item and rendered status icon
  Data/          App configuration and observable store
  Resources/     Bundled starter JSON
  Views/         SwiftUI popover and circular indicators
Resources/       App-bundle Info.plist
Sources/
  CodexRateLimitsCore/
    Data/        Provider protocol, Codex usage provider, and local JSON provider
    Models/      Rate-limit snapshot and metric types
    Utils/       JSON/date/number formatting helpers
Tests/           Core parsing and provider tests
scripts/         Run, app-bundle build, and data-update helpers
Data/            Editable local rate-limit JSON source
```

## Data Flow

`CodexUsageRateLimitProvider` reads `~/.codex/auth.json`, calls the Codex usage endpoint, maps the 5-hour and weekly windows into `RateLimitSnapshot`, and emits changes to `RateLimitStore`. The status bar item and SwiftUI popover observe the store. UI updates animate automatically when the Week Limit or 5 Hour Limit changes.

## Extension Points

- Keep the UI unchanged by continuing to publish `RateLimitSnapshot`.
- Use `CODEX_RATE_LIMITS_SOURCE=local` for JSON-driven testing or demos.
- Adjust `CodexUsageRateLimitProvider` if Codex changes the usage endpoint shape in a future app release.

## Tests

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
swift test
```

## Release Packaging

Build a signed local release archive and checksum:

```bash
./scripts/package_release.sh 0.2.0
```

Publish to GitHub after authenticating `gh`:

```bash
gh auth login
./scripts/publish_release.sh 0.2.0
```

By default this publishes to:

```text
https://github.com/fabi-wi/codex-rate-limits
```
