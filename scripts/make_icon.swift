import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation
import AppKit

let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func col(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat((hex >> 16) & 255) / 255, CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, a])!
}

// Background: Swiss red gradient
let grad = CGGradient(colorsSpace: cs, colors: [col(0xFF3B47), col(0xC8101E)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// soft highlight
let glow = CGGradient(colorsSpace: cs, colors: [col(0xFFFFFF, 0.22), col(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 330, y: 820), startRadius: 0, endCenter: CGPoint(x: 330, y: 820), endRadius: 620, options: [])

// Speech bubble
let bubble = CGRect(x: 150, y: 290, width: 724, height: 560)
let path = CGMutablePath()
path.addRoundedRect(in: bubble, cornerWidth: 190, cornerHeight: 190)
// tail (bottom-left)
let tail = CGMutablePath()
tail.move(to: CGPoint(x: 250, y: 330))
tail.addCurve(to: CGPoint(x: 190, y: 150), control1: CGPoint(x: 260, y: 250), control2: CGPoint(x: 240, y: 190))
tail.addCurve(to: CGPoint(x: 420, y: 300), control1: CGPoint(x: 300, y: 170), control2: CGPoint(x: 380, y: 240))
tail.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -26), blur: 50, color: col(0x000000, 0.28))
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
ctx.setFillColor(col(0xFFFFFF))
ctx.addPath(path); ctx.fillPath()
ctx.addPath(tail); ctx.fillPath()
ctx.endTransparencyLayer()
ctx.restoreGState()

// Big rounded "ü" — the Schwiizerdüütsch wink
import CoreText
let font = CTFontCreateWithName("ArialRoundedMTBold" as CFString, 560, nil)
let attrs: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(colorSpace: cs, components: [0.898, 0.125, 0.180, 1])!
]
let line = CTLineCreateWithAttributedString(NSAttributedString(string: "ü", attributes: attrs))
let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: bubble.midX - b.midX, y: bubble.midY - b.midY)
CTLineDraw(line, ctx)

let img = ctx.makeImage()!
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote", url.path)
