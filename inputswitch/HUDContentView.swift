import SwiftUI

struct HUDContentView: View {
    let inputSourceName: String
    let iconURL: URL?
    let backgroundColor: Color
    let backgroundOpacity: Double

    var body: some View {
        HStack(spacing: 12) {
            if let iconURL = iconURL, let nsImage = NSImage(contentsOf: iconURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: HUDConstants.iconSize, height: HUDConstants.iconSize)
            }
            Text(inputSourceName)
                .font(.system(size: HUDConstants.fontSize, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, HUDConstants.horizontalMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: HUDConstants.cornerRadius)
                .fill(backgroundColor.opacity(backgroundOpacity))
        )
    }
}
