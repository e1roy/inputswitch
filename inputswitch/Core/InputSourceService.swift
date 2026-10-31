import AppKit
import Carbon
import Observation

/// A selectable keyboard input source (layout, input method, or input mode).
struct InputSource: Identifiable, Hashable, Sendable {
    /// Stable TIS identifier, e.g. `com.apple.keylayout.ABC`.
    let id: String
    /// Localized display name, e.g. "ABC" or "微信输入法".
    let name: String
    let iconURL: URL?
    /// Whether the icon is a monochrome template that should be tinted.
    let iconIsTemplate: Bool
}

/// Reads, observes, and selects keyboard input sources via Carbon's TIS API.
@Observable
final class InputSourceService {
    /// The currently selected input source.
    private(set) var current: InputSource?
    /// A non-observed snapshot for the menu bar's SwiftUI scene. The menu
    /// refreshes it when it opens instead of rebuilding on every switch.
    @ObservationIgnored private(set) var currentIDForMenu: String?
    /// All enabled, selectable keyboard input sources in system order.
    private(set) var sources: [InputSource] = []

    /// Called on the main thread whenever the selected input source changes.
    @ObservationIgnored var onSelectionChanged: ((InputSource) -> Void)?
    /// Called on the main thread when the set of enabled sources changes.
    @ObservationIgnored var onSourcesChanged: (([InputSource]) -> Void)?

    @ObservationIgnored private var observer: DistributedObserver?
    @ObservationIgnored private var iconCache: [String: NSImage] = [:]

    func start() {
        guard observer == nil else { return }
        refresh()

        let observer = DistributedObserver()
        observer.observe(kTISNotifySelectedKeyboardInputSourceChanged as String) { [weak self] in
            self?.selectionDidChange()
        }
        observer.observe(kTISNotifyEnabledKeyboardInputSourcesChanged as String) { [weak self] in
            self?.refresh()
            self?.onSourcesChanged?(self?.sources ?? [])
        }
        self.observer = observer
    }

    func stop() {
        observer = nil
    }

    func refresh() {
        sources = Self.enabledTISSources().compactMap { InputSource(tisSource: $0) }
        updateCurrent(Self.currentTISSource().flatMap { InputSource(tisSource: $0) })
    }

    func select(id: String) {
        guard let source = Self.enabledTISSources().first(where: {
            $0.string(for: kTISPropertyInputSourceID) == id
        }) else { return }
        TISSelectInputSource(source)
    }

    /// Returns the icon for a source, loading and caching it on first use.
    func icon(for source: InputSource) -> NSImage? {
        if let cached = iconCache[source.id] { return cached }
        guard let url = source.iconURL, let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = source.iconIsTemplate
        iconCache[source.id] = image
        return image
    }

    // MARK: - Private

    private func selectionDidChange() {
        guard let newSource = Self.currentTISSource().flatMap({ InputSource(tisSource: $0) }),
              newSource != current else { return }
        updateCurrent(newSource)
        onSelectionChanged?(newSource)
    }

    func updateCurrent(_ source: InputSource?) {
        current = source
        currentIDForMenu = source?.id
    }

    private static func enabledTISSources() -> [TISInputSource] {
        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ]
        return TISCreateInputSourceList(filter as CFDictionary, false)?
            .takeRetainedValue() as? [TISInputSource] ?? []
    }

    private static func currentTISSource() -> TISInputSource? {
        TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }
}

private extension InputSource {
    init?(tisSource source: TISInputSource) {
        guard let id = source.string(for: kTISPropertyInputSourceID),
              let name = source.string(for: kTISPropertyLocalizedName) else { return nil }
        self.init(
            id: id,
            name: name,
            iconURL: source.property(kTISPropertyIconImageURL, as: CFURL.self) as URL?,
            iconIsTemplate: source.property("TISIconIsTemplate" as CFString, as: CFBoolean.self)
                .map(CFBooleanGetValue) ?? false
        )
    }
}

private extension TISInputSource {
    func property<T>(_ key: CFString, as _: T.Type) -> T? {
        guard let pointer = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? T
    }

    func string(for key: CFString) -> String? {
        property(key, as: CFString.self) as String?
    }
}

/// Observes distributed notifications with `.deliverImmediately`, which is
/// required for a background (LSUIElement) app: AppKit otherwise suspends
/// distributed notification delivery while the app is inactive.
private final class DistributedObserver: NSObject {
    private var handlers: [String: () -> Void] = [:]

    func observe(_ name: String, handler: @escaping () -> Void) {
        handlers[name] = handler
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handle(_:)),
            name: Notification.Name(name),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc nonisolated private func handle(_ notification: Notification) {
        let name = notification.name.rawValue
        if Thread.isMainThread {
            MainActor.assumeIsolated { handlers[name]?() }
        } else {
            Task { @MainActor in self.handlers[name]?() }
        }
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
