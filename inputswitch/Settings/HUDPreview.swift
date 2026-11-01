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
        .task { wallpaper = await WallpaperThumbnail.image() }
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
}

/// The downsized desktop picture behind the previews.
///
/// Every Settings page swap rebuilds `HUDPreview`, so decoding a copy per
/// appearance allocated a fresh 1200 px bitmap on each visit: the footprint of
/// an open Settings window grew ~6 MB per page change and never came back until
/// the window closed (P-SET-09 / run 20261101-105000). One image, decoded once
/// and sized for the largest preview, is reused instead.
@MainActor
private enum WallpaperThumbnail {
    /// Large enough for a 180 pt preview at 3× (540 px), with no extra copy of
    /// the desktop picture held in memory.
    nonisolated private static let maxPixelSize = 600
    private static var cachedKey: Key?
    private static var cachedImage: NSImage?
    private static var failedKey: Key?

    /// The picture can be rewritten in place, so the cache is keyed on the
    /// file's modification date as well as its path.
    private struct Key: Equatable {
        let url: URL
        let modified: Date
    }

    static func image() async -> NSImage? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first,
              let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        let modified = (try? FileManager.default
            .attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? .distantPast
        let key = Key(url: url, modified: modified)
        if key == cachedKey { return cachedImage }
        if key == failedKey { return nil }

        let cgImage = await Task.detached(priority: .utility) { () -> CGImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value

        guard let cgImage else {
            failedKey = key
            return nil
        }
        let image = NSImage(cgImage: cgImage, size: .zero)
        cachedKey = key
        cachedImage = image
        return image
    }
}
