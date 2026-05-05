# Codex Rate Limits

Clean macOS menu-bar app for tracking two Codex rate limits:

- Week Limit
- 5 Hour Limit

The status item uses two concentric circular indicators. The outer circle is the Week Limit, and the inner circle is the 5 Hour Limit. The popover shows the same rings at a larger size, plus exact remaining and used values.

The popover uses a native macOS translucent material with a restrained liquid-glass color treatment inspired by polished health-tracking menu panels.

## Requirements

- macOS 14 or newer
- Xcode command line tools or Xcode
- Swift 6 compatible toolchain

## Run Locally

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
./scripts/run.sh
```

The app runs as an accessory/menu-bar app. It does not show a Dock icon.

To work in Xcode:

```bash
open Package.swift
```

Select the `CodexRateLimitsApp` scheme and run it.

## Update the Local Data Source

The default local data source is:

```text
/Users/admin/Developer/my_projects/codex-rate-limits/Data/ratelimits.json
```

The app polls this file every 2 seconds and updates the rings when the file changes.

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

macOS then runs a lightweight watcher every 10 seconds. When `/Applications/Codex.app` is running, the watcher opens `CodexRateLimits.app` and passes the repo data file with `--data-file`.

Remove the automatic launcher:

```bash
./scripts/uninstall-codex-launcher.sh
```

Remove it and quit the menu-bar app:

```bash
./scripts/uninstall-codex-launcher.sh --quit-app
```

## Data Schema

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
    Data/        Provider protocol and local JSON provider
    Models/      Rate-limit snapshot and metric types
    Utils/       JSON/date/number formatting helpers
Tests/           Core parsing and provider tests
scripts/         Run, app-bundle build, and data-update helpers
Data/            Editable local rate-limit JSON source
```

## Data Flow

`LocalJSONRateLimitProvider` reads the configured JSON file, decodes it into `RateLimitSnapshot`, and emits changes to `RateLimitStore`. The status bar item and SwiftUI popover observe the store. UI updates animate automatically when the Week Limit or 5 Hour Limit changes.

## Extension Points

- Replace `LocalJSONRateLimitProvider` with another `RateLimitProviding` implementation for a real Codex source.
- Keep the UI unchanged by continuing to publish `RateLimitSnapshot`.
- Use `CODEX_RATE_LIMITS_FILE` for a scraper, CLI, or background job that writes local JSON without adding network dependencies to the app.

## Tests

```bash
cd /Users/admin/Developer/my_projects/codex-rate-limits
swift test
```

## Release Packaging

Build a signed local release archive and checksum:

```bash
./scripts/package_release.sh 0.1.0
```

Publish to GitHub after authenticating `gh`:

```bash
gh auth login
./scripts/publish_release.sh 0.1.0
```

By default this publishes to:

```text
https://github.com/fabi-wi/codex-rate-limits
```
