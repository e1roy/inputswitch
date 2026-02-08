import AppKit

final class HUDPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
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
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let utilityLevel = Int(CGWindowLevelForKey(.utilityWindow))
        level = NSWindow.Level(rawValue: utilityLevel + 1000)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
