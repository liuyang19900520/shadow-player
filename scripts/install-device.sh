#!/usr/bin/env bash
# Build a Debug ShadowPlayer and install + launch it on a connected iPhone.
#
#   scripts/install-device.sh            # first connected iPhone
#   scripts/install-device.sh <udid>     # a specific device
set -euo pipefail

cd "$(dirname "$0")/.."

BUNDLE_ID=com.liuyang19900520.shadowplayer
DERIVED="${TMPDIR:-/tmp}/shadowplayer-device"
DEVICES_JSON="$(mktemp)"
trap 'rm -f "$DEVICES_JSON"' EXIT

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null
  DEVICE="$(python3 - "$DEVICES_JSON" <<'EOF'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
for d in devices:
    if d["hardwareProperties"].get("platform") == "iOS" \
            and d["connectionProperties"].get("tunnelState") == "connected":
        print(d["identifier"])
        break
EOF
)"
fi
if [[ -z "$DEVICE" ]]; then
  echo "No connected iPhone found. Plug it in, unlock it, and trust this Mac." >&2
  echo "A paired phone that shows as 'available' often still works when named directly:" >&2
  echo "  xcrun devicectl list devices   # then: $0 <identifier>" >&2
  exit 1
fi
echo "==> Device: $DEVICE"

echo "==> Building"
xcodebuild build \
  -project ShadowPlayer.xcodeproj \
  -scheme ShadowPlayer \
  -configuration Debug \
  -destination "id=$DEVICE" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  -quiet

APP="$DERIVED/Build/Products/Debug-iphoneos/ShadowPlayer.app"

echo "==> Installing"
xcrun devicectl device install app --device "$DEVICE" "$APP" >/dev/null

echo "==> Launching"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" >/dev/null

echo "==> Installed and launched on $DEVICE"
