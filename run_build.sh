#!/bin/bash
cd /Users/michaelshingara/Downloads/the-black-archives
xcodebuild -project TheBlackArchives.xcodeproj -scheme TheBlackArchives -destination 'generic/platform=iOS' -configuration Release build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO > /tmp/xcode_build.log 2>&1
echo "EXIT: $?" >> /tmp/xcode_build.log