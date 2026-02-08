import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(DefaultsKey.hotKeySwitchInputSource) private var hotKeySelection: Int = SwitchHotKey.rightCommand.rawValue
    @AppStorage(DefaultsKey.hudDisplayDuration) private var displayDuration: Double = HUDConstants.defaultDisplayDuration

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Switch Input Source Shortcut")
                        .font(.headline)

                    Picker("", selection: $hotKeySelection) {
                        Text("Right Command ⌘")
                            .tag(SwitchHotKey.rightCommand.rawValue)
                        Text("Right Option ⌥")
                            .tag(SwitchHotKey.rightOption.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("HUD Display Duration")
                        .font(.headline)

                    HStack {
                        Slider(
                            value: $displayDuration,
                            in: HUDConstants.minDisplayDuration...HUDConstants.maxDisplayDuration,
                            step: 0.1
                        )
                        Text(String(format: "%.1fs", displayDuration))
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
