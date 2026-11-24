# AGENTS.md — rules for AI agents working on Kage Loop (shadow-player)

Kage Loop is an iOS shadowing app (SwiftUI + AVPlayer) with local Swift packages in `Packages/`.
Build and test commands are in [CLAUDE.md](CLAUDE.md). These rules apply to every agent: Claude
sessions on the Mac, Claude cloud sessions, and the Grok bot that dispatches work to them.

## Who works where

| Channel | Runs on | Can do |
|---|---|---|
| Yang on the Mac (`~/Code/shadow-player`) | Mac | everything: build, test, install on the iPhone |
| Yang on the Claude phone app, cloud session | Linux cloud container | edit code, push a branch, open a PR |
| Grok bot → `claude --remote "…"` | Linux cloud container | same as above; the session shows up in Yang's Claude app |
| Yang on the phone → Remote Control `shadow-player` | Mac | everything, while the Mac is on |

Cloud containers have **no Xcode**: no `xcodebuild`, no `scripts/install-device.sh`, and `swift test`
probably fails for packages that import Apple frameworks. Building and device testing happen on the Mac.

## Rules
- **GitHub is the single source of truth.** Work that isn't pushed doesn't exist. Push your branch before you stop.
- **Branches:** `develop` is the default branch. Work on `feature/…`, `fix/…`, `docs/…`, `claude/…` or `codex/…`
  and open a PR into `develop`. Never commit straight to `develop` or `master`.
- **Never merge a PR without Yang's explicit approval.** Don't delete branches, change secrets, or change the default branch.
- **Every push to `develop` uploads a TestFlight build** (`.github/workflows/testflight.yml`; docs-only pushes are skipped).
  Uploading never submits for review.
- **`master` only holds versions already live on the App Store.**
- **App Store review** goes through the `Submit for review` workflow (manual, `confirm=SUBMIT`). Only run it when
  Yang says so after testing the build in TestFlight.
- Release notes for each version live in `submissions/<version>/` (see `submissions/README.md`).
- Secrets live only in GitHub Secrets. Never commit keys, certificates, or personal data.

## Checks before a PR is ready
- On the Mac:
  - `cd Packages/PhraseKit && swift test` and `cd Packages/PracticeKit && swift test`
  - `xcodebuild build -project ShadowPlayer.xcodeproj -scheme ShadowPlayer -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet`
- In a cloud session: these can't run. Say so in the PR description and in the final message, and list what Yang
  should test on the device.
- Device-only behaviour (speech recognition, background audio, Picture in Picture, rotation) is confirmed only by
  Yang's manual test.

## Release flow (Yang's standard)
- `develop` is where work is integrated and tested. `master` always equals the version live on the App Store.
- Every change goes `feature/*` / `claude/*` / `codex/*` → PR into `develop`. Pushes to `develop` upload a TestFlight build.
- Yang verifies the build in TestFlight, then says "推送 App Store". Only then submit for review.
- After Apple approves and the app is live, merge `develop` into `master` and tag `vX.Y.Z`. No release branches.
- Urgent fix for live users: `hotfix/*` from `master` → PR into `master`, tag, then merge back into `develop`.

## Grok bot: how to dispatch work

The Grok bot does not edit code itself. It starts Claude cloud sessions from its own computer, logged in to
Yang's Claude account, inside a clone of this repository:

```bash
claude --remote "<task>"
```

- **One task per session.** Split unrelated requests into separate sessions.
- **Write the task so it stands alone.** Include: the goal, the files or screen involved, what "done" looks like,
  and this line: *"Follow AGENTS.md: work on a new branch, push it, open a PR into develop, don't merge."*
- **Don't ask a session to** merge, tag, push to `develop`/`master`, run `Submit for review`, or touch secrets.
  These need Yang's explicit go-ahead, given by Yang directly, not relayed from another message.
- **Report back to Yang** with the PR link, a one-line summary, and what needs a device test.
- If a task needs a real iPhone (audio, speech recognition, PiP, rotation), tell Yang it must be checked on the Mac
  (`git fetch origin && git switch <branch>`, then `scripts/install-device.sh <UDID>`), or via Remote Control.
