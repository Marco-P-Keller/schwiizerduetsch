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

/// Design tokens. Swiss editorial: warm paper, deep ink, one confident red.
enum Theme {
    static let red = Color(hex: 0xE3202D)
    static let redDeep = Color(hex: 0xB0131E)
    static let green = Color(hex: 0x23A669)
    static let greenDeep = Color(hex: 0x178350)
    static let gold = Color(hex: 0xF2B035)
    static let goldDeep = Color(hex: 0xCB8A10)
    static let blue = Color(hex: 0x3461F0)
    static let orange = Color(hex: 0xFF7A3D)

    static let bg = Color.adaptive(light: 0xF6F1E8, dark: 0x0F0F12)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x1A1A1F)
    static let ink = Color.adaptive(light: 0x17171A, dark: 0xF4F1EB)
    static let muted = Color.adaptive(light: 0x65636D, dark: 0xA3A1AB)
    static let line = Color.adaptive(light: 0xE9E2D5, dark: 0x2B2B32)
    static let soft = Color.adaptive(light: 0xEFE8DA, dark: 0x25252B)

    static var redGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xF03A46), Color(hex: 0xC8101E)], startPoint: .top, endPoint: .bottom)
    }
}

extension Font {
    /// Clean grotesk text (SF Pro) used everywhere in the UI.
    static func ui(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
    static func ui(size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Editorial serif used for Swiss German phrases and big headlines.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Numerals with a friendly rounded feel.
    static func numeric(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Buttons

/// Primary button: confident gradient, soft coloured shadow, springy press.
struct ChunkyButtonStyle: ButtonStyle {
    var color: Color = Color(hex: 0xF03A46)
    var deep: Color = Color(hex: 0xC8101E)
    var textColor: Color = .white
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !disabled
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        configuration.label
            .font(.ui(.headline, .bold))
            .tracking(0.3)
            .foregroundStyle(disabled ? Theme.muted : textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                shape.fill(disabled
                           ? AnyShapeStyle(Theme.soft)
                           : AnyShapeStyle(LinearGradient(colors: [color, deep], startPoint: .top, endPoint: .bottom)))
            )
            .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(disabled ? 0 : 0.45), .clear],
                                                        startPoint: .top, endPoint: .center), lineWidth: 1))
            .shadow(color: disabled ? .clear : deep.opacity(0.32), radius: pressed ? 4 : 14, y: pressed ? 2 : 8)
            .scaleEffect(pressed ? 0.975 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static var chunky: ChunkyButtonStyle { ChunkyButtonStyle() }
    static var chunkyGreen: ChunkyButtonStyle { ChunkyButtonStyle(color: Color(hex: 0x2DBE7B), deep: Theme.greenDeep) }
    static func chunky(disabled: Bool) -> ChunkyButtonStyle { ChunkyButtonStyle(disabled: disabled) }
}

// MARK: - Cards & surfaces

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(self.padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.line.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardModifier(padding: padding)) }

    /// Section title style.
    func eyebrow(_ color: Color = Theme.muted) -> some View {
        self.font(.ui(.caption, .bold)).tracking(1.2).textCase(.uppercase).foregroundStyle(color)
    }
}

/// Soft tinted circle behind an SF Symbol.
struct IconBadge: View {
    let systemName: String
    var tint: Color = Theme.red
    var size: CGFloat = 44
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.34, style: .continuous))
    }
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
