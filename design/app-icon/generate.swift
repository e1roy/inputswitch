import AppKit
import CoreText

// Generates the Icon Composer layers for AppIcon.icon (1024×1024 canvas, y-down SVG).
// Motif matches the menu bar glyph: a keycap split diagonally, solid half with
// a cut-out "A", outlined half with "文".

let C: CGFloat = 1024

func glyphPath(_ s: String, font: NSFont) -> CGPath {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: font]))
    let out = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let f = (CTRunGetAttributes(run) as! [CFString: Any])[kCTFontAttributeName] as! CTFont
        let n = CTRunGetGlyphCount(run)
        var g = [CGGlyph](repeating: 0, count: n), p = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: n), &g)
        CTRunGetPositions(run, CFRange(location: 0, length: n), &p)
        for i in 0..<n {
            if let gp = CTFontCreatePathForGlyph(f, g[i], nil) {
                out.addPath(gp, transform: CGAffineTransform(translationX: p[i].x, y: p[i].y))
            }
        }
    }
    return out
}

/// Glyph centered at `c` (y-down canvas coords) with height `h`.
func glyph(_ s: String, _ font: NSFont, _ c: CGPoint, _ h: CGFloat) -> CGPath {
    let p = glyphPath(s, font: font).normalized()
    let b = p.boundingBoxOfPath
    let k = h / b.height
    // font space is y-up; flip into y-down
    var t = CGAffineTransform(translationX: c.x, y: c.y).scaledBy(x: k, y: -k).translatedBy(x: -b.midX, y: -b.midY)
    return p.copy(using: &t)!
}

func svgData(_ path: CGPath) -> String {
    var d = ""
    func f(_ v: CGFloat) -> String { String(format: "%.2f", v) }
    path.applyWithBlock { e in
        let pts = e.pointee.points
        switch e.pointee.type {
        case .moveToPoint: d += "M\(f(pts[0].x)) \(f(pts[0].y))"
        case .addLineToPoint: d += "L\(f(pts[0].x)) \(f(pts[0].y))"
        case .addQuadCurveToPoint: d += "Q\(f(pts[0].x)) \(f(pts[0].y)) \(f(pts[1].x)) \(f(pts[1].y))"
        case .addCurveToPoint: d += "C\(f(pts[0].x)) \(f(pts[0].y)) \(f(pts[1].x)) \(f(pts[1].y)) \(f(pts[2].x)) \(f(pts[2].y))"
        case .closeSubpath: d += "Z"
        @unknown default: break
        }
    }
    return d
}

func writeSVG(_ name: String, _ path: CGPath, dir: String) {
    let svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(C))" height="\(Int(C))" viewBox="0 0 \(Int(C)) \(Int(C))">
    <path fill="#FFFFFF" fill-rule="evenodd" d="\(svgData(path))"/>
    </svg>
    """
    try! svg.write(toFile: "\(dir)/\(name).svg", atomically: true, encoding: .utf8)
}

let latin = NSFont.systemFont(ofSize: 200, weight: .semibold)
let cjk = NSFont(name: "PingFangSC-Semibold", size: 200)!

// Keycap geometry (same proportions as the 18pt menu bar glyph, scaled up).
let capSide: CGFloat = 600
let cap = CGRect(x: (C - capSide) / 2, y: (C - capSide) / 2, width: capSide, height: capSide)
let radius: CGFloat = 156
let stroke: CGFloat = 46
let k = capSide / 15.5                  // menu bar glyph units → canvas
func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {   // menu bar coords (y-up, 18pt) → canvas
    CGPoint(x: cap.minX + (x - 1.25) * k, y: cap.maxY - (y - 1.25) * k)
}

let outer = CGPath(roundedRect: cap, cornerWidth: radius, cornerHeight: radius, transform: nil)
let innerRect = cap.insetBy(dx: stroke, dy: stroke)
let inner = CGPath(roundedRect: innerRect, cornerWidth: radius - stroke, cornerHeight: radius - stroke, transform: nil)

// Layer 1: solid top-left half of the keycap, "A" knocked out.
let triangle = CGMutablePath()
triangle.move(to: CGPoint(x: 0, y: 0)); triangle.addLine(to: CGPoint(x: C, y: 0)); triangle.addLine(to: CGPoint(x: 0, y: C))
triangle.closeSubpath()
let half = outer.intersection(triangle)
let a = glyph("A", latin, pt(5.7, 12.3), 5.0 * k)
let solid = half.subtracting(a)

// Layer 2: keycap ring (lower-right part is what shows) + "文".
let ring = outer.subtracting(inner).subtracting(half)
let wen = glyph("文", cjk, pt(12.3, 5.7), 5.6 * k)
let outline = ring.union(wen)

let dir = CommandLine.arguments[1]
writeSVG("solid", solid, dir: dir)
writeSVG("outline", outline, dir: dir)
print("ok")
