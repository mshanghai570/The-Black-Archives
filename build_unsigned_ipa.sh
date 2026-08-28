#!/bin/bash
set -e

PROJECT_DIR="/Users/michaelshingara/Downloads/the-black-archives"
cd "$PROJECT_DIR"

echo "=== Building for generic iOS device (Release) ==="
xcodebuild -project TheBlackArchives.xcodeproj \
    -scheme TheBlackArchives \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

echo "=== Creating unsigned IPA ==="
APP_PATH="build/Build/Products/Release-iphoneos/TheBlackArchives.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: .app not found at $APP_PATH"
    exit 1
fi

mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -r TheBlackArchives.ipa Payload/TheBlackArchives.app
rm -rf Payload

echo "=== IPA created: $PROJECT_DIR/TheBlackArchives.ipa ==="
ls -lh TheBlackArchives.ipa