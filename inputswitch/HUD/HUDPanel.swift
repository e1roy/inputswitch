import AppKit

/// Borderless, click-through, non-activating panel that floats above
/// everything (including full-screen apps) on every Space.
final class HUDPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovable = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.utilityWindow)) + 1000)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Liquid Glass draws its edge highlights only in windows with an active
    // appearance. This panel can never become key (it must not steal focus),
    // so it would always render flat, unlike the Settings preview. AppKit has
    // no public switch for this, so override its private query. If a future
    // macOS stops calling it, the HUD simply falls back to the flat look.
    @objc(_hasActiveAppearance) private var hasActiveAppearance: Bool { true }
}
