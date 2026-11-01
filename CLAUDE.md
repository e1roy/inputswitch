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

# Create DMG distribution (VERSION=1.2.3 sets MARKETING_VERSION; CI=1 skips Finder styling)
./build-dmg.sh

# Release: push a vX.Y.Z tag → .github/workflows/release.yml builds the DMG and publishes the GitHub Release (see the `release` skill)

# Run tests
xcodebuild test -project inputswitch.xcodeproj -scheme inputswitch -destination 'platform=macOS'
```

## Architecture

`AppCoordinator` is the composition root: it owns every service and wires their callbacks. `AppDelegate` owns the coordinator and handles lifecycle (first launch / Dock reopen → `showSettings()`; silent at login).

### Core Components

| Component | Responsibility |
|-----------|----------------|
| [`App/AppCoordinator.swift`](inputswitch/App/AppCoordinator.swift) | Creates services, connects events, exposes actions (`showSettings`, `previewHUD`, …) |
| [`App/AppDelegate.swift`](inputswitch/App/AppDelegate.swift) | Lifecycle; `applicationShouldHandleReopen` opens Settings; detects login-item launch |
| [`Core/AppSettings.swift`](inputswitch/Core/AppSettings.swift) | `@Observable` preferences persisted to `UserDefaults` (injectable for tests) |
| [`Core/InputSourceService.swift`](inputswitch/Core/InputSourceService.swift) | TIS wrapper: current/enabled sources, select by ID, distributed-notification observing |
| [`Core/HUDAppearanceStore.swift`](inputswitch/Core/HUDAppearanceStore.swift) | Per-source `HUDTint`, keyed by input source **ID**; migrates legacy name-keyed colors |
| [`HUD/HUDController.swift`](inputswitch/HUD/HUDController.swift) | Sizes, positions, animates the `HUDPanel` |
| [`HUD/HUDView.swift`](inputswitch/HUD/HUDView.swift) | `HUDCard` (Liquid Glass / solid), shared by the overlay and Settings preview |
| [`Settings/SettingsWindowController.swift`](inputswitch/Settings/SettingsWindowController.swift) | AppKit window hosting `SettingsView`; switches activation policy to `.regular` while open |

### Data Flow

```
InputSourceService ──selection changed──▶ HUDController
AppSettings / HUDAppearanceStore ◀── Settings UI (@Bindable) ; read by HUDController
```

### Conventions

- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; state types use `@Observable`
- UI follows macOS 27 HIG; see [docs/design-macos27.md](docs/design-macos27.md). Liquid Glass is used **only** for the HUD (functional layer), gated by `#available(macOS 26, *)` with a material fallback: `.regular` by default, `.clear` as a user opt-in. Every color on the glass (source tint, clear-glass dimming) goes into its single `Glass.tint` via `HUDGlassLook.glassTint(over:)`. Settings content uses standard controls, and the sidebar uses plain SF Symbols (accent-colored). Deployment target is macOS 15.7
- Keep decision logic (e.g. tint contrast, color migration) in pure functions/value types so it stays testable
- HUD: do not make an `NSHostingView` the panel's direct `contentView` (AppKit throws "too many Update Constraints passes" when it is resized while hidden). Embed it in a container. When the HUD **appears**, create a fresh hosting view (otherwise glass morphs from the previous, hidden geometry). While it is **visible**, keep the view and update `HUDPresentation.card` so the card animates like the Settings preview; the panel only grows during that time, so the morph is never clipped. Measure with a separate hosting view's `fittingSize` (before `sizingOptions = []`)
- The menu bar icon (`StatusBarIcon`) must stay a single template image
- `HUDPanel` overrides AppKit's private `_hasActiveAppearance`. Without it the never-key panel renders Liquid Glass flat, with no edge highlights. Re-check this on each new macOS release
- All user-facing strings live in `Localizable.xcstrings` (en, zh-Hans, zh-Hant, ja)
- A feature that is added or changed updates its row in [docs/features.md](docs/features.md) and its test rows in [docs/bench/test-plan.md](docs/bench/test-plan.md) in the same change (rules at the top of each file). The `input-switch-bench-test` skill runs that plan and tracks per-metric best/latest in `docs/bench/baseline.md`
- `xcode-select` may point at CommandLineTools; prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`

## Important Notes

- The app has no dock icon (`LSUIElement = 1` in Info.plist)
- HUD colors are stored in UserDefaults (`HUDTintsBySourceID`, JSON) per input source ID
- Settings use a `NavigationSplitView` sidebar with grouped `Form` pages (General, HUD, Input Sources, About)
- The app needs no Accessibility permission; it has no keyboard shortcuts of its own and reacts only to TIS input-source-change notifications
- Icons are generated, not hand-drawn. `swift design/app-icon/generate.swift <dir>` writes the `solid.svg` / `outline.svg` layers for `AppIcon.icon/Assets`. `swift design/statusbar-icon/generate.swift <dir>` writes candidate 18 pt template PDFs plus a `sheet.png` comparison. The split-keycap variant (`B_split.pdf`) is the one shipped as `StatusBarIcon.pdf`
