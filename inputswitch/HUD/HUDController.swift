import AppKit
import SwiftUI

/// Shows the HUD for an input source on the active screen, then fades it out.
final class HUDController {
    private let settings: AppSettings
    private let appearance: HUDAppearanceStore
    private let inputSources: InputSourceService

    private let presentation = HUDPresentation()
    private var panel: HUDPanel?
    private var hideTask: Task<Void, Never>?
    /// Bumped on every `show`, so a stale fade-out never hides a newer HUD.
    private var generation = 0

    init(settings: AppSettings, appearance: HUDAppearanceStore, inputSources: InputSourceService) {
        self.settings = settings
        self.appearance = appearance
        self.inputSources = inputSources
    }

    /// The card as it would currently be rendered for `source`.
    func card(for source: InputSource) -> HUDCard {
        HUDCard(
            name: source.name,
            icon: settings.hudShowsIcon ? inputSources.icon(for: source) : nil,
            style: settings.hudStyle,
            tint: appearance.tint(for: source.id),
            size: settings.hudSize
        )
    }

    func show(_ source: InputSource) {
        hideTask?.cancel()
        generation += 1
        let showGeneration = generation

        let panel = makePanelIfNeeded()
        let newCard = card(for: source)
        let fitted = NSHostingView(rootView: newCard.padding(HUDMetrics.shadowInset)).fittingSize

        if panel.isVisible, let hostingView = panel.contentView?.subviews.first {
            // Already on screen: keep the same view so the card animates from
            // the previous source (as in the Settings preview). Grow the panel
            // to fit both cards — never shrink mid-animation — and re-center.
            let current = panel.frame.size
            let size = NSSize(width: max(current.width, fitted.width), height: max(current.height, fitted.height))
            if size != current {
                panel.setContentSize(size)
                hostingView.frame = NSRect(origin: .zero, size: size)
            }
            position(panel)
            presentation.card = newCard
        } else {
            // Appearing: use a fresh hosting view so nothing morphs from the
            // previous card's (hidden) geometry.
            panel.alphaValue = 0
            presentation.isVisible = false
            presentation.card = newCard
            let hostingView = NSHostingView(rootView: HUDOverlayView(presentation: presentation))
            hostingView.sizingOptions = []
            panel.setContentSize(fitted)
            hostingView.frame = NSRect(origin: .zero, size: fitted)
            hostingView.autoresizingMask = [.width, .height]
            panel.contentView?.subviews = [hostingView]
            position(panel)
        }
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        withAnimation(.spring(duration: 0.38, bounce: 0.3)) {
            presentation.isVisible = true
        }

        let duration = settings.hudDisplayDuration
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.hide(generation: showGeneration)
        }
    }

    private func hide(generation hideGeneration: Int) {
        guard let panel, hideGeneration == generation else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.generation == hideGeneration else { return }
                panel.orderOut(nil)
            }
        })
        withAnimation(.easeIn(duration: 0.32)) {
            presentation.isVisible = false
        }
    }

    private func makePanelIfNeeded() -> HUDPanel {
        if let panel { return panel }

        let panel = HUDPanel()
        // Hosting views are added to a plain container with frame-based layout.
        // As a window's direct contentView, NSHostingView syncs the window's
        // content size limits during constraint updates; resizing the panel
        // while hidden and re-showing it then throws "too many Update
        // Constraints passes".
        panel.contentView = NSView()
        self.panel = panel
        return panel
    }

    /// Places the panel on the screen with keyboard focus (follows Spaces and
    /// full-screen apps), falling back to the screen under the mouse.
    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.main
                ?? NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
                ?? NSScreen.screens.first else { return }

        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.minY + visible.height * settings.hudPosition.verticalAnchor - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}
