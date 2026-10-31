import Foundation
import Observation

enum HUDStyle: String, CaseIterable, Identifiable, Sendable {
    case glass
    case solid

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .glass: "Liquid Glass"
        case .solid: "Solid"
        }
    }
}

enum HUDPosition: String, CaseIterable, Identifiable, Sendable {
    case top
    case center
    case bottom

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .top: "Top"
        case .center: "Center"
        case .bottom: "Bottom"
        }
    }

    /// Vertical position of the HUD's center as a fraction of the screen's
    /// visible height, measured from the bottom.
    var verticalAnchor: CGFloat {
        switch self {
        case .top: 0.82
        case .center: 0.5
        case .bottom: 0.18
        }
    }
}

enum HUDSize: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var scale: CGFloat {
        switch self {
        case .small: 0.8
        case .medium: 1.0
        case .large: 1.3
        }
    }
}

/// User preferences, persisted to `UserDefaults` and observable by SwiftUI.
@Observable
final class AppSettings {
    var switchShortcutEnabled: Bool { didSet { defaults.set(switchShortcutEnabled, forKey: DefaultsKey.switchShortcutEnabled) } }
    var switchKey: SwitchKey { didSet { defaults.set(switchKey.rawValue, forKey: DefaultsKey.switchKey) } }
    var fnDoubleTapEnabled: Bool { didSet { defaults.set(fnDoubleTapEnabled, forKey: DefaultsKey.fnDoubleTapEnabled) } }

    var hudStyle: HUDStyle { didSet { defaults.set(hudStyle.rawValue, forKey: DefaultsKey.hudStyle) } }
    var hudPosition: HUDPosition { didSet { defaults.set(hudPosition.rawValue, forKey: DefaultsKey.hudPosition) } }
    var hudSize: HUDSize { didSet { defaults.set(hudSize.rawValue, forKey: DefaultsKey.hudSize) } }
    var hudShowsIcon: Bool { didSet { defaults.set(hudShowsIcon, forKey: DefaultsKey.hudShowsIcon) } }
    var hudDisplayDuration: TimeInterval {
        didSet {
            let clamped = hudDisplayDuration.clamped(to: HUDMetrics.displayDurationRange)
            if clamped != hudDisplayDuration { hudDisplayDuration = clamped; return }
            defaults.set(hudDisplayDuration, forKey: DefaultsKey.hudDisplayDuration)
        }
    }

    var showMenuBarIcon: Bool { didSet { defaults.set(showMenuBarIcon, forKey: DefaultsKey.showMenuBarIcon) } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            DefaultsKey.switchShortcutEnabled: true,
            DefaultsKey.switchKey: SwitchKey.rightCommand.rawValue,
            DefaultsKey.fnDoubleTapEnabled: true,
            DefaultsKey.hudStyle: HUDStyle.glass.rawValue,
            DefaultsKey.hudPosition: HUDPosition.center.rawValue,
            DefaultsKey.hudSize: HUDSize.medium.rawValue,
            DefaultsKey.hudShowsIcon: true,
            DefaultsKey.hudDisplayDuration: HUDMetrics.defaultDisplayDuration,
            DefaultsKey.showMenuBarIcon: true,
        ])

        switchShortcutEnabled = defaults.bool(forKey: DefaultsKey.switchShortcutEnabled)
        switchKey = SwitchKey(rawValue: defaults.integer(forKey: DefaultsKey.switchKey)) ?? .rightCommand
        fnDoubleTapEnabled = defaults.bool(forKey: DefaultsKey.fnDoubleTapEnabled)
        hudStyle = defaults.string(forKey: DefaultsKey.hudStyle).flatMap(HUDStyle.init) ?? .glass
        hudPosition = defaults.string(forKey: DefaultsKey.hudPosition).flatMap(HUDPosition.init) ?? .center
        hudSize = defaults.string(forKey: DefaultsKey.hudSize).flatMap(HUDSize.init) ?? .medium
        hudShowsIcon = defaults.bool(forKey: DefaultsKey.hudShowsIcon)
        hudDisplayDuration = defaults.double(forKey: DefaultsKey.hudDisplayDuration)
            .clamped(to: HUDMetrics.displayDurationRange)
        showMenuBarIcon = defaults.bool(forKey: DefaultsKey.showMenuBarIcon)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
