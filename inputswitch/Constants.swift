import Foundation
import CoreGraphics

enum HUDConstants {
    static let fadeInDuration: TimeInterval = 0.25
    static let fadeOutDuration: TimeInterval = 0.5
    static let defaultDisplayDuration: TimeInterval = 2.0
    static let minDisplayDuration: TimeInterval = 0.3
    static let maxDisplayDuration: TimeInterval = 5.0
    static let defaultBackgroundRed: CGFloat = 0.05
    static let defaultBackgroundGreen: CGFloat = 0.05
    static let defaultBackgroundBlue: CGFloat = 0.05
    static let defaultAlpha: CGFloat = 0.75
    static let cornerRadius: CGFloat = 18.0
    static let panelHeight: CGFloat = 90.0
    static let horizontalMargin: CGFloat = 30.0
    static let fontSize: CGFloat = 24.0
    static let iconSize: CGFloat = 48.0
    static let fnDoubleStrikeInterval: TimeInterval = 0.35
}

/// macOS key codes for distinguishing left/right modifier keys
enum KeyCode: UInt16 {
    case commandR = 54
    case commandL = 55
    case optionR  = 61
    case optionL  = 58
    case fn       = 63
}

/// Which modifier key is used for switching input source
enum SwitchHotKey: Int {
    case rightCommand = 0
    case rightOption  = 1
}

let kFnKeyMask: UInt = 0x800000

enum DefaultsKey {
    static let hotKeySwitchInputSource = "HotKeySwitchInputSource"
    static let hudDisplayDuration = "HudDisplayDuration"
    static let inputSourceColors = "InputSourceColors"
    static let knownInputSources = "KnownInputSources"
}
