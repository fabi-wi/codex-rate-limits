<img width="1672" height="941" alt="ChatGPT Image 5  Mai 2026, 19_54_07" src="https://github.com/user-attachments/assets/2906e35c-8b6c-481e-9c7c-3b6d23c2e9fe" />

# Codex Rate Limits

Unofficial macOS menu-bar companion for keeping Codex rate limits visible while you work in the current ChatGPT desktop app or the legacy Codex app.

The app shows every active usage window returned for your account. Depending on the current plan and rollout, that can be a weekly window only, a 5-hour and weekly pair, or additional window durations in the future.

Up to three windows are visualized as concentric indicators. All returned windows are listed with their remaining percentage and reset timing in the popover.

It reads the same live Codex usage data used by the ChatGPT desktop app's Codex experience, then displays the remaining percentage and reset timing in a small translucent macOS popover.

## Install

### Homebrew

```bash
brew install --cask fabi-wi/tap/codex-rate-limits
```

After installing, open **Codex Rate Limits** from Applications or Spotlight.

### Manual Download

1. Download the latest `CodexRateLimits-vX.Y.Z-macos-arm64.zip` from [Releases](https://github.com/fabi-wi/codex-rate-limits/releases).
2. Unzip it.
3. Move `CodexRateLimits.app` to your `Applications` folder.
4. Open the app.

The app lives only in the macOS menu bar. It does not show a Dock icon.

If macOS blocks first launch because the app is not notarized yet, right-click `CodexRateLimits.app` and choose **Open**.

## Requirements

- macOS 14 or newer
- Apple Silicon Mac for the prebuilt Homebrew and release downloads
- ChatGPT desktop app with Codex installed (the legacy standalone Codex app is also supported)
- Codex signed in with your ChatGPT account
- Local Codex auth file at `~/.codex/auth.json`

No personal project path or manual data file is required for normal use.

## How It Works

Codex Rate Limits reads the local Codex auth file shared by the ChatGPT desktop app, Codex CLI, and legacy Codex app, then calls:

```text
https://chatgpt.com/backend-api/wham/usage
```

It discovers the non-null `*_window` entries in the live response and uses each entry's `limit_window_seconds` value to label and order the windows. The UI does not require both a 5-hour and a weekly window, and new durations such as a monthly window can be displayed without changing the data model.

The app polls every 30 seconds and refreshes immediately when you open the popover.

[OpenAI documents](https://help.openai.com/en/articles/11369540-using-codex-with-chatgpt) these as Codex/agentic usage associated with your ChatGPT plan. They are separate from unrelated ChatGPT limits such as file uploads, images, and voice.

## Privacy

The app uses your Codex access token in memory only to request your rate-limit usage. It does not log, print, upload, or store tokens.

See [SECURITY.md](SECURITY.md) for details.

## Build From Source

You can clone the repo anywhere:

```bash
git clone https://github.com/fabi-wi/codex-rate-limits.git
cd codex-rate-limits
./scripts/run.sh
```

To build a local app bundle:

```bash
./scripts/build_app.sh
open .build/release/CodexRateLimits.app
```

To work in Xcode:

```bash
open Package.swift
```

Select the `CodexRateLimitsApp` scheme and run it.

## Automatic Opening With ChatGPT or Codex

The downloadable app works as soon as you open it.

If you are building from source and want the companion to open automatically when the current ChatGPT desktop app (or the legacy Codex app) is running, install the optional local LaunchAgent:

```bash
./scripts/install-codex-launcher.sh
```

Remove it later with:

```bash
./scripts/uninstall-codex-launcher.sh
```

Remove it and quit the menu-bar app:

```bash
./scripts/uninstall-codex-launcher.sh --quit-app
```

## Local Test Data

Live Codex usage is the default. For development or demos, you can run against a local JSON file:

```bash
CODEX_RATE_LIMITS_SOURCE=local ./scripts/run.sh
```

The default local file inside your checkout is:

```text
Data/ratelimits.json
```

Update it with:

```bash
./scripts/update-data.sh 62000 200000 16500 50000
```

Arguments are for the legacy two-window sample format:

```text
WEEK_USED WEEK_LIMIT FIVE_HOUR_USED FIVE_HOUR_LIMIT
```

You can also choose any JSON file:

```bash
CODEX_RATE_LIMITS_SOURCE=local CODEX_RATE_LIMITS_FILE=/path/to/ratelimits.json ./scripts/run.sh
```

## Local JSON Schema

The expandable schema accepts any number of windows:

```json
{
  "limits": [
    {
      "durationSeconds": 604800,
      "metric": {
        "used": 4,
        "limit": 100,
        "resetAt": "2026-07-20T09:00:00Z"
      }
    }
  ],
  "updatedAt": "2026-07-13T09:00:00Z"
}
```

The original two-window schema remains supported for local development:

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
scripts/         Run, app-bundle build, release, and launcher helpers
Data/            Editable local rate-limit JSON source for development
```

## Tests

```bash
swift test
```

## Release Packaging

```bash
./scripts/package_release.sh 0.2.0
```

Publish a release after authenticating GitHub CLI:

```bash
gh auth login
./scripts/publish_release.sh 0.2.0
```

## License

MIT
