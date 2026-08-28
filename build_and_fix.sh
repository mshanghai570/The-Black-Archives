#!/bin/bash
set -e

echo "=== Downloading Mirage XCFramework ==="
mkdir -p /Users/michaelshingara/Downloads/the-black-archives/build/SourcePackages/artifacts/mirage/sdcpp
cd /Users/michaelshingara/Downloads/the-black-archives/build/SourcePackages/artifacts/mirage/sdcpp

if [ ! -d "sdcpp.xcframework" ]; then
    curl -L -o sdcpp.xcframework.zip "https://github.com/haplollc/Mirage/releases/download/0.2.0/sdcpp.xcframework.zip"
    unzip -q sdcpp.xcframework.zip
    rm sdcpp.xcframework.zip
    echo "XCFramework downloaded successfully"
else
    echo "XCFramework already exists"
fi

ls -la

echo ""
echo "=== Cleaning DerivedData ==="
rm -rf ~/Library/Developer/Xcode/DerivedData/TheBlackArchives-*

echo ""
echo "=== Building ==="
cd /Users/michaelshingara/Downloads/the-black-archives
xcodebuild -project TheBlackArchives.xcodeproj -scheme TheBlackArchives -configuration Release -destination 'generic/platform=iOS' clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

echo ""
echo "=== Build complete ==="