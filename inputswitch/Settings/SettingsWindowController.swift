import AppKit
import SwiftUI

/// Hosts the SwiftUI Settings UI in an AppKit window so it can be opened from
/// anywhere (menu bar, Dock reopen, first launch) and brought to the front.
///
/// While the window is open the app temporarily becomes a regular app with a
/// Dock icon, so the window participates in ⌘-Tab and Mission Control.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let navigation: SettingsNavigation

    init(coordinator: AppCoordinator) {
        navigation = coordinator.navigation
        let hostingController = NSHostingController(rootView: SettingsView(coordinator: coordinator))
        hostingController.sceneBridgingOptions = [.toolbars, .title]
        // The window manages its own size; letting SwiftUI drive window size
        // constraints from changing content (e.g. preview text) can loop.
        hostingController.sizingOptions = []

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.toolbar = NSToolbar(identifier: "SettingsToolbar")
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.contentMinSize = NSSize(width: 680, height: 480)
        window.setContentSize(NSSize(width: 760, height: 560))
        self.window = window

        super.init()
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        trackPageTitle()
    }

    /// Mirrors the selected page into the window title, like System Settings.
    private func trackPageTitle() {
        let page = withObservationTracking {
            navigation.selection ?? .general
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackPageTitle() }
        }
        window.title = String(localized: page.title)
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        // Cooperative activation may decline to activate us (e.g. when launched
        // from another app); still make sure the window is visible on top.
        window.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
