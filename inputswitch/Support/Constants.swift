import Foundation

/// Timing and layout constants for the HUD overlay.
enum HUDMetrics {
    static let defaultDisplayDuration: TimeInterval = 0.8
    static let displayDurationRange: ClosedRange<TimeInterval> = 0.1...1.0

    /// Transparent margin around the HUD card so its shadow is never clipped
    /// by the panel bounds.
    static let shadowInset: CGFloat = 40
}

enum AppLinks {
    static let repository = URL(string: "https://github.com/e1roy/inputswitch")!
    static let inspiration = URL(string: "https://github.com/ghawkgu/isHUD")!
}

/// UserDefaults keys. Legacy keys keep their original names so existing
/// user preferences survive the upgrade.
enum DefaultsKey {
    static let hudDisplayDuration = "HudDisplayDuration"
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
