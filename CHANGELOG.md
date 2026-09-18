# Changelog

## 0.2.3 - 2026-09-18

Maintenance and reliability release.

- Fixed bundled sample loading after installing the app outside its build directory.
- Avoided creating demo data when using live Codex usage.
- Coalesced overlapping refresh requests, added a request timeout, and cancelled pending requests when stopping.
- Made failed refreshes visible in the menu bar and labelled retained readings with their last update time.
- Rejected missing usage values and empty local window lists instead of displaying misleading availability.
- Integrated the detailed reset countdown with flexible usage windows.
- Added request lifecycle tests and an installation smoke test to release packaging.
- Updated and pinned GitHub Actions; CI now produces verified release archives.
- Required matching release versions and a clean, committed main branch for publishing.

## 0.2.2 - 2026-07-13

Flexible usage-window release.

- Fixed live usage loading when OpenAI returns a weekly window without a 5-hour window.
- Replaced the fixed weekly/5-hour data model with an ordered collection of available windows.
- Added automatic labels for hourly, daily, weekly, and monthly window durations.
- Made the menu-bar rings, tooltip, popover rows, and popover height adapt to the returned windows.
- Preserved compatibility with the original local JSON schema.

## 0.2.1 - 2026-07-10

ChatGPT desktop compatibility release.

- Added automatic companion launch for the current `/Applications/ChatGPT.app` host.
- Preserved automatic launch support for legacy `/Applications/Codex.app` installations.
- Updated host termination and session-level close suppression for both desktop app names.
- Clarified that the displayed limits are Codex/agentic usage windows associated with the user's ChatGPT plan.

## 0.2.0 - 2026-05-05

Release-ready live Codex version.

- Added live Codex usage polling from the same rate-limit endpoint used by the Codex desktop app.
- Added automatic token refresh pickup by rereading `~/.codex/auth.json` before each request.
- Added a top-right close button and session-level companion launch suppression.
- Added automatic app termination when Codex quits.
- Removed footer status text from the popover.
- Simplified the glass background to native macOS material without a synthetic color overlay.
- Added CI, security notes, MIT license, and release checklist for open-source distribution.

## 0.1.0 - 2026-05-05

Initial public release of Codex Rate Limits.

- Added a macOS menu-bar app for Week Limit and 5 Hour Limit tracking.
- Added two concentric circular indicators in the status item and popover.
- Added a translucent liquid-glass popover background using native macOS visual effects.
- Added local JSON polling with a clean provider protocol for future data sources.
- Added automatic launch support when Codex.app is running.
- Added release packaging scripts, tests, and documentation.
