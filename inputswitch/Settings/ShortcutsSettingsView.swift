import SwiftUI

struct ShortcutsSettingsView: View {
    let coordinator: AppCoordinator

    private var settings: AppSettings { coordinator.settings }

    var body: some View {
        @Bindable var settings = settings

        Form {
            if !coordinator.accessibility.isTrusted {
                Section {
                    AccessibilityStatusRow(permission: coordinator.accessibility)
                }
            }

            Section {
                ShortcutIllustration(key: settings.switchKey, isEnabled: settings.switchShortcutEnabled)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                Toggle("Tap a modifier key to switch", isOn: $settings.switchShortcutEnabled)

                Picker("Key", selection: $settings.switchKey) {
                    ForEach(SwitchKey.allCases) { key in
                        Text("\(Text(key.title)) \(key.symbol)").tag(key)
                    }
                }
                .disabled(!settings.switchShortcutEnabled)
            } header: {
                Text("Switch Input Source")
            } footer: {
                Text("Press and release the key on its own to move to the next input source. Shortcuts that use the key, like ⌘C, keep working as usual.")
            }

            Section {
                Toggle(isOn: $settings.fnDoubleTapEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Double-tap Fn (🌐)")
                        Text("Shows the HUD for the current input source.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Show Current Input Source")
            }
        }
        .formStyle(.grouped)
    }
}

/// "Tap ⌘ → next input source" diagram.
private struct ShortcutIllustration: View {
    let key: SwitchKey
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 18) {
            KeyCap(symbol: key.symbol, caption: key.title)
            Image(systemName: "arrow.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tertiary)
            Label("Next input source", systemImage: "globe")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.quaternary, in: Capsule())
        }
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.default, value: isEnabled)
        .accessibilityElement(children: .combine)
    }
}

private struct KeyCap: View {
    let symbol: String
    let caption: LocalizedStringResource

    var body: some View {
        VStack(spacing: 2) {
            Text(symbol)
                .font(.system(size: 22, weight: .medium))
            Text(caption)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72, minHeight: 52)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.18), radius: 0.5, y: 1)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}
