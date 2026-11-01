import SwiftUI

struct HUDSettingsView: View {
    let coordinator: AppCoordinator

    private var settings: AppSettings { coordinator.settings }

    private var previewSource: InputSource {
        coordinator.inputSources.current
            ?? InputSource(id: "preview", name: "ABC", iconURL: nil, iconIsTemplate: false)
    }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                HUDPreview(card: coordinator.card(for: previewSource))
                    .listRowInsets(EdgeInsets())
            } footer: {
                HStack {
                    Spacer()
                    Button("Show on Screen", systemImage: "play.fill") {
                        coordinator.previewHUD(for: nil)
                    }
                }
            }

            Section("Appearance") {
                Picker("Style", selection: $settings.hudStyle) {
                    ForEach(HUDStyle.allCases) { Text($0.title).tag($0) }
                }
                if #available(macOS 26, *), settings.hudStyle == .glass {
                    Picker("Glass", selection: $settings.hudGlassVariant) {
                        ForEach(HUDGlassVariant.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if settings.hudGlassVariant == .clear {
                        LabeledContent("Dimming") {
                            HStack(spacing: 10) {
                                Slider(value: $settings.hudGlassDimming, in: HUDGlassLook.dimmingRange, step: 0.05)
                                    .frame(maxWidth: 220)
                                Text(settings.hudGlassDimming, format: .percent.precision(.fractionLength(0)))
                                    .monospacedDigit()
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
                Picker("Size", selection: $settings.hudSize) {
                    ForEach(HUDSize.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Position", selection: $settings.hudPosition) {
                    ForEach(HUDPosition.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show input source icon", isOn: $settings.hudShowsIcon)
            }

            Section {
                LabeledContent("Display duration") {
                    HStack(spacing: 10) {
                        Slider(value: $settings.hudDisplayDuration, in: HUDMetrics.displayDurationRange, step: 0.05)
                            .frame(maxWidth: 220)
                        Text(verbatim: settings.hudDisplayDuration.formatted(.number.precision(.fractionLength(1...2))) + " s")
                            .monospacedDigit()
                            .frame(width: 52, alignment: .trailing)
                    }
                }
            } header: {
                Text("Timing")
            } footer: {
                Text("Colors for each input source can be set in Input Sources.")
            }
        }
        .formStyle(.grouped)
    }
}
