#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="inputswitch"
BUILD_DIR="$PROJECT_DIR/build"

echo "==> Building $SCHEME..."
xcodebuild -project "$PROJECT_DIR/inputswitch.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | tail -5

APP_PATH=$(find "$BUILD_DIR" -name "inputswitch.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed: inputswitch.app not found"
    exit 1
fi

echo "==> Killing existing instance (if any)..."
killall inputswitch 2>/dev/null || true
sleep 1

INSTALL_DIR="/Applications"
echo "==> Copying to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/inputswitch.app"
cp -R "$APP_PATH" "$INSTALL_DIR/"

echo "==> Launching /Applications/inputswitch.app"
open "/Applications/inputswitch.app"
