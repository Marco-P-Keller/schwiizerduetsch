import SwiftUI

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) { self.init(UIColor(hex: hex)) }
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum Theme {
    static let red = Color(hex: 0xE5202E)
    static let redDeep = Color(hex: 0xB3121F)
    static let green = Color(hex: 0x2FB36D)
    static let greenDeep = Color(hex: 0x1F8F53)
    static let gold = Color(hex: 0xF5B335)
    static let blue = Color(hex: 0x2F80ED)
    static let orange = Color(hex: 0xFF8A3D)

    static let bg = Color.adaptive(light: 0xF8F4EC, dark: 0x111114)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x1D1D22)
    static let ink = Color.adaptive(light: 0x1E1E22, dark: 0xF4F1EA)
    static let muted = Color.adaptive(light: 0x6C6A72, dark: 0xA3A1AA)
    static let line = Color.adaptive(light: 0xE6DFD2, dark: 0x2E2E35)
    static let soft = Color.adaptive(light: 0xF0EADF, dark: 0x26262C)
}

extension Font {
    static func rounded(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    static func rounded(size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Chunky, tactile button like the best learning apps.
struct ChunkyButtonStyle: ButtonStyle {
    var color: Color = Theme.red
    var deep: Color = Theme.redDeep
    var textColor: Color = .white
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !disabled
        configuration.label
            .font(.rounded(.headline, .bold))
            .foregroundStyle(disabled ? Theme.muted : textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(disabled ? Theme.line : deep)
                        .offset(y: pressed ? 0 : 4)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(disabled ? Theme.soft : color)
                        .offset(y: pressed ? 4 : 0)
                }
            )
            .padding(.bottom, 4)
            .offset(y: pressed ? 2 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static var chunky: ChunkyButtonStyle { ChunkyButtonStyle() }
    static var chunkyGreen: ChunkyButtonStyle { ChunkyButtonStyle(color: Theme.green, deep: Theme.greenDeep) }
    static func chunky(disabled: Bool) -> ChunkyButtonStyle { ChunkyButtonStyle(disabled: disabled) }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(self.padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1.5))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardModifier(padding: padding)) }
}

/// Simple wrapping layout for word tiles.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            rowH = max(rowH, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
