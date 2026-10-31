# InputSwitch

[English](README.md) | **简体中文**

一个轻量的 macOS 菜单栏应用：每次切换输入法时，用 Liquid Glass（液态玻璃）HUD 显示当前输入法。适合整天在多种语言之间来回切换、不想再猜“这次打出来会是什么”的人。

> 本项目灵感来自 [isHUD](https://github.com/ghawkgu/isHUD)，使用 Swift 从头重写。

<p align="center">
  <img src="images/image_abc.png" width="420" alt="以液态玻璃样式显示 ABC 输入法的 HUD">
  <img src="images/image_wx.png" width="420" alt="以自定义绿色显示微信输入法的 HUD">
</p>

## 目录

- [功能特点](#功能特点)
- [安装](#安装)
- [使用方法](#使用方法)
- [设置](#设置)
- [从源码构建](#从源码构建)
- [架构](#架构)
- [发布](#发布)
- [常见问题](#常见问题)
- [许可证](#许可证)

## 功能特点

- **Liquid Glass HUD**：在当前屏幕显示输入法图标和名称。支持液态玻璃 / 纯色两种样式、小 / 中 / 大三种尺寸、顶部 / 居中 / 底部三种位置。macOS 26 及以上的玻璃效果会跟随系统的玻璃透明度设置；更早的系统使用材质背景。
- **按输入法着色**：为每个输入法单独设置 HUD 颜色和浓度，设置页带实时壁纸预览。
- **菜单栏菜单**：直接选择输入法、打开设置；也可以隐藏菜单栏图标。
- **无需特殊权限**：只监听系统的输入法变更通知，不需要辅助功能权限。
- **开机启动**，界面支持 English、简体中文、繁體中文、日本語。

## 安装

### 系统要求

- macOS 15.7 或更高版本（液态玻璃效果需要 macOS 26 或更高版本）
- Apple Silicon 或 Intel Mac（发布版为 Universal Binary）

### 下载

1. 从 [GitHub Releases](https://github.com/e1roy/inputswitch/releases) 下载最新的 `inputswitch-X.Y.Z.dmg`。
2. 打开 DMG，把 **inputswitch** 拖到“应用程序”文件夹。
3. 启动应用，首次启动会自动打开设置窗口。

DMG 未经过 Apple 公证。如果 macOS 拒绝打开，请参见[常见问题](#下载后无法打开应用)。

## 使用方法

1. **切换输入法**：照常切换即可（例如系统的 ⌃空格 或 🌐 快捷键，或从菜单栏选择），HUD 会显示在当前屏幕上。
2. **打开设置**：点击菜单栏图标选择“设置…”（⌘,），或从“应用程序”、启动台、聚焦搜索再次打开 InputSwitch。隐藏菜单栏图标后也可以这样打开。

## 设置

设置窗口采用侧边栏布局，共四个页面：

| 页面 | 可配置项 |
|------|----------|
| 通用 | 开机启动、显示 / 隐藏菜单栏图标 |
| HUD | 样式（液态玻璃 / 纯色）、尺寸、位置、是否显示图标、显示时长（0.1–1.0 秒，默认 0.8 秒），以及“在屏幕上显示”预览 |
| 输入法 | 每个输入法的颜色和浓度，带实时预览 |
| 关于 | 版本号和相关链接 |

偏好设置保存在 `UserDefaults` 中。输入法颜色按输入法 ID 保存（`HUDTintsBySourceID`），因此重命名输入法或更改系统语言后颜色不会丢失。旧版本按名称保存的颜色会自动迁移。

## 从源码构建

### 前置条件

- 带 macOS 26 SDK 或更高版本的 Xcode（项目使用 Swift 6 和液态玻璃 API）
- 如果 `xcode-select` 指向的是 Command Line Tools，请在 `xcodebuild` 命令前加上 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。`start.sh` 会自动处理。

### 克隆仓库

```bash
git clone https://github.com/e1roy/inputswitch.git
cd inputswitch
```

### 编译、安装并运行

```bash
./start.sh
```

该脚本可以重复执行，它会：

1. 使用 `xcodebuild` 编译 Release 配置
2. 退出正在运行的 InputSwitch 和旧版 isHUD
3. 卸载 isHUD（应用、登录项、偏好设置），如果存在的话
4. 替换 `/Applications/inputswitch.app`，并在 LaunchServices 中注销其他位置的旧副本，确保聚焦搜索和启动台打开的是新版本
5. 启动应用

> **注意：** `start.sh` 会删除 isHUD 应用及其偏好设置。如果你想保留 isHUD，请改用 Xcode 构建。

也可以用 Xcode 打开 `inputswitch.xcodeproj`，运行 `inputswitch` scheme。

### 仅编译

```bash
xcodebuild -project inputswitch.xcodeproj \
    -scheme inputswitch \
    -configuration Debug \
    build
```

### 运行测试

单元测试使用 Swift Testing，覆盖偏好设置持久化、HUD 颜色对比度和颜色迁移：

```bash
xcodebuild test -project inputswitch.xcodeproj -scheme inputswitch \
    -destination 'platform=macOS' -only-testing:inputswitchTests
```

### 脚本

| 脚本 | 说明 |
|------|------|
| `./start.sh` | 编译 Release、安装到 `/Applications`、卸载 isHUD 并启动 |
| `./build-dmg.sh` | 编译 Universal（arm64 + x86_64）DMG，输出到 `dist/` |

## 架构

### 技术栈

- **语言**：Swift 6（严格并发检查，默认 `MainActor` 隔离）
- **界面**：SwiftUI + Observation；HUD 的 `NSPanel` 和设置窗口使用 AppKit
- **输入法**：Carbon Text Input Sources (TIS) API
- **测试**：Swift Testing
- **CI**：GitHub Actions（`macos-26` runner）

### 工作原理

`AppCoordinator` 是组合根，负责创建所有服务并连接它们的回调。`AppDelegate` 持有 coordinator 并处理应用生命周期。

```
InputSourceService ──输入法已变更──▶ HUDController
AppSettings / HUDAppearanceStore ◀── 设置界面；由 HUDController 读取
```

1. 输入法变更时 TIS 发出分布式通知，`InputSourceService` 发布新的选中状态。
2. `HUDController` 计算 `HUDPanel` 的尺寸和位置，并在当前屏幕上播放动画。

### 目录结构

```
inputswitch/
├── App/
│   ├── InputSwitchApp.swift          # @main，菜单栏 Scene
│   ├── AppDelegate.swift             # 生命周期；再次打开应用时显示设置
│   └── AppCoordinator.swift          # 组合根
├── Core/
│   ├── AppSettings.swift             # 用户偏好（@Observable + UserDefaults）
│   ├── InputSourceService.swift      # TIS 封装：读取、监听、切换
│   ├── HUDAppearanceStore.swift      # 按输入法 ID 保存颜色，含旧数据迁移
│   └── LoginItemService.swift        # 开机启动
├── HUD/
│   ├── HUDView.swift                 # HUDCard（液态玻璃 / 纯色）
│   ├── HUDPanel.swift                # 悬浮、不抢焦点的 NSPanel
│   └── HUDController.swift           # 布局与动画
├── Settings/                         # 侧边栏式设置窗口及各页面
├── MenuBar/MenuBarContent.swift      # 菜单栏下拉菜单
├── Support/Constants.swift           # HUD 常量、链接、UserDefaults 键
└── Localizable.xcstrings             # en、zh-Hans、zh-Hant、ja
```

本项目遵循的界面设计规范见 [docs/design-macos27.md](docs/design-macos27.md)。

## 发布

推送 `vX.Y.Z` 格式的 tag 会触发 [.github/workflows/release.yml](.github/workflows/release.yml)，自动编译 Universal DMG，并发布附带 DMG 和 SHA-256 校验文件的 GitHub Release：

```bash
git tag -a v1.2.3 -m "InputSwitch v1.2.3"
git push origin v1.2.3
```

如需重新构建已有的 tag，可在 Actions 页面手动运行该 workflow 并填入 tag。

本地打包 DMG：

```bash
VERSION=1.2.3 ./build-dmg.sh
```

- 输出文件：`dist/inputswitch-<VERSION>.dmg`。不设置 `VERSION` 时使用当天日期（`YYYYMMDD`）。
- `VERSION` 为 `X.Y.Z` 格式时，会同时写入应用的 `MARKETING_VERSION`。
- 设置 `CI=1` 会跳过 Finder 窗口样式设置（该步骤需要图形界面会话）。
- 脚本开始时会删除 `build/` 和 `dist/` 目录。

## 常见问题

### 下载后无法打开应用

发布版未经 Apple 公证，可能会被 Gatekeeper 拦截。右键点击应用选择“打开”，或者清除隔离标记：

```bash
xattr -dr com.apple.quarantine /Applications/inputswitch.app
```

### 聚焦搜索打开的是旧版本

运行 `./start.sh`，它会在 LaunchServices 中注销旧副本。Release 和 DMG 的编译产物放在 `*.noindex` 目录中，不会被聚焦搜索索引。

## 许可证

MIT License
