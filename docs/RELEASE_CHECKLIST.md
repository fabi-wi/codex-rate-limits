# Release Checklist

1. Update `CHANGELOG.md`, `docs/releases/vX.Y.Z.md`, and `Resources/Info.plist`.
2. Run `swift test`.
3. Run `./scripts/build_app.sh`.
4. Run `./scripts/package_release.sh X.Y.Z`.
5. Install the generated app locally and verify live Codex usage updates.
6. Commit the release changes.
7. Tag and publish with `./scripts/publish_release.sh X.Y.Z`.
8. Verify the GitHub release title, notes, zip asset, and checksum.
