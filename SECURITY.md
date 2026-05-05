# Security

Codex Rate Limits reads your local Codex ChatGPT auth file at `~/.codex/auth.json` so it can request the same rate-limit usage data shown by the Codex desktop app.

The app does not log, print, upload, or store your tokens. It uses the access token in memory for the request to `https://chatgpt.com/backend-api/wham/usage`.

Do not share:

- `~/.codex/auth.json`
- terminal output containing access tokens
- screenshots that expose personal account data

If you find a security issue, please open a private report through GitHub Security Advisories if available, or contact the repository owner directly.
