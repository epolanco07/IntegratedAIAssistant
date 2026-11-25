import SwiftUI

struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser { Spacer(minLength: 80) } else { AssistantAvatar() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .textSelection(.enabled)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(message.isUser ? Theme.accentDeep.opacity(0.55) : Theme.surfaceRaised)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.border))
                Text(message.time).font(.caption2).foregroundStyle(Theme.textSecondary)
            }

            if !message.isUser { Spacer(minLength: 80) }
        }
    }
}
