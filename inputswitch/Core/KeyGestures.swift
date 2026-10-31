import AppKit

/// A right-hand modifier key that can be tapped on its own to switch input source.
enum SwitchKey: Int, CaseIterable, Identifiable, Sendable {
    // Raw values are persisted; keep 0 and 1 stable for existing users.
    case rightCommand = 0
    case rightOption = 1
    case rightShift = 2
    case rightControl = 3

    var id: Int { rawValue }

    var keyCode: UInt16 {
        switch self {
        case .rightCommand: 54
        case .rightOption: 61
        case .rightShift: 60
        case .rightControl: 62
        }
    }

    /// Device-dependent flag bit (from IOKit's `NX_DEVICER*KEYMASK`) that is set
    /// only while this *specific* physical key is held.
    var deviceMask: UInt {
        switch self {
        case .rightCommand: DeviceModifierMask.rightCommand
        case .rightOption: DeviceModifierMask.rightOption
        case .rightShift: DeviceModifierMask.rightShift
        case .rightControl: DeviceModifierMask.rightControl
        }
    }

    var symbol: String {
        switch self {
        case .rightCommand: "⌘"
        case .rightOption: "⌥"
        case .rightShift: "⇧"
        case .rightControl: "⌃"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .rightCommand: "Right Command"
        case .rightOption: "Right Option"
        case .rightShift: "Right Shift"
        case .rightControl: "Right Control"
        }
    }
}

/// Device-dependent modifier bits carried in `NSEvent.modifierFlags.rawValue`.
enum DeviceModifierMask {
    static let leftControl: UInt = 0x0001
    static let leftShift: UInt = 0x0002
    static let rightShift: UInt = 0x0004
    static let leftCommand: UInt = 0x0008
    static let rightCommand: UInt = 0x0010
    static let leftOption: UInt = 0x0020
    static let rightOption: UInt = 0x0040
    static let rightControl: UInt = 0x2000

    static let all: UInt = leftControl | leftShift | rightShift | leftCommand
        | rightCommand | leftOption | rightOption | rightControl
}

enum KeyCode {
    static let fn: UInt16 = 63
}

/// Recognizes a "solo tap" of a modifier key: pressed and released on its own,
/// quickly, with no other key, modifier, or mouse button used in between.
///
/// Pure value type so the logic can be unit-tested without real events.
struct SoloModifierRecognizer {
    var maximumHoldDuration: TimeInterval

    private var pressedAt: TimeInterval?
    private var interrupted = false

    init(maximumHoldDuration: TimeInterval = GestureTiming.maximumSoloHoldDuration) {
        self.maximumHoldDuration = maximumHoldDuration
    }

    /// Feed a `flagsChanged` event. Returns `true` when a solo tap completes.
    mutating func flagsChanged(
        keyCode: UInt16,
        rawFlags: UInt,
        timestamp: TimeInterval,
        target: SwitchKey
    ) -> Bool {
        guard keyCode == target.keyCode else {
            // Any other modifier changing state spoils the tap.
            interrupt()
            return false
        }

        let otherModifiersHeld = rawFlags & (DeviceModifierMask.all & ~target.deviceMask) != 0

        if rawFlags & target.deviceMask != 0 {
            pressedAt = timestamp
            interrupted = otherModifiersHeld
            return false
        }

        defer {
            pressedAt = nil
            interrupted = false
        }
        guard let pressedAt, !interrupted, !otherModifiersHeld else { return false }
        return timestamp - pressedAt <= maximumHoldDuration
    }

    /// Call for key-down or mouse-down events while the modifier may be held.
    mutating func interrupt() {
        if pressedAt != nil { interrupted = true }
    }
}

/// Recognizes two presses of the same key within `interval`.
struct DoubleTapRecognizer {
    var interval: TimeInterval

    private var lastPressAt: TimeInterval?

    init(interval: TimeInterval = GestureTiming.doubleTapInterval) {
        self.interval = interval
    }

    /// Feed a key press. Returns `true` on the second press of a double-tap.
    mutating func press(at timestamp: TimeInterval) -> Bool {
        if let last = lastPressAt, timestamp - last <= interval {
            lastPressAt = nil
            return true
        }
        lastPressAt = timestamp
        return false
    }

    mutating func reset() {
        lastPressAt = nil
    }
}
