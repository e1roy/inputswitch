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

/// The Liquid Glass variant of the HUD on macOS 26 and later
/// (`Glass.regular` / `Glass.clear`). Earlier systems always use the material
/// fallback.
enum HUDGlassVariant: String, CaseIterable, Identifiable, Sendable {
    case regular
    case clear

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .regular: "Regular"
        case .clear: "Clear"
        }
    }
}

/// How the HUD's Liquid Glass is drawn: the variant plus, for clear glass, a
/// dimming strength that keeps the text legible over bright backdrops.
struct HUDGlassLook: Equatable, Sendable {
    var variant: HUDGlassVariant
    /// Opacity of the black dimming, used only by clear glass.
    var dimming: Double

    static let regular = HUDGlassLook(variant: .regular, dimming: 0)

    static let dimmingRange: ClosedRange<Double> = 0...0.6
    static let defaultDimming = 0.45

    /// The tint the glass is drawn with, given the source's own tint.
    ///
    /// Regular glass frosts its backdrop and takes the source tint as is. Clear
    /// glass adds the dimming as black underneath the source tint, folded into
    /// a single tint: a separate dimming layer would drift away from the glass
    /// while the card morphs.
    func glassTint(over sourceTint: HUDTint?) -> HUDTint? {
        let dimming = variant == .clear ? dimming.clamped(to: Self.dimmingRange) : 0
        guard dimming > 0 else { return sourceTint }
        guard let sourceTint else {
            return HUDTint(red: 0, green: 0, blue: 0, opacity: dimming)
        }
        // Source-over compositing of the tint onto black at `dimming`.
        let alpha = sourceTint.opacity + dimming * (1 - sourceTint.opacity)
        let scale = sourceTint.opacity / alpha
        return HUDTint(
            red: sourceTint.red * scale,
            green: sourceTint.green * scale,
            blue: sourceTint.blue * scale,
            opacity: alpha
        )
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
    var hudStyle: HUDStyle { didSet { defaults.set(hudStyle.rawValue, forKey: DefaultsKey.hudStyle) } }
    var hudGlassVariant: HUDGlassVariant {
        didSet { defaults.set(hudGlassVariant.rawValue, forKey: DefaultsKey.hudGlassVariant) }
    }
    var hudGlassDimming: Double {
        didSet {
            let clamped = hudGlassDimming.clamped(to: HUDGlassLook.dimmingRange)
            if clamped != hudGlassDimming { hudGlassDimming = clamped; return }
            defaults.set(hudGlassDimming, forKey: DefaultsKey.hudGlassDimming)
        }
    }
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

    var hudGlassLook: HUDGlassLook {
        HUDGlassLook(variant: hudGlassVariant, dimming: hudGlassDimming)
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            DefaultsKey.hudStyle: HUDStyle.glass.rawValue,
            DefaultsKey.hudGlassVariant: HUDGlassVariant.regular.rawValue,
            DefaultsKey.hudGlassDimming: HUDGlassLook.defaultDimming,
            DefaultsKey.hudPosition: HUDPosition.center.rawValue,
            DefaultsKey.hudSize: HUDSize.medium.rawValue,
            DefaultsKey.hudShowsIcon: true,
            DefaultsKey.hudDisplayDuration: HUDMetrics.defaultDisplayDuration,
            DefaultsKey.showMenuBarIcon: true,
        ])

        hudStyle = defaults.string(forKey: DefaultsKey.hudStyle).flatMap(HUDStyle.init) ?? .glass
        hudGlassVariant = defaults.string(forKey: DefaultsKey.hudGlassVariant)
            .flatMap(HUDGlassVariant.init) ?? .regular
        hudGlassDimming = defaults.double(forKey: DefaultsKey.hudGlassDimming)
            .clamped(to: HUDGlassLook.dimmingRange)
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
