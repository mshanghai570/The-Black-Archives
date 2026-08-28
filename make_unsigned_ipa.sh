#!/bin/bash
set -e

cd /Users/michaelshingara/Downloads/the-black-archives

echo "📦 Building Release for generic iOS device..."
xcodebuild -project TheBlackArchives.xcodeproj \
    -scheme TheBlackArchives \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo "📱 Locating .app..."
APP_PATH="build/Build/Products/Release-iphoneos/TheBlackArchives.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ .app not found at $APP_PATH"
    exit 1
fi

echo "📦 Creating IPA..."
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -r TheBlackArchives.ipa Payload/TheBlackArchives.app > /dev/null
rm -rf Payload

echo "✅ Done: TheBlackArchives.ipa"
ls -lh TheBlackArchives.ipa