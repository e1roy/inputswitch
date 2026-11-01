# macOS 27 design notes

How InputSwitch's UI maps to Apple's guidance for macOS 27 (WWDC26, June 2026). Check this list when changing the UI.

## Sources

- [Design – What's new](https://developer.apple.com/design/whats-new/). WWDC26 updates: menu item icons, sidebar icon colors, scroll edge effects, Liquid Glass for app icons.
- [WWDC26 design guide](https://developer.apple.com/wwdc26/guides/design/). macOS 27 refines Liquid Glass: more uniform refraction, better contrast, and a system slider in Settings › Appearance that ranges from ultra-clear to fully tinted. Apps that use system glass pick up these changes automatically.
- HIG pages: [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [Color › Liquid Glass color](https://developer.apple.com/design/human-interface-guidelines/color), [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [The menu bar › Menu bar extras](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar), [Scroll views › Scroll edge effects](https://developer.apple.com/design/human-interface-guidelines/scroll-views).

## Decisions

| Guidance | Implementation |
|---|---|
| Liquid Glass is for the functional layer. "Don't use Liquid Glass in the content layer", and use it sparingly. | Only the HUD uses glass. The HUD is a floating overlay, like the system volume HUD. Settings pages use standard controls (`.bordered`, `.borderedProminent`, `.quaternary` fills). |
| Use the **regular** glass variant for components with text. Glass appearance follows the user's Liquid Glass look setting. | The HUD uses `.glassEffect(.regular, in: .capsule)` (tinted only if the user picked a color), so it follows the macOS 27 clear↔tinted slider. Before macOS 26 it falls back to `.regularMaterial`. |
| Clear glass suits bright, bold content over media, and needs a dimming layer when what's behind it is bright. | Clear is an opt-in (Settings › HUD › Glass, macOS 26+). The dimming is not a separate layer: `HUDGlassLook.glassTint(over:)` composites the source color over black at the dimming strength into one `Glass.clear.tint(_:)`, so it morphs with the card (see the double-capsule note below). Text on clear glass is white. The default 45 % gives white text ≥ 3:1 over a white backdrop (measured 3.07:1; regular glass measures 2.65:1 there). |
| Apply color sparingly, for elements that benefit from emphasis such as status indicators. | Per-source color is opt-in and off by default. When set, it is applied as the glass's own tint (`Glass.regular.tint(_:)`). With the active appearance (see below) the tint is uniform, and because color and shape are a single layer, they morph together when the HUD switches sources. An earlier version drew a separate fill over the glass, and the two drifted apart mid-animation (a "double capsule"). |
| Sidebar icons should use the accent color the user chose. Use fixed colors sparingly. | Sidebar rows use plain SF Symbols (`Label(_, systemImage:)`), which follow the accent color and the sidebar icon size. |
| "Consider letting people hide the sidebar." | Not offered. Like System Settings, the Settings window keeps its sidebar. `SidebarCommands()` was tried and removed because it does not reach an AppKit-hosted `NavigationSplitView`. |
| Menu item icons: use them sparingly, and give all items in a group an icon or none. Use title-style capitalization. | No menu item icons. English labels use title case. |
| Menu bar extras: use a template symbol, show a menu (not a popover), let people choose whether to show it, and don't rely on it alone. | `StatusBarIcon` is a single template image (black + clear). The menu is `.menuBarExtraStyle(.menu)`. "Show icon in menu bar" toggles `MenuBarExtra(isInserted:)`. Opening the app again always shows Settings. |
| Prefer the automatic scroll edge effect, and add none for decoration. | Only system `Form`, toolbar and sidebar are used. No custom scroll edge effects. |
| Unified toolbars and edge-to-edge sidebars. | `NSWindow.toolbarStyle = .unified` with `.fullSizeContentView`, plus `NavigationSplitView`. |
| Glass should look the same in the HUD as in the Settings preview. | Liquid Glass draws its edge highlights only in windows with an *active appearance*. The HUD panel must never become key (it would steal focus), so `HUDPanel` overrides AppKit's private `_hasActiveAppearance` query. Public alternatives were tested and had no effect: `isKeyWindow`/`isMainWindow` overrides and the SwiftUI `appearsActive`/`controlActiveState` environment values. If a future macOS stops calling the private query, the HUD falls back to flat glass. It does not crash. |
| Respect accessibility settings. | Reduce Motion turns off the HUD scale animation. Glass and materials handle Reduce Transparency and Increase Contrast themselves. |
