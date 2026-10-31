import SwiftUI

/// Contents of the menu bar extra's dropdown menu.
struct MenuBarContent: View {
    let coordinator: AppCoordinator

    private var inputSources: InputSourceService { coordinator.inputSources }

    var body: some View {
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

        Button("Settings…") { coordinator.showSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") { coordinator.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }

    private var currentSourceBinding: Binding<String?> {
        Binding(
            get: { inputSources.current?.id },
            set: { id in if let id { inputSources.select(id: id) } }
        )
    }
}
