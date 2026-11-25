import SwiftUI

enum Theme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let surface = Color(red: 0.08, green: 0.09, blue: 0.13)
    static let surfaceRaised = Color(red: 0.12, green: 0.14, blue: 0.19)
    static let accent = Color(red: 0.27, green: 0.74, blue: 0.96)
    static let accentDeep = Color(red: 0.16, green: 0.42, blue: 0.88)
    static let signalViolet = Color(red: 0.48, green: 0.34, blue: 0.94)
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

struct CommandOrb: View {
    enum Mode { case idle, listening, speaking }
    let mode: Mode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isActive: Bool { mode != .idle }
    private var label: String {
        switch mode { case .idle: "Activate voice"; case .listening: "Listening"; case .speaking: "Speaking" }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { timeline in
            let phase = reduceMotion ? 0 : (sin(timeline.date.timeIntervalSinceReferenceDate * 2.2) + 1) / 2
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(signalColor.opacity(0.12 + Double(index) * 0.05), lineWidth: 1)
                        .frame(width: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : 0), height: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : 0))
                }
                Circle()
                    .fill(RadialGradient(colors: [signalColor.opacity(0.92), Theme.signalViolet.opacity(0.68), Theme.background], center: .topLeading, startRadius: 5, endRadius: 130))
                    .frame(width: 188, height: 188)
                    .shadow(color: signalColor.opacity(isActive ? 0.36 : 0.18), radius: isActive ? 28 : 14, y: 8)
                Image(systemName: mode == .speaking ? "waveform" : "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: mode == .speaking && !reduceMotion)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
        }
        .frame(width: 360, height: 360)
    }

    private var signalColor: Color { mode == .idle ? Theme.accentDeep : Theme.accent }
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
