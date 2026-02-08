import SwiftUI

struct AppearanceSettingsView: View {
    var colorManager = InputSourceColorManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if colorManager.knownInputSources.isEmpty {
                VStack(spacing: 12) {
                    Text("No Input Sources Recorded")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Switch between input sources to see them appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(colorManager.knownInputSources, id: \.self) { name in
                        InputSourceColorRow(name: name, colorManager: colorManager)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 450, height: 300)
    }
}

struct InputSourceColorRow: View {
    let name: String
    var colorManager: InputSourceColorManager

    @State private var selectedColor: Color
    @State private var opacity: Double

    init(name: String, colorManager: InputSourceColorManager) {
        self.name = name
        self.colorManager = colorManager
        let nsColor = colorManager.colorForInputSource(name)
        _selectedColor = State(initialValue: Color(nsColor: nsColor))
        _opacity = State(initialValue: Double(colorManager.alphaForInputSource(name)))
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)

            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: selectedColor) { _, newColor in
                    if let nsColor = NSColor(newColor).usingColorSpace(.sRGB) {
                        colorManager.setColor(nsColor, forInputSource: name)
                    }
                }

            Text("Opacity")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $opacity, in: 0.1...1.0, step: 0.05)
                .frame(width: 120)
                .onChange(of: opacity) { _, newValue in
                    colorManager.setAlpha(CGFloat(newValue), forInputSource: name)
                }

            Text(String(format: "%.0f%%", opacity * 100))
                .frame(width: 40, alignment: .trailing)
                .monospacedDigit()
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
