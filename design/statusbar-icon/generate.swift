import AppKit
import CoreText

// Canvas in points (menu bar template image).
let S: CGFloat = 18

func glyphPath(_ s: String, font: NSFont) -> CGPath {
    let attr = NSAttributedString(string: s, attributes: [.font: font])
    let line = CTLineCreateWithAttributedString(attr)
    let out = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let attrs = CTRunGetAttributes(run) as! [CFString: Any]
        let f = attrs[kCTFontAttributeName] as! CTFont
        let n = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: n)
        var pos = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: n), &glyphs)
        CTRunGetPositions(run, CFRange(location: 0, length: n), &pos)
        for i in 0..<n {
            if let p = CTFontCreatePathForGlyph(f, glyphs[i], nil) {
                out.addPath(p, transform: CGAffineTransform(translationX: pos[i].x, y: pos[i].y))
            }
        }
    }
    return out
}

/// Glyph path whose bounding box is centered at `c`, scaled so its height is `h`.
func centered(_ s: String, font: NSFont, at c: CGPoint, height h: CGFloat) -> CGPath {
    let p = glyphPath(s, font: font)
    let b = p.boundingBoxOfPath
    let k = h / b.height
    var t = CGAffineTransform(translationX: c.x, y: c.y)
        .scaledBy(x: k, y: k)
        .translatedBy(x: -b.midX, y: -b.midY)
    return p.copy(using: &t)!.normalized()
}

let latin = NSFont.systemFont(ofSize: 20, weight: .semibold)
let cjk = NSFont(name: "PingFangSC-Semibold", size: 20)!

typealias Draw = (CGContext) -> Void

// A: keycap outline, "A" top-left, "文" bottom-right.
let keycap: Draw = { ctx in
    let r = CGRect(x: 1.25, y: 1.25, width: 15.5, height: 15.5)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 4.2, cornerHeight: 4.2, transform: nil))
    ctx.setLineWidth(1.5)
    ctx.strokePath()
    ctx.addPath(centered("A", font: latin, at: CGPoint(x: 6.1, y: 11.9), height: 5.2))
    ctx.addPath(centered("文", font: cjk, at: CGPoint(x: 11.9, y: 6.1), height: 5.8))
    ctx.fillPath()
}

// B: filled keycap with "A" knocked out, small "文" badge corner.
let splitKeycap: Draw = { ctx in
    // Outline keycap
    let r = CGRect(x: 1.25, y: 1.25, width: 15.5, height: 15.5)
    let cap = CGPath(roundedRect: r, cornerWidth: 4.2, cornerHeight: 4.2, transform: nil)
    // Diagonal split: fill the top-left triangle region of the keycap
    ctx.saveGState()
    ctx.addPath(cap); ctx.clip()
    ctx.move(to: CGPoint(x: 0, y: 0)); ctx.addLine(to: CGPoint(x: 0, y: S)); ctx.addLine(to: CGPoint(x: S, y: S))
    ctx.closePath()
    ctx.addPath(centered("A", font: latin, at: CGPoint(x: 5.7, y: 12.3), height: 5.0))
    ctx.fillPath(using: .evenOdd)
    ctx.restoreGState()
    ctx.addPath(cap); ctx.setLineWidth(1.5); ctx.strokePath()
    ctx.addPath(centered("文", font: cjk, at: CGPoint(x: 12.3, y: 5.7), height: 5.6))
    ctx.fillPath()
}

// C: "A" and "文" with a two-arrow swap cycle, no frame.
let swap: Draw = { ctx in
    ctx.addPath(centered("A", font: latin, at: CGPoint(x: 5.2, y: 9), height: 6.2))
    ctx.addPath(centered("文", font: cjk, at: CGPoint(x: 12.8, y: 9), height: 6.8))
    ctx.fillPath()
    ctx.setLineWidth(1.3); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    // top arc A -> 文
    ctx.addArc(center: CGPoint(x: 9, y: 9), radius: 7.6, startAngle: .pi * 0.80, endAngle: .pi * 0.20, clockwise: true)
    ctx.strokePath()
    ctx.addArc(center: CGPoint(x: 9, y: 9), radius: 7.6, startAngle: -.pi * 0.20, endAngle: -.pi * 0.80, clockwise: true)
    ctx.strokePath()
    func head(_ a: CGFloat, _ dir: CGFloat) {
        let p = CGPoint(x: 9 + 7.6 * cos(a), y: 9 + 7.6 * sin(a))
        let tan = a - dir * .pi / 2
        let l: CGFloat = 2.2
        ctx.move(to: CGPoint(x: p.x + l * cos(tan + .pi - 0.6), y: p.y + l * sin(tan + .pi - 0.6)))
        ctx.addLine(to: p)
        ctx.addLine(to: CGPoint(x: p.x + l * cos(tan + .pi + 0.6), y: p.y + l * sin(tan + .pi + 0.6)))
        ctx.strokePath()
    }
    head(.pi * 0.20, 1)
    head(-.pi * 0.80, 1)
}

let variants: [(String, Draw)] = [("A_keycap", keycap), ("B_split", splitKeycap), ("C_swap", swap)]

let outDir = CommandLine.arguments[1]

func writePDF(_ name: String, _ d: Draw) {
    var box = CGRect(x: 0, y: 0, width: S, height: S)
    let url = URL(fileURLWithPath: "\(outDir)/\(name).pdf") as CFURL
    let ctx = CGContext(url, mediaBox: &box, nil)!
    ctx.beginPDFPage(nil)
    ctx.setFillColor(NSColor.black.cgColor); ctx.setStrokeColor(NSColor.black.cgColor)
    d(ctx)
    ctx.endPDFPage(); ctx.closePDF()
}

// Preview sheet: each variant at 1x/2x on light & dark bars, plus a 10x zoom.
func sheet() {
    let zoom: CGFloat = 10
    let cellW: CGFloat = S * zoom + 40
    let W = cellW * CGFloat(variants.count) + 20
    let H: CGFloat = S * zoom + 40 + 2 * 60 + 40
    let scale: CGFloat = 2
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(W * scale), height: Int(H * scale), bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: scale, y: scale)
    ctx.setFillColor(NSColor.white.cgColor); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    for (i, (_, d)) in variants.enumerated() {
        let x0 = 20 + CGFloat(i) * cellW
        // zoomed
        ctx.saveGState()
        ctx.translateBy(x: x0, y: 140 + 20)
        ctx.setFillColor(NSColor(white: 0.93, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: S * zoom, height: S * zoom))
        ctx.scaleBy(x: zoom, y: zoom)
        ctx.setFillColor(NSColor.black.cgColor); ctx.setStrokeColor(NSColor.black.cgColor)
        d(ctx)
        ctx.restoreGState()
        // menu bars
        for (j, (bg, fg)) in [(NSColor(white: 0.96, alpha: 1), NSColor(white: 0.1, alpha: 1)),
                              (NSColor(white: 0.16, alpha: 1), NSColor.white)].enumerated() {
            let y = 20 + CGFloat(j) * 60
            ctx.setFillColor(bg.cgColor); ctx.fill(CGRect(x: x0, y: y, width: S * zoom, height: 40))
            for (k, sc) in [CGFloat(1), 1.5].enumerated() {
                ctx.saveGState()
                ctx.translateBy(x: x0 + 30 + CGFloat(k) * 80, y: y + 20 - S * sc / 2)
                ctx.scaleBy(x: sc, y: sc)
                ctx.setFillColor(fg.cgColor); ctx.setStrokeColor(fg.cgColor)
                d(ctx)
                ctx.restoreGState()
            }
        }
    }
    let img = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: img)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/sheet.png"))
}

for (n, d) in variants { writePDF(n, d) }
sheet()
print("ok")
