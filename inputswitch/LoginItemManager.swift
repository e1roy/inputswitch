import ServiceManagement
import SwiftUI

@Observable
final class LoginItemManager {
    var isEnabled: Bool = false

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("LoginItemManager error: \(error)")
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
