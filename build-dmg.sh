#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="inputswitch"
VERSION=$(date +%Y%m%d)
BUILD_DIR="$PROJECT_DIR/build"
DMG_DIR="$PROJECT_DIR/dist"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOL_NAME="InputSwitch"

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR" "$DMG_DIR"
mkdir -p "$DMG_DIR"

echo "==> Building Universal Binary (arm64 + x86_64)..."
xcodebuild -project "$PROJECT_DIR/${APP_NAME}.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed: ${APP_NAME}.app not found"
    exit 1
fi

echo "==> Found app at: $APP_PATH"

# Verify universal binary
echo "==> Verifying architectures..."
lipo -archs "$APP_PATH/Contents/MacOS/$APP_NAME"
echo "   ✓ Universal binary verified"

# Create DMG staging area
STAGING_DIR="$DMG_DIR/staging"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG..."
# Create temporary DMG
temp_dmg="$DMG_DIR/temp.dmg"
hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -fs HFS+ \
    -format UDRW -size 50m "$temp_dmg"

# Mount DMG
MOUNT_POINT="/Volumes/$VOL_NAME"
hdiutil attach "$temp_dmg" -mountpoint "$MOUNT_POINT"

# Set DMG style
echo "==> Setting DMG style..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 885, 430}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {120, 150}
        set position of item "Applications" of container window to {360, 150}
        close
    end tell
end tell
EOF

# Unmount and convert to compressed DMG
hdiutil detach "$MOUNT_POINT" -force || true
sleep 1

hdiutil convert "$temp_dmg" -format UDZO -o "$DMG_DIR/$DMG_NAME"
rm -f "$temp_dmg"
rm -rf "$STAGING_DIR"

echo ""
echo "✅ DMG created: $DMG_DIR/$DMG_NAME"
echo "   Size: $(du -h "$DMG_DIR/$DMG_NAME" | cut -f1)"
