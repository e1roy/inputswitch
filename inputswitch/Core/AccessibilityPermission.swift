import AppKit
import ApplicationServices
import Observation

/// Tracks whether the app is trusted for Accessibility, which macOS requires
/// for global keyboard event monitoring.
@Observable
final class AccessibilityPermission {
    private(set) var isTrusted: Bool

    /// Called once each time trust transitions from denied to granted.
    @ObservationIgnored var onGranted: (() -> Void)?
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    /// Re-checks trust; polls in the background until granted.
    func startMonitoring() {
        refresh()
        guard !isTrusted, pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.5))
                guard let self else { return }
                self.refresh()
                if self.isTrusted { break }
            }
            self?.pollTask = nil
        }
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        guard trusted != isTrusted else { return }
        isTrusted = trusted
        if trusted { onGranted?() }
    }

    /// Shows the system prompt (first time) and opens the Accessibility pane.
    func request() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(AppLinks.accessibilitySettings)
        startMonitoring()
    }
}
