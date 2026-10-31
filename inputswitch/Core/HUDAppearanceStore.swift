import Foundation
import Observation

/// A per-input-source HUD color. sRGB components in `0...1`.
struct HUDTint: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    /// Tint strength for Liquid Glass, fill opacity for the solid style.
    var opacity: Double

    static let opacityRange: ClosedRange<Double> = 0.1...1.0

    /// Fill used by the solid style when a source has no custom tint.
    static let solidDefault = HUDTint(red: 0.08, green: 0.08, blue: 0.09, opacity: 0.78)

    /// Relative luminance (WCAG) of the color composited at full opacity.
    var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// Whether dark text reads better than white text on this tint.
    var prefersDarkForeground: Bool {
        opacity >= 0.45 && luminance > 0.5
    }
}

/// Stores per-input-source HUD tints, keyed by the stable input source ID.
@Observable
final class HUDAppearanceStore {
    private(set) var tints: [String: HUDTint] = [:]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: DefaultsKey.hudTints),
           let decoded = try? JSONDecoder().decode([String: HUDTint].self, from: data) {
            tints = decoded
        }
    }

    func tint(for sourceID: String) -> HUDTint? {
        tints[sourceID]
    }

    func setTint(_ tint: HUDTint?, for sourceID: String) {
        var tint = tint
        if let opacity = tint?.opacity {
            tint?.opacity = opacity.clamped(to: HUDTint.opacityRange)
        }
        guard tints[sourceID] != tint else { return }
        tints[sourceID] = tint
        save()
    }

    /// Moves colors saved by older versions (keyed by localized name) onto the
    /// matching source IDs. Unmatched legacy entries are kept for later.
    func migrateLegacyColors(for sources: [InputSource]) {
        guard var legacy = defaults.dictionary(forKey: DefaultsKey.legacyInputSourceColors)
                as? [String: [String: Double]], !legacy.isEmpty else { return }

        for source in sources {
            guard let rgba = legacy.removeValue(forKey: source.name) else { continue }
            if tints[source.id] == nil {
                tints[source.id] = HUDTint(
                    red: rgba["r"] ?? 0,
                    green: rgba["g"] ?? 0,
                    blue: rgba["b"] ?? 0,
                    opacity: (rgba["a"] ?? HUDTint.solidDefault.opacity).clamped(to: HUDTint.opacityRange)
                )
            }
        }

        save()
        if legacy.isEmpty {
            defaults.removeObject(forKey: DefaultsKey.legacyInputSourceColors)
            defaults.removeObject(forKey: DefaultsKey.legacyKnownInputSources)
        } else {
            defaults.set(legacy, forKey: DefaultsKey.legacyInputSourceColors)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tints) {
            defaults.set(data, forKey: DefaultsKey.hudTints)
        }
    }
}
