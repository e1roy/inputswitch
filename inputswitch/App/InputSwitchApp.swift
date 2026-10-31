import SwiftUI

@main
struct InputSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        @Bindable var settings = appDelegate.coordinator.settings

        MenuBarExtra(isInserted: $settings.showMenuBarIcon) {
            MenuBarContent(coordinator: appDelegate.coordinator)
        } label: {
            Image("StatusBarIcon")
                .accessibilityLabel("InputSwitch")
        }
        .menuBarExtraStyle(.menu)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { appDelegate.coordinator.showSettings() }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
