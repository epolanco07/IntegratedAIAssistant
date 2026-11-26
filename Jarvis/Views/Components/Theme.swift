import SwiftUI

enum Theme {
    static let background = Color(red: 0.025, green: 0.10, blue: 0.14)
    static let surface = Color(red: 0.045, green: 0.16, blue: 0.21)
    static let surfaceRaised = Color(red: 0.07, green: 0.23, blue: 0.29)
    static let accent = Color(red: 0.16, green: 0.84, blue: 1.00)
    static let accentDeep = Color(red: 0.03, green: 0.48, blue: 0.78)
    static let signalCore = Color(red: 0.78, green: 0.96, blue: 1.00)
    static let textPrimary = Color(red: 0.90, green: 0.98, blue: 1.00)
    static let textSecondary = Color(red: 0.58, green: 0.79, blue: 0.86)
    static let border = Color(red: 0.25, green: 0.78, blue: 0.90).opacity(0.20)
    static let success = Color(red: 0.30, green: 0.90, blue: 0.70)
    static let warning = Color(red: 1.00, green: 0.76, blue: 0.32)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.40)

}

struct JarvisBackground: View {
    var body: some View {
        ZStack {
            Theme.background
        }
        .ignoresSafeArea()
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            Circle().fill(Theme.accentDeep)
            Circle().strokeBorder(Theme.accent.opacity(0.75), lineWidth: 1)
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
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0 : (sin(timeline.date.timeIntervalSinceReferenceDate * 2.2) + 1) / 2
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(signalColor.opacity(0.12 + Double(index) * 0.05), lineWidth: 1)
                        .frame(width: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : phase * 2), height: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : phase * 2))
                }
                Circle().fill(Theme.surface).frame(width: 198, height: 198)
                Circle().strokeBorder(signalColor.opacity(0.5), lineWidth: 1).frame(width: 188, height: 188)
                Circle().fill(signalColor.opacity(isActive ? 0.74 : 0.42)).frame(width: 152, height: 152)
                Circle().strokeBorder(.white.opacity(0.28), lineWidth: 1).frame(width: 116, height: 116)
                Circle().fill(Theme.background).frame(width: 88, height: 88)
                Circle()
                    .fill(RadialGradient(colors: [Theme.signalCore, signalColor, Theme.accentDeep], center: .topLeading, startRadius: 1, endRadius: 36))
                    .frame(width: 50, height: 50)
                    .shadow(color: signalColor.opacity(isActive ? 0.32 : 0.14), radius: isActive ? 22 : 12, y: 6)
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
