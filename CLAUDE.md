# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InputSwitch is a macOS menu bar application written in Swift 5 that provides convenient input source switching with a visual HUD overlay. The app is an LSUIElement application (no dock icon, menu bar only).

## Build Commands

```bash
# Quick start: Build, install to /Applications, and run
./start.sh

# Build debug
xcodebuild -project inputswitch.xcodeproj \
    -scheme inputswitch \
    -configuration Debug \
    build

# Build release with universal binary (arm64 + x86_64)
xcodebuild -project inputswitch.xcodeproj \
    -scheme inputswitch \
    -configuration Release \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

# Create DMG distribution
./build-dmg.sh

# Run tests
xcodebuild test -project inputswitch.xcodeproj -scheme inputswitch -destination 'platform=macOS'
```

## Architecture

The app follows a Model-Coordinator pattern with AppDelegate as the central coordinator:

### Core Components

| Component | Responsibility |
|-----------|----------------|
| [`AppDelegate.swift`](inputswitch/AppDelegate.swift) | Central coordinator that initializes and manages all services |
| [`HotKeyManager.swift`](inputswitch/HotKeyManager.swift) | Handles keyboard events for input switching and HUD display via NSEvent global monitors |
| [`InputSourceMonitor.swift`](inputswitch/InputSourceMonitor.swift) | Monitors input source changes using Carbon Framework's TIS API |
| [`HUDWindowController.swift`](inputswitch/HUDWindowController.swift) | Controls the HUD NSPanel overlay |
| [`InputSourceColorManager.swift`](inputswitch/InputSourceColorManager.swift) | Singleton managing per-input-source color customization |

### Data Flow

```
User Input (HotKeyManager/ InputSourceMonitor) → AppDelegate Callbacks → HUDWindowController
Settings Changes (@AppStorage) → UserDefaults → Runtime Behavior
```

### Key Patterns

- **Observer/Callback Pattern**: Used for input source changes (`CFNotificationCenter`) and hot key events
- **Singleton Pattern**: `InputSourceColorManager.shared`
- **@Observable Pattern**: Swift 6 Observation framework for state management
- **@AppStorage Pattern**: SwiftUI UserDefaults binding for settings persistence

### Technical Details

- **Input Source Management**: Uses Carbon Framework's TIS (Text Input Sources) API
- **Event Monitoring**: Global event monitoring via `NSEvent.addGlobalMonitorForEvents`
- **Solo Key Detection**: Logic to detect "press and release" of modifier keys without combining with other keys
- **HUD Display**: Floating NSPanel with dynamic sizing on the screen with keyboard focus (`NSScreen.main`)
- **Minimum Deployment Target**: macOS 15.7+ (as configured in project settings, though README states 14.0+)
- **Localization**: Supports zh-Hans, zh-Hant, ja, en

## Important Notes

- The app has no dock icon (`LSUIElement = 1` in Info.plist)
- HUD colors are stored in UserDefaults per input source ID
- Settings views use SwiftUI with split-based navigation
