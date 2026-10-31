import SwiftUI

struct GeneralSettingsView: View {
    let coordinator: AppCoordinator

    private var settings: AppSettings { coordinator.settings }
    private var loginItem: LoginItemService { coordinator.loginItem }
    private var accessibility: AccessibilityPermission { coordinator.accessibility }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                StatusHeader(coordinator: coordinator)
            }

            Section {
                AccessibilityStatusRow(permission: accessibility)
            } header: {
                Text("Permissions")
            } footer: {
                if !accessibility.isTrusted {
                    Text("macOS requires Accessibility access for InputSwitch to notice when you tap a modifier key. InputSwitch never records what you type.")
                }
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
                Text("Input source switching and the HUD stop working until InputSwitch is opened again.")
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

    @ViewBuilder
    private var statusLine: some View {
        let settings = coordinator.settings
        if !coordinator.accessibility.isTrusted {
            Label("Waiting for Accessibility access", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        } else if settings.switchShortcutEnabled {
            Label {
                Text("Tap \(Text(settings.switchKey.title)) \(settings.switchKey.symbol) to switch input source")
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
            .foregroundStyle(.secondary)
        } else {
            Label("Shortcut is off — HUD still shows on every switch", systemImage: "pause.circle.fill")
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessibilityStatusRow: View {
    let permission: AccessibilityPermission

    var body: some View {
        LabeledContent {
            if permission.isTrusted {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.green)
            } else {
                Button("Grant Access…") { permission.request() }
                    .buttonStyle(.borderedProminent)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility")
                    Text(permission.isTrusted
                         ? "Keyboard shortcuts are active."
                         : "Required for keyboard shortcuts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "accessibility")
                    .foregroundStyle(.tint)
            }
        }
    }
}
