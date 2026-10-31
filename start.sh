#!/bin/bash
# Build the latest InputSwitch (Release), replace the copy in /Applications,
# remove the legacy isHUD app, and launch.
#
# Safe to run repeatedly: every removal step skips what is already gone.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="inputswitch"
# ".noindex" keeps Spotlight from listing the build product as a second app.
BUILD_DIR="$PROJECT_DIR/build/install.noindex"
INSTALL_DIR="/Applications"
APP_NAME="inputswitch.app"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# xcodebuild needs full Xcode; fall back to it when xcode-select points at
# the Command Line Tools.
if ! xcodebuild -version >/dev/null 2>&1 && [ -d /Applications/Xcode.app ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

quit_app() { # $1 = process name
    if pgrep -xq "$1"; then
        echo "    quitting $1"
        killall "$1" 2>/dev/null || true
        for _ in 1 2 3 4 5; do pgrep -xq "$1" || return 0; sleep 0.5; done
        killall -9 "$1" 2>/dev/null || true
    fi
}

remove_path() {
    if [ -e "$1" ]; then
        if rm -rf "$1" 2>/dev/null; then
            echo "    removed $1"
        else
            # e.g. sandbox containers, which macOS protects from deletion
            echo "    skipped $1 (protected by macOS)"
        fi
    fi
}

echo "==> Building $SCHEME (Release)..."
xcodebuild -project "$PROJECT_DIR/inputswitch.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" | grep -v appintentsmetadataprocessor || true

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME"
if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed: $BUILT_APP not found"
    exit 1
fi

echo "==> Quitting running instances..."
quit_app isHUD
quit_app inputswitch

echo "==> Removing legacy isHUD..."
osascript -e 'tell application "System Events" to if exists login item "isHUD" then delete login item "isHUD"' >/dev/null 2>&1 \
    && echo "    login item checked" || echo "    (could not access login items; remove isHUD manually if listed)"
remove_path "$INSTALL_DIR/isHUD.app"
remove_path "$HOME/Applications/isHUD.app"
remove_path "$HOME/Library/Preferences/net.ghawk.isHUD.plist"
remove_path "$HOME/Library/Containers/net.thinking.ghawk.isHUD"
remove_path "$HOME/Library/Application Scripts/net.thinking.ghawk.isHUD"
defaults delete net.ghawk.isHUD >/dev/null 2>&1 || true

echo "==> Replacing installed InputSwitch..."
remove_path "$INSTALLED_APP"
remove_path "$HOME/Applications/$APP_NAME"
cp -R "$BUILT_APP" "$INSTALL_DIR/"
echo "    installed $INSTALLED_APP"

# Make LaunchServices (Spotlight, Launchpad, `open`) resolve the bundle ID to
# the /Applications copy only, not to build products lying around.
"$LSREGISTER" -dump 2>/dev/null \
    | awk '/^path:/ { sub(/^path: +/, ""); sub(/ \(0x[0-9a-f]+\)$/, ""); print }' \
    | grep -E "/(inputswitch|isHUD)\.app$" \
    | grep -v "^$INSTALLED_APP$" \
    | while read -r stale; do
        "$LSREGISTER" -u "$stale" >/dev/null 2>&1 && echo "    unregistered $stale"
    done || true
"$LSREGISTER" -f "$INSTALLED_APP"

echo "==> Launching $INSTALLED_APP"
open "$INSTALLED_APP"
