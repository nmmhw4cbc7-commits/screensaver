#!/bin/zsh
# Builds a universal Lumen.app and a drag-to-install DMG into ./build
set -euo pipefail
cd "${0:A:h}/.."
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
B=build; APP=$B/Lumen.app
rm -rf $B && mkdir -p $APP/Contents/{MacOS,Resources} $B/obj

echo "→ Compiling (arm64 + x86_64)"
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -parse-as-library -target $arch-apple-macos15.0 \
    Sources/Lumen/*.swift -o $B/obj/Lumen-$arch
done
lipo -create $B/obj/Lumen-* -output $APP/Contents/MacOS/Lumen
cp Resources/Info.plist $APP/Contents/

echo "→ Rendering icon"
swift scripts/make_icon.swift $B/obj/icon.png
SET=$B/obj/AppIcon.iconset; mkdir -p $SET
for s in 16 32 128 256 512; do
  sips -z $s $s $B/obj/icon.png --out $SET/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) $B/obj/icon.png --out $SET/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns $SET -o $APP/Contents/Resources/AppIcon.icns

echo "→ Signing (ad-hoc)"
codesign --force --deep --sign - $APP

echo "→ Packaging DMG"
STAGE=$B/obj/dmg; mkdir -p $STAGE
cp -R $APP $STAGE/ && ln -s /Applications $STAGE/Applications
hdiutil create -volname "Lumen" -srcfolder $STAGE -ov -format UDZO $B/Lumen-$VERSION.dmg >/dev/null
echo "✓ $B/Lumen-$VERSION.dmg"
