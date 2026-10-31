import Foundation
import Observation
import Testing
@testable import inputswitch

// MARK: - Persistence

@MainActor
private func makeDefaults() -> UserDefaults {
    let name = "inputswitch.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@MainActor
struct AppSettingsTests {
    @Test func defaultsAreSensible() {
        let settings = AppSettings(defaults: makeDefaults())
        #expect(settings.hudStyle == .glass)
        #expect(settings.hudPosition == .center)
        #expect(settings.showMenuBarIcon)
    }

    @Test func changesPersist() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hudStyle = .solid
        settings.hudSize = .large
        settings.showMenuBarIcon = false

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.hudStyle == .solid)
        #expect(reloaded.hudSize == .large)
        #expect(!reloaded.showMenuBarIcon)
    }

    @Test func readsLegacyKeys() {
        let defaults = makeDefaults()
        defaults.set(0.5, forKey: "HudDisplayDuration")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.hudDisplayDuration == 0.5)
    }

    @Test func durationIsClamped() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.hudDisplayDuration = 60
        #expect(settings.hudDisplayDuration == 1.0)
        settings.hudDisplayDuration = 0
        #expect(settings.hudDisplayDuration == 0.1)
    }

    @Test func longLegacyDurationIsClampedOnLoad() {
        let defaults = makeDefaults()
        defaults.set(2.0, forKey: "HudDisplayDuration") // old default
        #expect(AppSettings(defaults: defaults).hudDisplayDuration == 1.0)
    }
}

@MainActor
struct HUDAppearanceStoreTests {
    private let pinyin = InputSource(id: "com.apple.inputmethod.SCIM.ITABC", name: "Pinyin", iconURL: nil, iconIsTemplate: false)

    @Test func tintRoundTrips() {
        let defaults = makeDefaults()
        let tint = HUDTint(red: 0.2, green: 0.7, blue: 0.4, opacity: 0.6)
        HUDAppearanceStore(defaults: defaults).setTint(tint, for: pinyin.id)
        #expect(HUDAppearanceStore(defaults: defaults).tint(for: pinyin.id) == tint)
    }

    @Test func resetRemovesTint() {
        let store = HUDAppearanceStore(defaults: makeDefaults())
        store.setTint(HUDTint(red: 1, green: 0, blue: 0, opacity: 1), for: pinyin.id)
        store.setTint(nil, for: pinyin.id)
        #expect(store.tint(for: pinyin.id) == nil)
    }

    @Test func opacityIsClamped() {
        let store = HUDAppearanceStore(defaults: makeDefaults())
        store.setTint(HUDTint(red: 1, green: 0, blue: 0, opacity: 0), for: pinyin.id)
        #expect(store.tint(for: pinyin.id)?.opacity == HUDTint.opacityRange.lowerBound)
    }

    @Test func migratesLegacyNameKeyedColors() {
        let defaults = makeDefaults()
        defaults.set([
            "Pinyin": ["r": 0.1, "g": 0.2, "b": 0.3, "a": 0.5],
            "Uninstalled": ["r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0],
        ], forKey: DefaultsKey.legacyInputSourceColors)

        let store = HUDAppearanceStore(defaults: defaults)
        store.migrateLegacyColors(for: [pinyin])

        #expect(store.tint(for: pinyin.id) == HUDTint(red: 0.1, green: 0.2, blue: 0.3, opacity: 0.5))
        let remaining = defaults.dictionary(forKey: DefaultsKey.legacyInputSourceColors)
        #expect(remaining?.keys.sorted() == ["Uninstalled"])
    }
}

@MainActor
struct HUDTintTests {
    @Test func lightColorsPreferDarkText() {
        #expect(HUDTint(red: 1, green: 0.95, blue: 0.3, opacity: 0.9).prefersDarkForeground)
        #expect(!HUDTint(red: 0.1, green: 0.2, blue: 0.6, opacity: 0.9).prefersDarkForeground)
    }

    @Test func faintTintsKeepLightText() {
        #expect(!HUDTint(red: 1, green: 1, blue: 1, opacity: 0.2).prefersDarkForeground)
    }
}

// MARK: - Switch-path retention guards

private final class ObservationChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.withLock { count += 1 }
    }

    var value: Int {
        lock.withLock { count }
    }
}

@MainActor
struct MenuBarObservationTests {
    private let abc = InputSource(id: "com.apple.keylayout.ABC", name: "ABC", iconURL: nil, iconIsTemplate: false)
    private let pinyin = InputSource(
        id: "com.tencent.inputmethod.wetype.pinyin",
        name: "WeType",
        iconURL: nil,
        iconIsTemplate: false
    )

    @Test func menuSnapshotDoesNotObserveCurrentChanges() {
        let service = InputSourceService()
        service.updateCurrent(abc)
        let changes = ObservationChangeCounter()

        withObservationTracking {
            _ = service.currentIDForMenu
        } onChange: {
            changes.increment()
        }
        service.updateCurrent(pinyin)

        #expect(changes.value == 0)
        #expect(service.currentIDForMenu == pinyin.id)
    }

    @Test func settingsStillObserveCurrentChanges() {
        let service = InputSourceService()
        service.updateCurrent(abc)
        let changes = ObservationChangeCounter()

        withObservationTracking {
            _ = service.current
        } onChange: {
            changes.increment()
        }
        service.updateCurrent(pinyin)

        #expect(changes.value == 1)
    }
}

@MainActor
struct SettingsWindowRetentionTests {
    @Test func closingSettingsReleasesItsViewGraph() {
        let coordinator = AppCoordinator(defaults: makeDefaults())
        coordinator.showSettings()
        #expect(coordinator.hasSettingsWindow)

        coordinator.closeSettingsForTesting()

        #expect(!coordinator.hasSettingsWindow)
    }
}
