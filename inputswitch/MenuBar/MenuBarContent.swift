import SwiftUI

/// Contents of the menu bar extra's dropdown menu.
struct MenuBarContent: View {
    let coordinator: AppCoordinator

    private var settings: AppSettings { coordinator.settings }
    private var inputSources: InputSourceService { coordinator.inputSources }

    var body: some View {
        @Bindable var settings = settings

        Section("Input Source") {
            Picker("Input Source", selection: currentSourceBinding) {
                ForEach(inputSources.sources) { source in
                    Text(source.name).tag(Optional(source.id))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }

        Divider()

        Toggle(isOn: $settings.switchShortcutEnabled) {
            Text("Switch with \(Text(settings.switchKey.title)) \(settings.switchKey.symbol)")
        }
        Button("Show Current Input Source") {
            coordinator.showCurrentInputSource()
        }

        if !coordinator.accessibility.isTrusted {
            Divider()
            Button("Grant Accessibility Access…", systemImage: "exclamationmark.triangle") {
                coordinator.showSettings(.general)
                coordinator.accessibility.request()
            }
        }

        Divider()

        Button("Settings…") { coordinator.showSettings() }
            .keyboardShortcut(",", modifiers: .command)
        Button("About InputSwitch") { coordinator.showSettings(.about) }

        Divider()

        Button("Quit InputSwitch") { coordinator.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }

    private var currentSourceBinding: Binding<String?> {
        Binding(
            get: { inputSources.current?.id },
            set: { id in if let id { inputSources.select(id: id) } }
        )
    }
}
