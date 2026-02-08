import Foundation
import Carbon

/// Monitors keyboard input source changes via CFNotificationCenter + TIS API.
/// All public callbacks are dispatched to main thread.
final class InputSourceMonitor {
    var onInputSourceChanged: ((_ name: String, _ iconURL: URL?) -> Void)?
    var onEnabledSourcesChanged: (() -> Void)?

    private var currentName: String?
    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        currentName = currentInputSourceName()

        let center = CFNotificationCenterGetDistributedCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let monitor = Unmanaged<InputSourceMonitor>.fromOpaque(observer).takeUnretainedValue()
                monitor._handleInputSourceChanged()
            },
            kTISNotifySelectedKeyboardInputSourceChanged as CFString,
            nil,
            .deliverImmediately
        )

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let monitor = Unmanaged<InputSourceMonitor>.fromOpaque(observer).takeUnretainedValue()
                monitor._handleEnabledSourcesChanged()
            },
            kTISNotifyEnabledKeyboardInputSourcesChanged as CFString,
            nil,
            .deliverImmediately
        )
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        let center = CFNotificationCenterGetDistributedCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    func currentInputSourceName() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
        return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
    }

    func currentInputSourceIconURL() -> URL? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        guard let urlPtr = TISGetInputSourceProperty(source, kTISPropertyIconImageURL) else { return nil }
        return Unmanaged<CFURL>.fromOpaque(urlPtr).takeUnretainedValue() as URL
    }

    func allKeyboardInputSourceNames() -> [String] {
        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true
        ]
        guard let sources = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return sources.compactMap { source in
            guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
            return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        }
    }

    func longestInputSourceName() -> String {
        let names = allKeyboardInputSourceNames()
        return names.max(by: { $0.count < $1.count }) ?? ""
    }

    // MARK: - Internal (called from CF callbacks)

    nonisolated func _handleInputSourceChanged() {
        let newName = MainActor.assumeIsolated {
            self.currentInputSourceName()
        }
        MainActor.assumeIsolated {
            guard let name = newName, name != self.currentName else { return }
            self.currentName = name
            let iconURL = self.currentInputSourceIconURL()
            self.onInputSourceChanged?(name, iconURL)
        }
    }

    nonisolated func _handleEnabledSourcesChanged() {
        MainActor.assumeIsolated {
            self.onEnabledSourcesChanged?()
        }
    }

    deinit {
        stopMonitoring()
    }
}
