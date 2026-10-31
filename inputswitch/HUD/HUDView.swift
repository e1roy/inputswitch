import SwiftUI

/// The HUD card: input source icon + name on a Liquid Glass (or solid) capsule.
///
/// Pure value view, shared by the on-screen overlay and the Settings preview.
struct HUDCard: View {
    let name: String
    let icon: NSImage?
    let style: HUDStyle
    let tint: HUDTint?
    let size: HUDSize

    private var scale: CGFloat { size.scale }

    var body: some View {
        HStack(spacing: 14 * scale) {
            if let icon {
                Image(nsImage: icon)
                    .renderingMode(icon.isTemplate ? .template : .original)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34 * scale, height: 34 * scale)
                    .accessibilityHidden(true)
            }
            Text(name)
                .font(.system(size: 26 * scale, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 32 * scale)
        .frame(minWidth: 168 * scale, minHeight: 80 * scale)
        .modifier(HUDBackground(style: style, tint: tint))
        .accessibilityElement(children: .combine)
    }

    private var foreground: Color {
        switch (style, tint) {
        case (.glass, nil): .primary
        case (.solid, nil): .white
        case (_, let tint?): tint.prefersDarkForeground ? .black.opacity(0.85) : .white
        }
    }
}

private struct HUDBackground: ViewModifier {
    let style: HUDStyle
    let tint: HUDTint?

    func body(content: Content) -> some View {
        switch style {
        case .glass:
            if #available(macOS 26, *) {
                content.glassEffect(.regular.tint(tintColor), in: .capsule)
            } else {
                content
                    .background {
                        Capsule().fill(.regularMaterial)
                        if let tintColor { Capsule().fill(tintColor) }
                    }
                    .overlay { Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5) }
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            }
        case .solid:
            let fill = tint ?? .solidDefault
            content
                .background(Capsule().fill(fill.color.opacity(fill.opacity)))
                .overlay { Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.22), radius: 20, y: 10)
        }
    }

    private var tintColor: Color? {
        tint.map { $0.color.opacity($0.opacity) }
    }
}

extension HUDTint {
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }

    /// Creates a tint from any SwiftUI color, converted to sRGB.
    init(_ color: Color, opacity: Double) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        self.init(
            red: Double(ns.redComponent),
            green: Double(ns.greenComponent),
            blue: Double(ns.blueComponent),
            opacity: opacity
        )
    }
}

/// What the HUD panel shows. Observed by the overlay, so replacing `card`
/// while the HUD is on screen animates like the Settings preview.
@Observable
final class HUDPresentation {
    var card: HUDCard?
    var isVisible = false
}

/// Root view of the HUD panel: the card, centered, plus a transparent shadow
/// margin. The panel may be larger than the card (it only grows while
/// visible), so the card stays centered while it morphs between sources.
struct HUDOverlayView: View {
    let presentation: HUDPresentation

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let card = presentation.card {
            card
                .animation(
                    reduceMotion || !presentation.isVisible ? nil : .smooth,
                    value: card.name
                )
                .scaleEffect(presentation.isVisible || reduceMotion ? 1 : 0.88)
                .animation(
                    reduceMotion
                        ? nil
                        : presentation.isVisible
                            ? .spring(duration: 0.38, bounce: 0.3)
                            : .easeIn(duration: 0.32),
                    value: presentation.isVisible
                )
                .padding(HUDMetrics.shadowInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview("HUD styles") {
    VStack(spacing: 24) {
        HUDCard(name: "微信输入法", icon: nil, style: .glass, tint: nil, size: .medium)
        HUDCard(name: "ABC", icon: nil, style: .glass,
                tint: HUDTint(red: 0.2, green: 0.7, blue: 0.4, opacity: 0.7), size: .medium)
        HUDCard(name: "Pinyin", icon: nil, style: .solid, tint: nil, size: .small)
    }
    .padding(40)
    .background(LinearGradient(colors: [.indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
}
