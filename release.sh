#!/bin/bash

set -e

# 检查是否安装了 gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# 交互输入版本号
echo "InputSwitch Release Script"
echo "=========================="
read -p "Enter version (e.g., v1.0.0): " VERSION

# 检查版本号格式
if ! [[ $VERSION =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Expected format: v1.2.3 or 1.2.3"
    exit 1
fi

# 如果没有 v 前缀，自动添加
if [[ ! $VERSION =~ ^v ]]; then
    VERSION="v$VERSION"
fi

# 检查 release 是否已存在
if gh release view "$VERSION" &> /dev/null; then
    echo "Release $VERSION already exists."
    read -p "Upload to existing release? (y/n): " UPLOAD

    if [[ $UPLOAD != "y" && $UPLOAD != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi

    # 上传到已有 release
    DMG_FILE=$(ls dist/inputswitch-*.dmg 2>/dev/null | head -n 1)

    if [[ -z "$DMG_FILE" ]]; then
        echo "Error: No DMG file found in dist/ directory."
        echo "Run ./build-dmg.sh first to build the distribution."
        exit 1
    fi

    echo "Uploading $(basename "$DMG_FILE") to release $VERSION..."
    gh release upload "$VERSION" "$DMG_FILE" --clobber
    echo "✓ Upload complete!"
    echo "Release: $(gh release view "$VERSION" --json url -q '.url')"
    exit 0
fi

# 新建 release，输入标题和描述
DEFAULT_TITLE="Release $VERSION"
read -p "Enter title [$DEFAULT_TITLE]: " TITLE
TITLE=${TITLE:-$DEFAULT_TITLE}

echo ""
echo "Enter release notes (press Ctrl+D when done):"
NOTES=$(cat)

# 构建 DMG
read -p "Build DMG now? (y/n): " BUILD
if [[ $BUILD == "y" || $BUILD == "Y" ]]; then
    echo "Building DMG..."
    ./build-dmg.sh
fi

# 检查 DMG 文件
DMG_FILE=$(ls dist/inputswitch-*.dmg 2>/dev/null | head -n 1)

if [[ -z "$DMG_FILE" ]]; then
    echo "Error: No DMG file found in dist/ directory."
    echo "Run ./build-dmg.sh first to build the distribution."
    exit 1
fi

echo ""
echo "Creating release $VERSION..."
echo "Title: $TITLE"
echo "File: $(basename "$DMG_FILE")"
read -p "Confirm? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# 创建 release 并上传
gh release create "$VERSION" \
    --title "$TITLE" \
    --notes "$NOTES" \
    "$DMG_FILE"

echo ""
echo "✓ Release created successfully!"
echo "Release: $(gh release view "$VERSION" --json url -q '.url')"
