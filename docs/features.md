# Features

Everything InputSwitch does, one row per user-visible feature, with the [bench test plan](bench/test-plan.md) rows that cover it. A feature that is added or changed gets its row here in the same change, plus its test-plan rows.

- **ID**: `<component>-<nn>`, permanent. Take the next free number; a removed feature is struck through with `removed YYYY-MM-DD`.
- **Functional** / **Performance**: the covering `F-…` / `P-…` IDs in test-plan.md. `—` means not covered yet. Write `n/a: <reason>` when a feature has no meaningful performance dimension.

## HUD

| ID | Feature | Behaviour | Code | Functional | Performance |
|---|---|---|---|---|---|
| HUD-01 | Show HUD on input-source change | Any switch (system shortcut, input menu, our menu, another app) shows a HUD with the source name and icon, even while the app is in the background | [InputSourceService.swift](../inputswitch/Core/InputSourceService.swift), [HUDController.swift](../inputswitch/HUD/HUDController.swift) | F-HUD-01, F-SRC-02, F-SRC-03 | P-APP-05, P-HUD-01, P-HUD-02, P-HUD-03, P-HUD-05, P-HUD-08, P-HUD-09, P-HUD-10, P-HUD-14 |
| HUD-02 | Auto-hide | Fades out after the display duration (0.1–1.0 s, default 0.8 s) | [HUDController.swift](../inputswitch/HUD/HUDController.swift) | F-HUD-04 | P-HUD-04, P-HUD-17 |
| HUD-03 | Rapid switching | While visible the card morphs to the new source in place, and a stale fade-out never hides a newer HUD | [HUDController.swift](../inputswitch/HUD/HUDController.swift), [HUDView.swift](../inputswitch/HUD/HUDView.swift) | F-HUD-03, F-HUD-05 | P-HUD-06, P-HUD-07, P-HUD-12, P-HUD-13, P-HUD-15, P-HUD-16 |
| HUD-04 | Appearance options | Style Liquid Glass / Solid, size small / medium / large, show/hide the source icon | [HUDView.swift](../inputswitch/HUD/HUDView.swift), [AppSettings.swift](../inputswitch/Core/AppSettings.swift) | F-HUD-09 | P-HUD-11 |
| HUD-10 | Glass variant and dimming | macOS 26 and later, Liquid Glass style only: glass Regular (default) / Clear. Clear adds a dimming of 0–60 % (default 45 %, white text ≥ 3:1 on a white backdrop), folded into the glass tint together with the source's own color. Hidden for Solid and before macOS 26 | [AppSettings.swift](../inputswitch/Core/AppSettings.swift), [HUDView.swift](../inputswitch/HUD/HUDView.swift), [HUDSettingsView.swift](../inputswitch/Settings/HUDSettingsView.swift) | F-HUD-14, F-SET-04, F-LIFE-02 | P-HUD-11 (`glass-clear`) |
| HUD-05 | Position | Top / center / bottom of the screen with keyboard focus (falls back to the screen under the mouse) | [HUDController.swift](../inputswitch/HUD/HUDController.swift) | F-HUD-06, F-HUD-07 | — |
| HUD-06 | Per-source color | Each input source can have its own tint. Text switches to dark on light tints for contrast | [HUDAppearanceStore.swift](../inputswitch/Core/HUDAppearanceStore.swift), [HUDView.swift](../inputswitch/HUD/HUDView.swift) | F-HUD-02 | — |
| HUD-07 | Unobtrusive overlay | Floats above full-screen apps on every Space, never takes focus, and is click-through | [HUDPanel.swift](../inputswitch/HUD/HUDPanel.swift) | F-HUD-08, F-HUD-10, F-HUD-11 | — |
| HUD-08 | Accessibility adaptation | Reduce Motion drops the scale animation. Glass falls back to material before macOS 26 and under Reduce Transparency | [HUDView.swift](../inputswitch/HUD/HUDView.swift) | F-HUD-12 | P-HUD-11 (`glass-reduce-transparency`) |
| HUD-09 | Liquid Glass highlights | The HUD renders glass with edge highlights despite never being key (`_hasActiveAppearance` override) | [HUDPanel.swift](../inputswitch/HUD/HUDPanel.swift) | F-HUD-13 | — |

## Input sources

| ID | Feature | Behaviour | Code | Functional | Performance |
|---|---|---|---|---|---|
| SRC-01 | Live source list | Enabled, selectable keyboard sources in system order, updated when sources are added or removed in System Settings | [InputSourceService.swift](../inputswitch/Core/InputSourceService.swift) | F-SRC-01 | — |
| SRC-02 | Select a source | Selecting a source from the app (menu bar picker) switches the system input source | [InputSourceService.swift](../inputswitch/Core/InputSourceService.swift) | F-MENU-01 | — |
| SRC-03 | Source icons | Each source's icon is loaded once and cached; template icons follow light/dark mode | [InputSourceService.swift](../inputswitch/Core/InputSourceService.swift) | F-HUD-01 | — |

## Menu bar

| ID | Feature | Behaviour | Code | Functional | Performance |
|---|---|---|---|---|---|
| MENU-01 | Menu bar icon and source picker | Template status icon. The menu lists enabled sources with the current one checked; choosing one switches to it | [InputSwitchApp.swift](../inputswitch/App/InputSwitchApp.swift), [MenuBarContent.swift](../inputswitch/MenuBar/MenuBarContent.swift) | F-MENU-01, F-MENU-03 | — |
| MENU-02 | Settings and Quit | Menu items with ⌘, and ⌘Q | [MenuBarContent.swift](../inputswitch/MenuBar/MenuBarContent.swift) | F-MENU-02 | — |
| MENU-03 | Hide menu bar icon | The icon can be hidden. Opening the app again (Finder, Launchpad, Spotlight) brings Settings back | [GeneralSettingsView.swift](../inputswitch/Settings/GeneralSettingsView.swift), [AppDelegate.swift](../inputswitch/App/AppDelegate.swift) | F-MENU-04 | — |

## Settings

| ID | Feature | Behaviour | Code | Functional | Performance |
|---|---|---|---|---|---|
| SET-01 | Settings window | Sidebar with General / HUD / Input Sources / About. Window title follows the page, frame is remembered, one window only. Shows a Dock icon and ⌘-Tab entry while open | [SettingsWindowController.swift](../inputswitch/Settings/SettingsWindowController.swift), [SettingsView.swift](../inputswitch/Settings/SettingsView.swift) | F-SET-01, F-SET-02, F-SET-03 | P-SET-01, P-SET-02, P-SET-07 |
| SET-02 | General page | Status header with the current source and a "show HUD" button, launch at login (with the needs-approval state and errors), menu bar icon toggle, Quit | [GeneralSettingsView.swift](../inputswitch/Settings/GeneralSettingsView.swift) | F-SET-04, F-SET-08 | — |
| SET-03 | HUD page | Live preview over the user's wallpaper. Style, glass variant and dimming (macOS 26+), size, position, icon and duration controls, plus Show on Screen | [HUDSettingsView.swift](../inputswitch/Settings/HUDSettingsView.swift), [HUDPreview.swift](../inputswitch/Settings/HUDPreview.swift) | F-SET-04, F-SET-06 | P-SET-03, P-SET-04, P-SET-08 |
| SET-04 | Input Sources page | Source list with a "Current" badge and a tint swatch. Per-source color editor (12 presets, custom color, intensity, reset, Show on Screen), and a link to Keyboard Settings | [InputSourcesSettingsView.swift](../inputswitch/Settings/InputSourcesSettingsView.swift) | F-SET-05, F-SRC-01 | P-SET-05, P-SET-06 |
| SET-05 | About page | Version and build, links to GitHub and isHUD | [AboutView.swift](../inputswitch/Settings/AboutView.swift) | F-SET-09 | n/a: static page |
| SET-06 | Localization | All UI in English, Simplified Chinese, Traditional Chinese and Japanese | [Localizable.xcstrings](../inputswitch/Localizable.xcstrings) | F-SET-07 | n/a: no runtime cost of its own |

## Lifecycle

| ID | Feature | Behaviour | Code | Functional | Performance |
|---|---|---|---|---|---|
| LIFE-01 | Launch behaviour | First launch and manual launches open Settings, a login-item launch stays silent, and re-opening the running app opens Settings | [AppDelegate.swift](../inputswitch/App/AppDelegate.swift) | F-LIFE-01, F-SET-02 | — |
| LIFE-02 | Launch at login | Registers the app via `SMAppService`, in sync with System Settings › Login Items | [LoginItemService.swift](../inputswitch/Core/LoginItemService.swift) | F-SET-08 | — |
| LIFE-03 | Preferences | Every setting persists in `UserDefaults`. Out-of-range or invalid values fall back to defaults or are clamped | [AppSettings.swift](../inputswitch/Core/AppSettings.swift), [HUDAppearanceStore.swift](../inputswitch/Core/HUDAppearanceStore.swift) | F-SET-04, F-LIFE-02, F-LIFE-06 | — |
| LIFE-04 | Legacy migration | Name-keyed colors and old keys from pre-2.0 / isHUD-era versions move to the current format | [HUDAppearanceStore.swift](../inputswitch/Core/HUDAppearanceStore.swift) | F-LIFE-03 | n/a: one-off at launch |
| LIFE-05 | Background agent | Menu-bar-only app (no Dock icon) that needs no permissions and keeps working across sleep/wake, lock and user switching | `INFOPLIST_KEY_LSUIElement` in [project.pbxproj](../inputswitch.xcodeproj/project.pbxproj), [AppDelegate.swift](../inputswitch/App/AppDelegate.swift) | F-LIFE-04, F-LIFE-05 | P-APP-01, P-APP-02, P-APP-03, P-APP-04 |
