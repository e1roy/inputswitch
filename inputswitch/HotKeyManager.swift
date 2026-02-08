import AppKit
import Carbon

/// Monitors modifier key events to:
/// 1. Switch input source on right-Command or right-Option key press+release (solo press)
/// 2. Show HUD on Fn double-tap
final class HotKeyManager {
    var onShowHUD: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // Fn double-tap tracking
    private var lastFnPressTime: TimeInterval = 0

    // Solo modifier key detection: trigger only when the modifier key is
    // pressed and released without any other key being pressed in between.
    private var trackingKeyCode: UInt16?
    private var otherKeyDown = false
    private var otherKeyMonitorGlobal: Any?
    private var otherKeyMonitorLocal: Any?

    func startListening() {
        // Monitor flagsChanged for modifier key press/release
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        // Monitor keyDown to detect if another key was pressed while modifier is held
        otherKeyMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.otherKeyDown = true
        }
        otherKeyMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.otherKeyDown = true
            return event
        }
    }

    func stopListening() {
        for monitor in [globalMonitor, localMonitor, otherKeyMonitorGlobal, otherKeyMonitorLocal] {
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
        globalMonitor = nil
        localMonitor = nil
        otherKeyMonitorGlobal = nil
        otherKeyMonitorLocal = nil
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keyCode = event.keyCode

        // --- Fn double-tap detection ---
        if keyCode == KeyCode.fn.rawValue {
            let fnDown = event.modifierFlags.contains(.function)
            if fnDown {
                let now = ProcessInfo.processInfo.systemUptime
                if now - lastFnPressTime <= HUDConstants.fnDoubleStrikeInterval {
                    lastFnPressTime = 0
                    onShowHUD?()
                    return
                }
                lastFnPressTime = now
            }
            return
        }

        // --- Solo modifier key to switch input source ---
        let configuredKey = SwitchHotKey(rawValue: UserDefaults.standard.integer(forKey: DefaultsKey.hotKeySwitchInputSource)) ?? .rightCommand
        let targetKeyCode: UInt16 = (configuredKey == .rightCommand) ? KeyCode.commandR.rawValue : KeyCode.optionR.rawValue

        guard keyCode == targetKeyCode else { return }

        // Check if this is key-down or key-up by examining if the corresponding modifier flag is set
        let isModifierDown: Bool
        switch keyCode {
        case KeyCode.commandR.rawValue, KeyCode.commandL.rawValue:
            isModifierDown = event.modifierFlags.contains(.command)
        case KeyCode.optionR.rawValue, KeyCode.optionL.rawValue:
            isModifierDown = event.modifierFlags.contains(.option)
        default:
            return
        }

        if isModifierDown {
            // Modifier key pressed down — start tracking
            trackingKeyCode = keyCode
            otherKeyDown = false
        } else {
            // Modifier key released — check if it was a solo press
            if trackingKeyCode == keyCode && !otherKeyDown {
                // No other modifier should be held
                let unwanted: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
                if event.modifierFlags.intersection(unwanted).isEmpty {
                    selectNextInputSource()
                }
            }
            trackingKeyCode = nil
            otherKeyDown = false
        }
    }

    private func selectNextInputSource() {
        // Use TIS API to select next input source directly
        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true
        ]
        guard let sourceList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        guard let currentIDPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) else { return }
        let currentID = Unmanaged<CFString>.fromOpaque(currentIDPtr).takeUnretainedValue() as String

        // Find the next source in the list
        var foundCurrent = false
        var nextSource: TISInputSource?
        for source in sourceList {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            if foundCurrent {
                nextSource = source
                break
            }
            if id == currentID {
                foundCurrent = true
            }
        }
        // Wrap around to first
        if nextSource == nil, let first = sourceList.first {
            nextSource = first
        }

        if let next = nextSource {
            TISSelectInputSource(next)
        }
    }

    deinit {
        stopListening()
    }
}
