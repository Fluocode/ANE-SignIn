#!/bin/bash
# Build AppleSignInExtension.a (output in this folder) and copy to ANE/iPhone-ARM/
set -e
cd "$(dirname "$0")"
xcodebuild -project AppleSignInExtension.xcodeproj -scheme AppleSignInExtension -configuration Release -sdk iphoneos -arch arm64 build
cp AppleSignInExtension.a "../ANE/iPhone-ARM/"
echo "Done. AppleSignInExtension.a copied to ANE/iPhone-ARM/"
