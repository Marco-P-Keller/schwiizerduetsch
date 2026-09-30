import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation
import AppKit
import CoreText

// usage: compose_shot raw.png out.png "Headline line1|line2" "subtitle" variant(0-2)
let a = CommandLine.arguments
let W = 1320, H = 2868
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func col(_ h: UInt32, _ al: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [CGFloat((h >> 16) & 255) / 255, CGFloat((h >> 8) & 255) / 255, CGFloat(h & 255) / 255, al])! }

let variants: [(UInt32, UInt32)] = [(0xFF3B47, 0xB3121F), (0xE5202E, 0x8E0F1A), (0xF2545B, 0xC8101E)]
let v = variants[(Int(a[5]) ?? 0) % 3]
let g = CGGradient(colorsSpace: cs, colors: [col(v.0), col(v.1)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: CGFloat(H)), end: CGPoint(x: CGFloat(W), y: 0), options: [])
let glow = CGGradient(colorsSpace: cs, colors: [col(0xFFFFFF, 0.20), col(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 1100, y: 2600), startRadius: 0, endCenter: CGPoint(x: 1100, y: 2600), endRadius: 900, options: [])

func drawText(_ s: String, size: CGFloat, y: CGFloat, alpha: CGFloat = 1, maxW: CGFloat = 1120) {
    var sz = size
    var line: CTLine
    repeat {
        let font = CTFontCreateWithName("ArialRoundedMTBold" as CFString, sz, nil)
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): col(0xFFFFFF, alpha)]
        line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        sz -= 2
    } while CTLineGetTypographicBounds(line, nil, nil, nil) > Double(maxW)
    let w = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    ctx.textPosition = CGPoint(x: (CGFloat(W) - w) / 2, y: CGFloat(H) - y)
    CTLineDraw(line, ctx)
}
let lines = a[3].split(separator: "|").map(String.init)
var y: CGFloat = 250
for l in lines { drawText(l, size: 118, y: y); y += 140 }
drawText(a[4], size: 58, y: y + 30, alpha: 0.85)

// phone
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }!
let pw: CGFloat = 1010
let ph = pw * CGFloat(src.height) / CGFloat(src.width)
let px = (CGFloat(W) - pw) / 2
let top: CGFloat = y + 130               // distance from top of canvas
let rect = CGRect(x: px, y: CGFloat(H) - top - ph, width: pw, height: ph)
let r: CGFloat = 96
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -30), blur: 70, color: col(0x000000, 0.45))
ctx.setFillColor(col(0x111111))
ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: -16, dy: -16), cornerWidth: r + 16, cornerHeight: r + 16, transform: nil)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)); ctx.clip()
ctx.draw(src, in: rect)
ctx.restoreGState()

let out = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, out, nil); CGImageDestinationFinalize(dest)
