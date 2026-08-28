#!/bin/bash
cd /Users/michaelshingara/Downloads/the-black-archives
xcodebuild -project TheBlackArchives.xcodeproj -scheme TheBlackArchives -destination 'generic/platform=iOS' -configuration Release build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "(error:|warning:|BUILD|SUCCEEDED|FAILED)" > /tmp/build_result.txt
echo "Exit code: $?"
cat /tmp/build_result.txt