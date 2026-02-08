import AppKit
import SwiftUI

final class HUDWindowController {
    private var panel: HUDPanel?
    private var hostingView: NSHostingView<HUDContentView>?
    private var fadeOutTimer: Timer?
    private var panelWidth: CGFloat = 200
    /// Incremented each time showHUD is called; fade-out completion checks
    /// this to avoid hiding a newer HUD.
    private var showGeneration: UInt = 0
    /// The original Y position of the panel (used to reset after slide-up animation)
    private var originalY: CGFloat = 0
    private static let slideUpDistance: CGFloat = 30

    private let colorManager: InputSourceColorManager

    init(colorManager: InputSourceColorManager) {
        self.colorManager = colorManager
    }

    func setupHUDSize(longestName: String) {
        let font = NSFont.systemFont(ofSize: HUDConstants.fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (longestName as NSString).size(withAttributes: attrs)
        panelWidth = textSize.width + HUDConstants.iconSize + 12 + HUDConstants.horizontalMargin * 2 + 20
        panelWidth = max(panelWidth, 200)
    }

    func showHUD(name: String, iconURL: URL?) {
        // Cancel any pending fade-out timer
        fadeOutTimer?.invalidate()
        fadeOutTimer = nil

        // Bump generation so any in-flight fade-out completion becomes a no-op
        showGeneration &+= 1

        let color = colorManager.colorForInputSource(name)
        let alpha = colorManager.alphaForInputSource(name)

        let swiftUIColor = Color(
            red: Double(color.redComponent),
            green: Double(color.greenComponent),
            blue: Double(color.blueComponent)
        )

        let contentView = HUDContentView(
            inputSourceName: name,
            iconURL: iconURL,
            backgroundColor: swiftUIColor,
            backgroundOpacity: Double(alpha)
        )

        if panel == nil {
            let rect = NSRect(x: 0, y: 0, width: panelWidth, height: HUDConstants.panelHeight)
            panel = HUDPanel(contentRect: rect)
        }

        if hostingView == nil {
            hostingView = NSHostingView(rootView: contentView)
            panel?.contentView = hostingView
        } else {
            hostingView?.rootView = contentView
        }

        let frame = NSRect(x: 0, y: 0, width: panelWidth, height: HUDConstants.panelHeight)
        panel?.setFrame(frame, display: false)

        positionOnMouseScreen()

        // Cancel any running animation and reset position/alpha
        panel?.contentView?.layer?.removeAllAnimations()
        panel?.contentView?.alphaValue = 0
        // Reset to original position (in case a slide-up was in progress)
        if let panel = panel {
            panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: originalY))
        }

        panel?.orderFrontRegardless()

        fadeIn()
    }

    // MARK: - Positioning

    private func positionOnMouseScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main

        guard let screen = screen, let panel = panel else { return }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.midY - panel.frame.height / 2
        originalY = y
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Animation

    private func fadeIn() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = HUDConstants.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel?.contentView?.animator().alphaValue = 1.0
        }, completionHandler: { [weak self] in
            self?.scheduleFadeOut()
        })
    }

    private func scheduleFadeOut() {
        let duration = UserDefaults.standard.double(forKey: DefaultsKey.hudDisplayDuration)
        let displayDuration = duration > 0 ? duration : HUDConstants.defaultDisplayDuration

        fadeOutTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }

    private func fadeOut() {
        let gen = showGeneration
        guard let panel = panel else { return }

        // Animate alpha + slide up simultaneously
        let targetY = panel.frame.origin.y + Self.slideUpDistance
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = HUDConstants.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.contentView?.animator().alphaValue = 0.0
            panel.animator().setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: targetY))
        }, completionHandler: { [weak self] in
            guard let self, self.showGeneration == gen else { return }
            panel.orderOut(nil)
            // Reset position for next show
            panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: self.originalY))
        })
    }
}
