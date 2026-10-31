# InputSwitch

一个 macOS 菜单栏应用，提供便捷的输入法切换和可视化 HUD 提示。

> 本项目灵感来自 [isHUD](https://github.com/ghawkgu/isHUD)，使用 Swift 进行重写。

## 功能特点

- **一键切换输入法**：单独轻按右 Command / Option / Shift / Control（可选）切换到下一个输入法；⌘C 等组合键不受影响，按住过久或中途点击鼠标不会误触发
- **Liquid Glass HUD**：切换时在当前屏幕显示输入法图标和名称，支持液态玻璃 / 纯色样式、三种大小、顶部 / 居中 / 底部位置；液态玻璃会跟随 macOS 27 的“外观”玻璃透明度设置（设计规范对照见 [docs/design-macos27.md](docs/design-macos27.md)）
- **按输入法着色**：为每个输入法单独设置 HUD 颜色和浓度，设置页带实时壁纸预览
- **Fn 双击显示**：连按两下 Fn (🌐) 显示当前输入法
- **点击图标打开设置**：从“应用程序”、启动台或聚焦搜索打开 InputSwitch，即可显示设置窗口
- **权限引导**：自动检测辅助功能权限，并一键跳转到系统设置授权
- **菜单栏**：快速选择输入法、开关快捷键；也可以隐藏菜单栏图标
- **开机启动**、多语言（简体中文 / 繁體中文 / 日本語 / English）

<img src="images/image.png" width="400" alt="HUD 效果预览">

## 使用方法

1. **首次打开**：按提示在“系统设置 › 隐私与安全性 › 辅助功能”中允许 InputSwitch（用于检测修饰键轻按）
2. **切换输入法**：单独按下并松开右 Command 键（可在“快捷键”页面更换）
3. **显示当前输入法**：快速连按两下 Fn 键
4. **打开设置**：点击菜单栏图标选择“设置…”，或再次打开 InputSwitch 应用

## 系统要求

- macOS 15.7 或更高版本（macOS 26 及以上使用 Liquid Glass 效果）

## 技术栈

- Swift 6（严格并发检查）、SwiftUI + Observation
- AppKit（NSPanel HUD、设置窗口）
- Carbon TIS API（输入法读取与切换）
- Swift Testing 单元测试

## 项目结构

```
inputswitch/
├── App/
│   ├── InputSwitchApp.swift      # @main，菜单栏 Scene
│   ├── AppDelegate.swift         # 生命周期；点击 App 图标时打开设置
│   └── AppCoordinator.swift      # 组合根：创建并连接所有服务
├── Core/
│   ├── AppSettings.swift         # 用户偏好（@Observable + UserDefaults）
│   ├── InputSourceService.swift  # 输入法读取、监听、切换（TIS）
│   ├── KeyGestures.swift         # 单独轻按 / 双击识别（纯逻辑，可测试）
│   ├── HotKeyMonitor.swift       # NSEvent 全局监听 → 手势识别
│   ├── HUDAppearanceStore.swift  # 按输入法 ID 保存 HUD 颜色（含旧数据迁移）
│   ├── AccessibilityPermission.swift # 辅助功能权限检测
│   └── LoginItemService.swift    # 开机启动
├── HUD/
│   ├── HUDView.swift             # HUD 卡片（Liquid Glass / 纯色）
│   ├── HUDPanel.swift            # 悬浮、不抢焦点的 NSPanel
│   └── HUDController.swift       # 显示位置与动画
├── Settings/                     # 侧边栏式设置窗口
│   ├── SettingsWindowController.swift
│   ├── SettingsView.swift
│   ├── GeneralSettingsView.swift
│   ├── ShortcutsSettingsView.swift
│   ├── HUDSettingsView.swift
│   ├── InputSourcesSettingsView.swift
│   ├── HUDPreview.swift
│   └── AboutView.swift
├── MenuBar/MenuBarContent.swift  # 菜单栏菜单
├── Support/Constants.swift
└── Localizable.xcstrings
```

## 发布打包

推送 `vX.Y.Z` 格式的 tag 即可触发 GitHub Actions（[.github/workflows/release.yml](.github/workflows/release.yml)）自动打包 DMG 并发布 GitHub Release：

```bash
git tag -a v0.0.3 -m "InputSwitch v0.0.3"
git push origin v0.0.3
```

本地打包为 DMG 文件：

```bash
./build-dmg.sh
```

脚本会：
1. 编译 **Universal Binary**（同时支持 Apple Silicon ARM64 和 Intel x86_64）
2. 创建带 Applications 快捷方式的 DMG 文件
3. 设置美观的窗口布局
4. 输出到 `dist/inputswitch-YYYYMMDD.dmg`

**架构支持：**
- ✅ Apple Silicon (M1/M2/M3) - arm64
- ✅ Intel Mac - x86_64

## 构建

### 方式一：使用 Xcode

使用 Xcode 打开 `inputswitch.xcodeproj` 并构建运行。

### 方式二：使用命令行

项目提供了 `start.sh` 脚本，可以一键编译、安装并运行：

```bash
./start.sh
```

该脚本会（可重复执行）：
1. 使用 `xcodebuild` 编译最新代码（Release 配置）
2. 退出正在运行的 InputSwitch 和旧版 isHUD
3. 卸载 isHUD（应用、登录项、偏好设置）
4. 用新版本替换 `/Applications/inputswitch.app`，并在 LaunchServices 中注销其他位置的旧副本，确保 Spotlight / 启动台打开的是新版
5. 启动应用

运行单元测试：

```bash
xcodebuild test -project inputswitch.xcodeproj -scheme inputswitch \
    -destination 'platform=macOS' -only-testing:inputswitchTests
```

或者手动编译：

```bash
xcodebuild -project inputswitch.xcodeproj \
    -scheme inputswitch \
    -configuration Release \
    build
```

## 许可证

MIT License
