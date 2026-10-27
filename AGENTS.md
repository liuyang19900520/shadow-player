# AGENTS.md — rules for AI agents working on Kage Loop (shadow-player)

Kage Loop is an iOS shadowing app (SwiftUI + AVPlayer) with local Swift packages in `Packages/`.
Project details and test commands are in [CLAUDE.md](CLAUDE.md); the current to-do list is in [PLAN.md](PLAN.md).

## Rules
- **GitHub is the single source of truth.** Work that isn't pushed doesn't exist. Push your branch before you stop.
- **Branches:** `develop` is the default branch. Work on `feature/…`, `fix/…`, `docs/…`, `claude/…` or `codex/…` and open a PR into `develop`.
- **Never merge a PR without Yang's explicit approval.** Don't delete branches, change secrets, or change the default branch.
- **Every push to `develop` uploads a TestFlight build** (`.github/workflows/testflight.yml`). Uploading never submits for review.
- **`master` only holds versions already live on the App Store.** After a release, `develop` is merged into `master` and tagged.
- **App Store review** goes through the `Submit for review` workflow (manual, `confirm=SUBMIT`). Only run it when Yang says so after testing the build in TestFlight.
- Release notes for each version live in `submissions/<version>/` (see `submissions/README.md`).
- Secrets live only in GitHub Secrets. Never commit keys or certificates.

## Checks before a PR is ready
- `cd Packages/PhraseKit && swift test` and `cd Packages/PracticeKit && swift test`
- `xcodebuild build -project ShadowPlayer.xcodeproj -scheme ShadowPlayer -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet`
- Device-only behaviour (speech recognition, background audio, Picture in Picture, rotation) is confirmed only by Yang's manual test.
