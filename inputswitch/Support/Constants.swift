import Foundation

/// Timing and layout constants for the HUD overlay.
enum HUDMetrics {
    static let defaultDisplayDuration: TimeInterval = 0.8
    static let displayDurationRange: ClosedRange<TimeInterval> = 0.1...1.0

    /// Transparent margin around the HUD card so its shadow is never clipped
    /// by the panel bounds.
    static let shadowInset: CGFloat = 40
}

/// Timing constants for keyboard gesture recognition.
enum GestureTiming {
    /// Max delay between two Fn presses to count as a double-tap.
    static let doubleTapInterval: TimeInterval = 0.35
    /// A modifier held longer than this is treated as "held", not "tapped",
    /// so it will not switch input source when released.
    static let maximumSoloHoldDuration: TimeInterval = 0.8
}

enum AppLinks {
    static let repository = URL(string: "https://github.com/e1roy/inputswitch")!
    static let inspiration = URL(string: "https://github.com/ghawkgu/isHUD")!
    static let accessibilitySettings = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
}

/// UserDefaults keys. Legacy keys keep their original names so existing
/// user preferences survive the upgrade.
enum DefaultsKey {
    static let switchKey = "HotKeySwitchInputSource"
    static let hudDisplayDuration = "HudDisplayDuration"
    static let switchShortcutEnabled = "SwitchShortcutEnabled"
    static let fnDoubleTapEnabled = "FnDoubleTapEnabled"
    static let hudStyle = "HUDStyle"
    static let hudPosition = "HUDPosition"
    static let hudSize = "HUDSize"
    static let hudShowsIcon = "HUDShowsIcon"
    static let showMenuBarIcon = "ShowMenuBarIcon"
    static let hasLaunchedBefore = "HasLaunchedBefore"

    static let hudTints = "HUDTintsBySourceID"
    /// Pre-2.0: `[localizedName: ["r","g","b","a"]]`, migrated into `hudTints`.
    static let legacyInputSourceColors = "InputSourceColors"
    static let legacyKnownInputSources = "KnownInputSources"
}
