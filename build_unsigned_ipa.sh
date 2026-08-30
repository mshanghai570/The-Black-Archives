#!/usr/bin/env bash
# Build an UNSIGNED Release IPA of The Black Archives for iOS devices.
# No code signing is required (the project is configured with
# CODE_SIGNING_ALLOWED=NO). The local Mirage framework is used as-is.
set -euo pipefail

cd "$(dirname "$0")"   # repo root

OUT_DIR="build/ipa"
APP_PATH="build/Build/Products/Release-iphoneos/TheBlackArchives.app"
IPA="$OUT_DIR/TheBlackArchives.ipa"

echo "==> Building Release for generic iOS device (unsigned)..."
xcodebuild -project TheBlackArchives.xcodeproj \
    -scheme TheBlackArchives \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: .app not found at $APP_PATH" >&2
    exit 1
fi

echo "==> Creating unsigned IPA..."
mkdir -p "$OUT_DIR" Payload
rm -rf Payload/TheBlackArchives.app "$IPA"
cp -R "$APP_PATH" Payload/
zip -r "$IPA" Payload/TheBlackArchives.app > /dev/null
rm -rf Payload

echo "==> Done: $IPA"
ls -lh "$IPA"
unzip -l "$IPA" | tail -3
