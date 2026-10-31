import ImageIO
import SwiftUI

/// Renders a HUD card over the user's wallpaper so Liquid Glass and tints can
/// be judged in context.
struct HUDPreview: View {
    let card: HUDCard
    var height: CGFloat = 180

    @State private var wallpaper: NSImage?

    var body: some View {
        ZStack {
            background
            card
                .padding(24)
                .animation(.smooth, value: card.name)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task { wallpaper = await Self.loadWallpaper() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("HUD preview"))
    }

    @ViewBuilder
    private var background: some View {
        if let wallpaper {
            Image(nsImage: wallpaper)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            LinearGradient(
                colors: [.indigo, .purple, .orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Loads a downsampled copy of the current desktop picture off the main thread.
    private static func loadWallpaper() async -> NSImage? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first,
              let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        let cgImage = await Task.detached(priority: .utility) { () -> CGImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 1200,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value
        return cgImage.map { NSImage(cgImage: $0, size: .zero) }
    }
}
