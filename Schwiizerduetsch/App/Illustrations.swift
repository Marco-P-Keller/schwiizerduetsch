import SwiftUI

/// A jagged alpine ridge defined by normalised (x, y) points; filled to the bottom edge.
struct Ridge: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + first.x * rect.width, y: rect.minY + first.y * rect.height))
        for pt in points.dropFirst() {
            p.addLine(to: CGPoint(x: rect.minX + pt.x * rect.width, y: rect.minY + pt.y * rect.height))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Alpenglow scene: sunrise sky, snow-capped layered ridges, mist that melts into the page.
struct MountainScene: View {
    var fadeTo: Color = Theme.bg
    var showSun = true

    private static func pts(_ v: [(CGFloat, CGFloat)]) -> [CGPoint] { v.map { CGPoint(x: $0.0, y: $0.1) } }
    private let far = pts([(0, 0.55), (0.10, 0.40), (0.18, 0.50), (0.30, 0.28), (0.42, 0.48), (0.55, 0.34), (0.68, 0.52), (0.80, 0.30), (0.92, 0.46), (1, 0.42)])
    private let mid = pts([(0, 0.70), (0.12, 0.52), (0.22, 0.64), (0.36, 0.40), (0.48, 0.62), (0.62, 0.46), (0.76, 0.66), (0.88, 0.50), (1, 0.62)])
    private let near = pts([(0, 0.82), (0.14, 0.68), (0.28, 0.80), (0.44, 0.60), (0.58, 0.78), (0.74, 0.66), (0.90, 0.80), (1, 0.74)])

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Color(hex: 0xE3202D), Color(hex: 0xF0584A), Color(hex: 0xFF9A6B), Color(hex: 0xFFD2A8)],
                               startPoint: .top, endPoint: .bottom)
                if showSun {
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: 0xFFF3C4), Color(hex: 0xFFE39A).opacity(0.0)],
                                             center: .center, startRadius: 6, endRadius: geo.size.width * 0.42))
                        .frame(width: geo.size.width * 0.84, height: geo.size.width * 0.84)
                        .position(x: geo.size.width * 0.74, y: geo.size.height * 0.52)
                    Circle().fill(Color(hex: 0xFFF6D8)).frame(width: 46, height: 46)
                        .position(x: geo.size.width * 0.74, y: geo.size.height * 0.46)
                        .shadow(color: Color(hex: 0xFFE39A).opacity(0.9), radius: 26)
                }
                ridge(far, top: Color.white, base: Color(hex: 0xC9A9D6)).opacity(0.85)
                    .frame(height: geo.size.height * 0.82)
                ridge(mid, top: Color.white.opacity(0.92), base: Color(hex: 0x7C68B4))
                    .frame(height: geo.size.height * 0.64)
                ridge(near, top: Color.white.opacity(0.7), base: Color(hex: 0x3D3876))
                    .frame(height: geo.size.height * 0.46)
                LinearGradient(colors: [fadeTo.opacity(0), fadeTo], startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.30)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private func ridge(_ points: [CGPoint], top: Color, base: Color) -> some View {
        Ridge(points: points)
            .fill(LinearGradient(colors: [top, base, base], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.75)))
    }
}

/// The app mark: red bubble with the umlaut «ü».
struct AppMark: View {
    var size: CGFloat = 96
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFF4450), Color(hex: 0xC4101D)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .strokeBorder(.white.opacity(0.35), lineWidth: 1.2)
            Text("ü").font(.system(size: size * 0.66, weight: .heavy, design: .rounded)).foregroundStyle(.white).offset(y: -size * 0.03)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.red.opacity(0.4), radius: size * 0.22, y: size * 0.1)
    }
}

/// Glassy stat pill that reads well on top of the illustration.
struct GlassPill: View {
    let systemName: String
    let tint: Color
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName).foregroundStyle(tint)
            Text(text).font(.numeric(15)).foregroundStyle(.white)
        }
        .padding(.horizontal, 13).padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
        .background(Color.black.opacity(0.10), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
    }
}
