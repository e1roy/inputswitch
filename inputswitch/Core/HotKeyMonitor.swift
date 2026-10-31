import AppKit

/// Bridges global/local `NSEvent` monitors to the pure gesture recognizers.
///
/// - Solo tap of the configured right-hand modifier → `onSwitchRequested`
/// - Double-tap of Fn (🌐) → `onShowHUDRequested`
///
/// Global key monitoring requires Accessibility permission. Call `restart()`
/// after permission is granted so monitors are re-installed.
final class HotKeyMonitor {
    var onSwitchRequested: (() -> Void)?
    var onShowHUDRequested: (() -> Void)?

    private let settings: AppSettings
    private var monitors: [Any] = []
    private var solo = SoloModifierRecognizer()
    private var fnDoubleTap = DoubleTapRecognizer()

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isRunning: Bool { !monitors.isEmpty }

    func start() {
        guard monitors.isEmpty else { return }

        let flags: NSEvent.EventTypeMask = .flagsChanged
        let interruptions: NSEvent.EventTypeMask = [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]

        add(NSEvent.addGlobalMonitorForEvents(matching: flags) { [weak self] in self?.handleFlagsChanged($0) })
        add(NSEvent.addLocalMonitorForEvents(matching: flags) { [weak self] in self?.handleFlagsChanged($0); return $0 })
        add(NSEvent.addGlobalMonitorForEvents(matching: interruptions) { [weak self] _ in self?.handleInterruption() })
        add(NSEvent.addLocalMonitorForEvents(matching: interruptions) { [weak self] in self?.handleInterruption(); return $0 })
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
        solo = SoloModifierRecognizer()
        fnDoubleTap.reset()
    }

    func restart() {
        stop()
        start()
    }

    private func add(_ monitor: Any?) {
        if let monitor { monitors.append(monitor) }
    }

    private func handleInterruption() {
        solo.interrupt()
        fnDoubleTap.reset()
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        if event.keyCode == KeyCode.fn {
            solo.interrupt()
            if settings.fnDoubleTapEnabled,
               event.modifierFlags.contains(.function),
               fnDoubleTap.press(at: event.timestamp) {
                onShowHUDRequested?()
            }
            return
        }

        fnDoubleTap.reset()
        guard settings.switchShortcutEnabled else { return }

        let fired = solo.flagsChanged(
            keyCode: event.keyCode,
            rawFlags: event.modifierFlags.rawValue,
            timestamp: event.timestamp,
            target: settings.switchKey
        )
        if fired { onSwitchRequested?() }
    }
}
