# ShadowPlayer

iOS app (SwiftUI + AVPlayer) plus local Swift packages: `Packages/PhraseKit` (looped speech → word-list
lines) and `Packages/PracticeKit` (daily check-in rules; design in `design/daily-checkin.md`).

## Workflow

Claude develops on this Mac; the user tests by hand on a USB-connected iPhone.

1. Work on a branch (never commit straight to `master`).
2. Make the change, then check it:
   - `cd Packages/PhraseKit && swift test` and `cd Packages/PracticeKit && swift test`
   - `xcodebuild build -project ShadowPlayer.xcodeproj -scheme ShadowPlayer -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet`
3. Install on the test phone: `scripts/install-device.sh` (builds Debug, installs and launches on the
   first connected iPhone; pass a UDID to pick one).
4. Tell the user what to try on the phone. Don't claim device-only behaviour (speech recognition,
   background audio, Picture in Picture, fullscreen rotation) works. Only the user's manual test confirms it.

If `swift test` fails with a stale module cache error, delete that package's `.build` and rerun.
