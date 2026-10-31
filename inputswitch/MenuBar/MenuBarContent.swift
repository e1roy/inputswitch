import SwiftUI

/// Contents of the menu bar extra's dropdown menu.
struct MenuBarContent: View {
    let coordinator: AppCoordinator
    @State private var selectedSourceID: String?

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
            .onAppear {
                selectedSourceID = inputSources.currentIDForMenu
            }
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
            get: { selectedSourceID },
            set: { id in
                guard let id else { return }
                selectedSourceID = id
                inputSources.select(id: id)
            }
        )
    }
}
