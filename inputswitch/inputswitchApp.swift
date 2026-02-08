import SwiftUI

@main
struct inputswitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var loginItemManager = LoginItemManager()

    var body: some Scene {
        MenuBarExtra("inputswitch", image: "StatusBarIcon") {
            Button(loginItemManager.isEnabled ? "✓ Launch at Login" : "  Launch at Login") {
                loginItemManager.toggle()
            }
            Divider()
            SettingsLink {
                Text("Preferences...")
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            TabView {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                AppearanceSettingsView()
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }
}
