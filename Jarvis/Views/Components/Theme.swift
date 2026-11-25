import SwiftUI

enum Theme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let surface = Color(red: 0.08, green: 0.09, blue: 0.13)
    static let surfaceRaised = Color(red: 0.12, green: 0.14, blue: 0.19)
    static let accent = Color(red: 0.27, green: 0.74, blue: 0.96)
    static let accentDeep = Color(red: 0.16, green: 0.42, blue: 0.88)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.58)
    static let border = Color.white.opacity(0.08)
    static let success = Color(red: 0.30, green: 0.80, blue: 0.55)
    static let warning = Color(red: 0.96, green: 0.70, blue: 0.28)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.40)

    static let accentGradient = LinearGradient(
        colors: [accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct JarvisBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(colors: [Theme.accentDeep.opacity(0.16), .clear],
                           center: .topTrailing, startRadius: 20, endRadius: 600)
        }
        .ignoresSafeArea()
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.border))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

struct AssistantAvatar: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(Theme.accentGradient)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct StatusBadge: View {
    enum Kind {
        case connected, mock, neutral, error
        var color: Color {
            switch self {
            case .connected: return Theme.success
            case .mock: return Theme.warning
            case .neutral: return Theme.textSecondary
            case .error: return Theme.danger
            }
        }
    }

    let text: String
    let kind: Kind

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(kind.color).frame(width: 6, height: 6)
            Text(text).font(.caption2.weight(.medium))
        }
        .foregroundStyle(kind.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(kind.color.opacity(0.12), in: Capsule())
    }
}

struct SectionTitle: View {
    let text: String
    var trailing: String?

    init(_ text: String, trailing: String? = nil) {
        self.text = text
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.0)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if let trailing {
                Text(trailing).font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
