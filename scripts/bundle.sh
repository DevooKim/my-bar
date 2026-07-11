#!/bin/bash
# Assembles "dist/My Bar.app" from the SPM release binary.
# Signs with the "MyBar Dev" self-signed identity when present, so the code
# signature stays stable across rebuilds. Falls back to ad-hoc signing.
# Override the identity with MB_SIGN_IDENTITY.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="dist/My Bar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp .build/release/MyBar "$APP/Contents/MacOS/MyBar"

IDENTITY="${MB_SIGN_IDENTITY:-MyBar Dev}"
# --deep so any nested bundles are signed too. We attempt the real sign
# directly rather than gating on `find-identity`: a self-signed identity
# that isn't a trusted root is omitted from that list but still signs fine.
if codesign --force --deep --sign "$IDENTITY" "$APP" 2>/dev/null; then
    echo "Signed with: $IDENTITY"
else
    echo "warning: '$IDENTITY' identity unavailable; ad-hoc signing" >&2
    codesign --force --deep --sign - "$APP"
fi
echo "Bundled: $APP"
