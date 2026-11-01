import AppKit
import SwiftUI

/// Shows the HUD for an input source on the active screen, then fades it out.
final class HUDController {
    private struct FittingKey: Hashable {
        let name: String
        let hasIcon: Bool
        let style: String
        let size: String
    }

    private let settings: AppSettings
    private let appearance: HUDAppearanceStore
    private let inputSources: InputSourceService

    private let presentation = HUDPresentation()
    private var measuredFittingSizes: [FittingKey: NSSize] = [:]
    private var panel: HUDPanel?
    private var overlayHostingView: NSHostingView<HUDOverlayView>?
    private var hideTimer: DispatchSourceTimer?
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
            size: settings.hudSize,
            glass: settings.hudGlassLook
        )
    }

    func show(_ source: InputSource) {
        generation += 1

        let panel = makePanelIfNeeded()
        let newCard = card(for: source)
        let fittingKey = FittingKey(
            name: newCard.name,
            hasIcon: newCard.icon != nil,
            style: newCard.style.rawValue,
            size: newCard.size.rawValue
        )
        let fitted = measuredFittingSizes[fittingKey]
            ?? NSHostingView(rootView: newCard.padding(HUDMetrics.shadowInset)).fittingSize
        measuredFittingSizes[fittingKey] = fitted

        if panel.isVisible, let hostingView = overlayHostingView {
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
            // Appearing: update while hidden, then reuse one hosting view.
            // HUDOverlayView disables card morphing while hidden, so glass does
            // not animate from the previous appearance's geometry.
            panel.alphaValue = 0
            presentation.isVisible = false
            presentation.card = newCard
            let hostingView = overlayHostingView
                ?? NSHostingView(rootView: HUDOverlayView(presentation: presentation))
            hostingView.sizingOptions = []
            panel.setContentSize(fitted)
            hostingView.frame = NSRect(origin: .zero, size: fitted)
            hostingView.autoresizingMask = [.width, .height]
            if overlayHostingView == nil {
                panel.contentView?.subviews = [hostingView]
                overlayHostingView = hostingView
            }
            position(panel)
        }
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }

        if panel.alphaValue < 1 {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
        if !presentation.isVisible {
            presentation.isVisible = true
        }
        if hideTimer == nil {
            let timer = DispatchSource.makeTimerSource(queue: .main)
            timer.setEventHandler { [weak self] in
                MainActor.assumeIsolated {
                    self?.hideTimerDidFire()
                }
            }
            timer.schedule(deadline: .distantFuture)
            timer.resume()
            hideTimer = timer
        }
        hideTimer?.schedule(
            deadline: .now() + settings.hudDisplayDuration,
            leeway: .milliseconds(10)
        )
    }

    private func hideTimerDidFire() {
        hideTimer?.schedule(deadline: .distantFuture)
        hide(generation: generation)
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
                // The window alpha already faded the card out, so shrinking it
                // while visible only re-rendered the glass card for the whole
                // fade and kept the process busy ~300 ms after the HUD was gone
                // (P-HUD-17). Collapse it off-screen instead, with no animation.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { self.presentation.isVisible = false }
            }
        })
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
