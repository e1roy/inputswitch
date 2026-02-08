# InputSwitch

一个 macOS 菜单栏应用，提供便捷的输入法切换和可视化 HUD 提示。

> 本项目灵感来自 [isHUD](https://github.com/ghawgang/isHUD)，使用 Swift 进行重写。

## 功能特点

- **快捷键切换输入法**: 支持右 Command 或右 Option 键快速切换输入法
- **HUD 提示**: 切换输入法时显示精美的悬浮提示，显示当前输入法名称和图标
- **Fn 双击显示**: 双击 Fn 键可显示当前输入法状态
- **开机启动**: 支持设置开机自动启动
- **个性化设置**: 可为不同输入法设置不同的 HUD 背景颜色
- **菜单栏图标**: 轻量级菜单栏应用，随时可访问设置

<img src="images/image.png" width="400" alt="HUD 效果预览">

## 使用方法

1. **切换输入法**: 按下并松开右 Command 键或右 Option 键（可在设置中选择）
2. **显示当前输入法**: 快速双击 Fn 键
3. **访问设置**: 点击菜单栏图标，选择 "Preferences..."

## 系统要求

- macOS 14.0 或更高版本

## 技术栈

- Swift 5
- SwiftUI
- Carbon API (Text Input Sources)
- AppKit

## 项目结构

```
inputswitch/
├── inputswitchApp.swift      # 应用入口
├── AppDelegate.swift         # 应用生命周期管理
├── Constants.swift           # 常量定义
├── HotKeyManager.swift       # 快捷键监听与管理
├── InputSourceMonitor.swift  # 输入法状态监控
├── HUDWindowController.swift # HUD 窗口控制器
├── HUDContentView.swift      # HUD 内容视图
├── HUDPanel.swift            # HUD 面板
├── InputSourceColorManager.swift # 输入法颜色管理
├── LoginItemManager.swift    # 开机启动管理
├── Settings/                 # 设置页面
│   ├── GeneralSettingsView.swift
│   ├── AppearanceSettingsView.swift
│   └── AboutView.swift
└── Assets.xcassets/          # 图标资源
```

## 构建

使用 Xcode 打开 `inputswitch.xcodeproj` 并构建运行。

## 许可证

MIT License
