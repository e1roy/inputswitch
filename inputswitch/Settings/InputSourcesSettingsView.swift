import SwiftUI

struct InputSourcesSettingsView: View {
    let coordinator: AppCoordinator

    @State private var selectedID: String?

    private var inputSources: InputSourceService { coordinator.inputSources }
    private var appearance: HUDAppearanceStore { coordinator.appearance }

    private var selectedSource: InputSource? {
        let id = selectedID ?? inputSources.current?.id
        return inputSources.sources.first { $0.id == id } ?? inputSources.sources.first
    }

    var body: some View {
        Form {
            if let selectedSource {
                Section {
                    HUDPreview(card: coordinator.card(for: selectedSource), height: 150)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                if inputSources.sources.isEmpty {
                    ContentUnavailableView(
                        "No Input Sources",
                        systemImage: "keyboard",
                        description: Text("Add input sources in System Settings › Keyboard.")
                    )
                } else {
                    ForEach(inputSources.sources) { source in
                        InputSourceRow(
                            source: source,
                            icon: inputSources.icon(for: source),
                            tint: appearance.tint(for: source.id),
                            isCurrent: source.id == inputSources.current?.id,
                            isSelected: source.id == selectedSource?.id
                        ) {
                            selectedID = source.id
                        }
                    }
                }
            } header: {
                Text("Enabled Input Sources")
            } footer: {
                HStack {
                    Text("Select an input source to give its HUD a color.")
                    Spacer()
                    Button("Keyboard Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
            }

            if let selectedSource {
                TintEditor(
                    source: selectedSource,
                    tint: Binding(
                        get: { appearance.tint(for: selectedSource.id) },
                        set: { appearance.setTint($0, for: selectedSource.id) }
                    ),
                    onPreview: { coordinator.previewHUD(for: selectedSource) }
                )
            }
        }
        .formStyle(.grouped)
        .onAppear { inputSources.refresh() }
    }
}

private struct InputSourceRow: View {
    let source: InputSource
    let icon: NSImage?
    let tint: HUDTint?
    let isCurrent: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Group {
                    if let icon {
                        Image(nsImage: icon)
                            .renderingMode(icon.isTemplate ? .template : .original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "keyboard")
                    }
                }
                .frame(width: 20, height: 20)
                .foregroundStyle(.secondary)

                Text(source.name)
                    .lineLimit(1)

                if isCurrent {
                    Text("Current")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }

                Spacer()

                TintSwatch(tint: tint, size: 16)

                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
                    .opacity(isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Color + intensity controls for one input source's HUD.
private struct TintEditor: View {
    let source: InputSource
    @Binding var tint: HUDTint?
    let onPreview: () -> Void

    private static let presets: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink, .brown, .gray,
    ]
    private static let defaultOpacity = 0.7

    var body: some View {
        Section {
            LabeledContent("Color") {
                HStack(spacing: 6) {
                    swatchButton(nil)
                    ForEach(Self.presets.indices, id: \.self) { index in
                        swatchButton(Self.presets[index])
                    }
                }
            }

            ColorPicker("Custom Color", selection: customColor, supportsOpacity: false)

            LabeledContent("Intensity") {
                HStack(spacing: 10) {
                    Slider(value: opacity, in: HUDTint.opacityRange, step: 0.05)
                        .frame(maxWidth: 220)
                    Text(opacity.wrappedValue, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .disabled(tint == nil)

            HStack {
                Button("Reset to Default") { tint = nil }
                    .disabled(tint == nil)
                Spacer()
                Button("Show on Screen", systemImage: "play.fill", action: onPreview)
            }
        } header: {
            Text("HUD Color for “\(source.name)”")
        }
    }

    private func swatchButton(_ color: Color?) -> some View {
        let candidate = color.map { HUDTint($0, opacity: tint?.opacity ?? Self.defaultOpacity) }
        let isSelected = candidate.map { tint?.matchesColor(of: $0) ?? false } ?? (tint == nil)
        return Button {
            tint = candidate
        } label: {
            TintSwatch(tint: candidate, size: 18)
                .padding(2)
                .overlay {
                    Circle().strokeBorder(Color.accentColor, lineWidth: 2).opacity(isSelected ? 1 : 0)
                }
        }
        .buttonStyle(.plain)
        .help(color == nil ? Text("Default") : Text(verbatim: ""))
        .accessibilityLabel(color == nil ? Text("Default") : Text("Color"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { tint?.color ?? .gray },
            set: { tint = HUDTint($0, opacity: tint?.opacity ?? Self.defaultOpacity) }
        )
    }

    private var opacity: Binding<Double> {
        Binding(
            get: { tint?.opacity ?? Self.defaultOpacity },
            set: { newValue in tint?.opacity = newValue }
        )
    }
}

/// A small color dot; "default" is drawn as a split light/dark circle.
private struct TintSwatch: View {
    let tint: HUDTint?
    let size: CGFloat

    var body: some View {
        Group {
            if let tint {
                Circle().fill(tint.color)
            } else {
                Circle()
                    .fill(.background)
                    .overlay {
                        Image(systemName: "circle.lefthalf.filled")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .overlay { Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5) }
    }
}

private extension HUDTint {
    func matchesColor(of other: HUDTint) -> Bool {
        abs(red - other.red) < 0.01 && abs(green - other.green) < 0.01 && abs(blue - other.blue) < 0.01
    }
}
