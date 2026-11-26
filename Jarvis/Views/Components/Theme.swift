import SwiftUI

enum Theme {
    static let background = Color.black
    static let surface = Color(red: 0.027, green: 0.145, blue: 0.247)
    static let surfaceRaised = Color(red: 0.039, green: 0.25, blue: 0.39)
    static let accent = Color(red: 0.22, green: 0.91, blue: 1.0)
    static let accentDeep = Color(red: 0.02, green: 0.46, blue: 0.78)
    static let signalCore = Color(red: 0.90, green: 0.98, blue: 1.0)
    static let textPrimary = Color(red: 0.81, green: 0.94, blue: 1.0)
    static let textSecondary = Color(red: 0.37, green: 0.71, blue: 0.84)
    static let border = Color(red: 0.22, green: 0.91, blue: 1.0).opacity(0.82)
    static let success = Color(red: 0.30, green: 0.90, blue: 0.70)
    static let warning = Color(red: 1.00, green: 0.76, blue: 0.32)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.40)

}

struct ChamferedRectangle: Shape {
    var cut: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }
}

struct JarvisBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            Canvas { context, size in
                var grid = Path()
                let spacing: CGFloat = 38
                for x in stride(from: 0, through: size.width, by: spacing) {
                    grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(Theme.accent.opacity(0.12)), lineWidth: 0.5)
            }
            RadialGradient(colors: [.clear, Theme.background.opacity(0.88)], center: .center, startRadius: 220, endRadius: 900)
        }
        .ignoresSafeArea()
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background {
                ChamferedRectangle(cut: 10).fill(Theme.surface.opacity(0.6))
            }
            .overlay {
                ChamferedRectangle(cut: 10).stroke(Theme.border, lineWidth: 1)
            }
            .shadow(color: Theme.accent.opacity(0.16), radius: 7)
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
                        .stroke(signalColor.opacity(0.42 + Double(index) * 0.10), lineWidth: 1)
                        .frame(width: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : phase * 2), height: 180 + CGFloat(index) * 58 + (isActive ? phase * 10 : phase * 2))
                }
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .trim(from: 0.04, to: 0.20)
                        .stroke(signalColor.opacity(0.95), style: StrokeStyle(lineWidth: 2, lineCap: .square))
                        .frame(width: 230 + CGFloat(index) * 28, height: 230 + CGFloat(index) * 28)
                        .rotationEffect(.degrees(Double(index) * 91 + phase * (isActive ? 55 : 8)))
                }
                Circle().fill(Theme.surface).frame(width: 198, height: 198)
                Circle().strokeBorder(signalColor.opacity(0.9), lineWidth: 1).frame(width: 188, height: 188)
                Circle().fill(signalColor.opacity(isActive ? 0.90 : 0.60)).frame(width: 152, height: 152)
                Circle().strokeBorder(Theme.signalCore.opacity(0.65), lineWidth: 1).frame(width: 116, height: 116)
                Circle().fill(Theme.background).frame(width: 88, height: 88)
                Circle()
                    .fill(RadialGradient(colors: [Theme.signalCore, signalColor, Theme.accentDeep], center: .topLeading, startRadius: 1, endRadius: 36))
                    .frame(width: 50, height: 50)
                    .shadow(color: signalColor.opacity(1), radius: isActive ? 12 : 8)
                    .shadow(color: signalColor.opacity(0.78), radius: isActive ? 34 : 22)
                Text("ARTHUR")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(Theme.background)
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
