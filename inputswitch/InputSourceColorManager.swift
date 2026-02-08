import AppKit
import Observation

@Observable
final class InputSourceColorManager {
    static let shared = InputSourceColorManager()

    var knownInputSources: [String] = []
    private var colorCache: [String: [String: CGFloat]] = [:]

    private init() {
        loadFromDefaults()
    }

    // MARK: - Public API

    func recordInputSource(_ name: String) {
        if !knownInputSources.contains(name) {
            knownInputSources.append(name)
            saveKnownSources()
        }
    }

    func colorForInputSource(_ name: String) -> NSColor {
        if let rgba = colorCache[name] {
            return NSColor(
                red: rgba["r"] ?? HUDConstants.defaultBackgroundRed,
                green: rgba["g"] ?? HUDConstants.defaultBackgroundGreen,
                blue: rgba["b"] ?? HUDConstants.defaultBackgroundBlue,
                alpha: 1.0
            )
        }
        return NSColor(
            red: HUDConstants.defaultBackgroundRed,
            green: HUDConstants.defaultBackgroundGreen,
            blue: HUDConstants.defaultBackgroundBlue,
            alpha: 1.0
        )
    }

    func alphaForInputSource(_ name: String) -> CGFloat {
        return colorCache[name]?["a"] ?? HUDConstants.defaultAlpha
    }

    func setColor(_ color: NSColor, forInputSource name: String) {
        var rgba = colorCache[name] ?? defaultRGBA()
        let converted = color.usingColorSpace(.sRGB) ?? color
        rgba["r"] = converted.redComponent
        rgba["g"] = converted.greenComponent
        rgba["b"] = converted.blueComponent
        colorCache[name] = rgba
        saveColors()
    }

    func setAlpha(_ alpha: CGFloat, forInputSource name: String) {
        var rgba = colorCache[name] ?? defaultRGBA()
        rgba["a"] = max(0.1, min(1.0, alpha))
        colorCache[name] = rgba
        saveColors()
    }

    func nsColorForInputSource(_ name: String) -> NSColor {
        let color = colorForInputSource(name)
        let alpha = alphaForInputSource(name)
        return color.withAlphaComponent(alpha)
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        knownInputSources = defaults.stringArray(forKey: DefaultsKey.knownInputSources) ?? []
        colorCache = defaults.dictionary(forKey: DefaultsKey.inputSourceColors) as? [String: [String: CGFloat]] ?? [:]
    }

    private func saveKnownSources() {
        UserDefaults.standard.set(knownInputSources, forKey: DefaultsKey.knownInputSources)
    }

    private func saveColors() {
        UserDefaults.standard.set(colorCache, forKey: DefaultsKey.inputSourceColors)
    }

    private func defaultRGBA() -> [String: CGFloat] {
        return [
            "r": HUDConstants.defaultBackgroundRed,
            "g": HUDConstants.defaultBackgroundGreen,
            "b": HUDConstants.defaultBackgroundBlue,
            "a": HUDConstants.defaultAlpha
        ]
    }
}
