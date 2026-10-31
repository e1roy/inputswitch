import Foundation
import Testing
@testable import inputswitch

// MARK: - Solo modifier tap

@MainActor
struct SoloModifierRecognizerTests {
    private let key = SwitchKey.rightCommand
    private var down: UInt { key.deviceMask | 0x100000 } // + device-independent ⌘ bit
    private let up: UInt = 0

    @Test func quickTapFires() {
        var recognizer = SoloModifierRecognizer()
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: down, timestamp: 1.0, target: key)
        #expect(!pressed)
        let released = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: up, timestamp: 1.1, target: key)
        #expect(released)
    }

    @Test func keyPressInBetweenCancels() {
        var recognizer = SoloModifierRecognizer()
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: down, timestamp: 1.0, target: key)
        recognizer.interrupt() // e.g. ⌘C
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: up, timestamp: 1.1, target: key)
        #expect(!pressed)
    }

    @Test func holdingTooLongDoesNotFire() {
        var recognizer = SoloModifierRecognizer(maximumHoldDuration: 0.5)
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: down, timestamp: 1.0, target: key)
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: up, timestamp: 2.0, target: key)
        #expect(!pressed)
    }

    @Test func otherModifierHeldAtPressDoesNotFire() {
        var recognizer = SoloModifierRecognizer()
        let withLeftShift = down | DeviceModifierMask.leftShift
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: withLeftShift, timestamp: 1.0, target: key)
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: DeviceModifierMask.leftShift, timestamp: 1.1, target: key)
        #expect(!pressed)
    }

    @Test func otherModifierPressedDuringHoldCancels() {
        var recognizer = SoloModifierRecognizer()
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: down, timestamp: 1.0, target: key)
        _ = recognizer.flagsChanged(keyCode: 56, rawFlags: down | DeviceModifierMask.leftShift, timestamp: 1.05, target: key)
        _ = recognizer.flagsChanged(keyCode: 56, rawFlags: down, timestamp: 1.08, target: key)
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: up, timestamp: 1.1, target: key)
        #expect(!pressed)
    }

    @Test func leftCommandDoesNotTriggerRightCommand() {
        var recognizer = SoloModifierRecognizer()
        let leftDown = DeviceModifierMask.leftCommand | 0x100000
        let pressed = recognizer.flagsChanged(keyCode: 55, rawFlags: leftDown, timestamp: 1.0, target: key)
        #expect(!pressed)
        let released = recognizer.flagsChanged(keyCode: 55, rawFlags: up, timestamp: 1.1, target: key)
        #expect(!released)
    }

    @Test func releasingRightWhileLeftHeldDoesNotFire() {
        var recognizer = SoloModifierRecognizer()
        let both = down | DeviceModifierMask.leftCommand
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: both, timestamp: 1.0, target: key)
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: DeviceModifierMask.leftCommand | 0x100000, timestamp: 1.1, target: key)
        #expect(!pressed)
    }

    @Test(arguments: SwitchKey.allCases)
    func everySwitchKeyCanFire(_ target: SwitchKey) {
        var recognizer = SoloModifierRecognizer()
        _ = recognizer.flagsChanged(keyCode: target.keyCode, rawFlags: target.deviceMask, timestamp: 1.0, target: target)
        let pressed = recognizer.flagsChanged(keyCode: target.keyCode, rawFlags: 0, timestamp: 1.1, target: target)
        #expect(pressed)
    }

    @Test func interruptWithoutPressIsHarmless() {
        var recognizer = SoloModifierRecognizer()
        recognizer.interrupt()
        _ = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: down, timestamp: 1.0, target: key)
        let pressed = recognizer.flagsChanged(keyCode: key.keyCode, rawFlags: up, timestamp: 1.1, target: key)
        #expect(pressed)
    }
}

// MARK: - Double tap

@MainActor
struct DoubleTapRecognizerTests {
    @Test func twoQuickPressesFire() {
        var recognizer = DoubleTapRecognizer(interval: 0.35)
        let first = recognizer.press(at: 1.0)
        #expect(!first)
        let second = recognizer.press(at: 1.2)
        #expect(second)
    }

    @Test func slowPressesDoNotFire() {
        var recognizer = DoubleTapRecognizer(interval: 0.35)
        let first = recognizer.press(at: 1.0)
        #expect(!first)
        let second = recognizer.press(at: 1.5)
        #expect(!second)
    }

    @Test func thirdPressStartsOver() {
        var recognizer = DoubleTapRecognizer(interval: 0.35)
        _ = recognizer.press(at: 1.0)
        let first = recognizer.press(at: 1.1)
        #expect(first)
        let second = recognizer.press(at: 1.2)
        #expect(!second)
    }

    @Test func resetCancelsPendingTap() {
        var recognizer = DoubleTapRecognizer(interval: 0.35)
        _ = recognizer.press(at: 1.0)
        recognizer.reset()
        let first = recognizer.press(at: 1.1)
        #expect(!first)
    }
}

// MARK: - Input source order

@MainActor
struct NextSourceTests {
    @Test func advancesAndWraps() {
        let ids = ["abc", "pinyin", "kana"]
        #expect(InputSourceService.nextSourceID(after: "abc", in: ids) == "pinyin")
        #expect(InputSourceService.nextSourceID(after: "kana", in: ids) == "abc")
    }

    @Test func unknownOrMissingCurrentFallsBackToFirst() {
        #expect(InputSourceService.nextSourceID(after: "other", in: ["a", "b"]) == "a")
        #expect(InputSourceService.nextSourceID(after: nil, in: ["a", "b"]) == "a")
    }

    @Test func emptyListHasNoNext() {
        #expect(InputSourceService.nextSourceID(after: "a", in: []) == nil)
    }
}

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
        #expect(settings.switchShortcutEnabled)
        #expect(settings.switchKey == .rightCommand)
        #expect(settings.fnDoubleTapEnabled)
        #expect(settings.hudStyle == .glass)
        #expect(settings.hudPosition == .center)
        #expect(settings.showMenuBarIcon)
    }

    @Test func changesPersist() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.switchKey = .rightOption
        settings.hudStyle = .solid
        settings.hudSize = .large
        settings.showMenuBarIcon = false

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.switchKey == .rightOption)
        #expect(reloaded.hudStyle == .solid)
        #expect(reloaded.hudSize == .large)
        #expect(!reloaded.showMenuBarIcon)
    }

    @Test func readsLegacyKeys() {
        let defaults = makeDefaults()
        defaults.set(SwitchKey.rightOption.rawValue, forKey: "HotKeySwitchInputSource")
        defaults.set(0.5, forKey: "HudDisplayDuration")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.switchKey == .rightOption)
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
