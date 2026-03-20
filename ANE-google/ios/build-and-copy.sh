#!/bin/bash
# Build GoogleSignInExtension.a (output in this folder) and copy to ANE/iPhone-ARM/
# Run once: LANG=en_US.UTF-8 pod install
set -e
cd "$(dirname "$0")"
xcodebuild -workspace GoogleSignInExtension.xcworkspace -scheme GoogleSignInExtension -configuration Release -sdk iphoneos -arch arm64 build
cp GoogleSignInExtension.a "../ANE/iPhone-ARM/"
echo "Done. GoogleSignInExtension.a copied to ANE/iPhone-ARM/"
