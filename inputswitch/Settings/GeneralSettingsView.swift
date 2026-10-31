import SwiftUI

struct GeneralSettingsView: View {
    let coordinator: AppCoordinator

    private var settings: AppSettings { coordinator.settings }
    private var loginItem: LoginItemService { coordinator.loginItem }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                StatusHeader(coordinator: coordinator)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                ))

                if loginItem.requiresApproval {
                    LabeledContent {
                        Button("Open Login Items…") { loginItem.openSystemSettings() }
                    } label: {
                        Label("Approve InputSwitch in Login Items to finish setup.", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                if let error = loginItem.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                Toggle("Show icon in menu bar", isOn: $settings.showMenuBarIcon)
            } header: {
                Text("Startup")
            } footer: {
                if !settings.showMenuBarIcon {
                    Text("To get back here, open InputSwitch again from Applications, Launchpad, or Spotlight.")
                }
            }

            Section {
                LabeledContent("Quit InputSwitch") {
                    Button("Quit", role: .destructive) { coordinator.quit() }
                }
            } footer: {
                Text("The HUD stops showing until InputSwitch is opened again.")
            }
        }
        .formStyle(.grouped)
    }
}

/// App identity, live status, and the current input source.
private struct StatusHeader: View {
    let coordinator: AppCoordinator

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("InputSwitch")
                    .font(.title2.weight(.semibold))
                statusLine
                    .font(.callout)
            }

            Spacer(minLength: 12)

            if let current = coordinator.inputSources.current {
                Button {
                    coordinator.previewHUD(for: current)
                } label: {
                    Label(current.name, systemImage: "character.cursor.ibeam")
                        .lineLimit(1)
                }
                .help(Text("Show the HUD for the current input source"))
            }
        }
        .padding(.vertical, 6)
    }

    private var statusLine: some View {
        Label {
            Text("Shows the HUD whenever the input source changes")
        } icon: {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
        .foregroundStyle(.secondary)
    }
}
