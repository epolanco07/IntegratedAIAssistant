import SwiftUI

struct ChatView: View {
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Planning my week").font(.title3.weight(.semibold))
                    Text("Sample conversation. Not connected.").font(.caption).foregroundStyle(Theme.warning)
                }
                Spacer()
                Button {} label: { Label("New", systemImage: "square.and.pencil") }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider().overlay(Theme.border)

            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(ChatMessage.samples) { MessageView(message: $0) }
                    thinkingRow
                }
                .padding(24)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message JARVIS…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...8)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))

                Button {} label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Theme.accentGradient, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }

    /// Static preview of the "thinking" state.
    private var thinkingRow: some View {
        HStack(spacing: 10) {
            AssistantAvatar()
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(Theme.accent.opacity(0.6)).frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Spacer()
        }
    }
}
