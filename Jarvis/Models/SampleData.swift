import Foundation

// Static placeholder data used only to render the UI. Nothing here is live.

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, chat, voice, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .chat: return "Chat"
        case .voice: return "Voice"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .chat: return "bubble.left.and.bubble.right"
        case .voice: return "waveform.circle"
        case .settings: return "gearshape"
        }
    }
}

struct ConversationSummary: Identifiable {
    let id = UUID()
    let title: String
    let preview: String

    static let samples: [ConversationSummary] = [
        ConversationSummary(title: "Planning my week", preview: "What should I focus on this week?"),
        ConversationSummary(title: "Draft an email", preview: "Help me draft a polite follow-up."),
        ConversationSummary(title: "Study schedule", preview: "Sample conversation")
    ]
}

struct IntegrationItem: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let access: String
    let capabilities: String

    static let samples: [IntegrationItem] = [
        IntegrationItem(name: "Slack", systemImage: "number.square", access: "Direct API", capabilities: "Read channels · Send messages"),
        IntegrationItem(name: "Microsoft Teams", systemImage: "person.3", access: "Direct API", capabilities: "Read chats · Send messages"),
        IntegrationItem(name: "Google Calendar", systemImage: "calendar", access: "Direct API", capabilities: "Read events · Create events"),
        IntegrationItem(name: "Apple Reminders", systemImage: "checklist", access: "EventKit", capabilities: "Read · Create reminders"),
        IntegrationItem(name: "Outlook", systemImage: "envelope", access: "Graph or browser", capabilities: "Read mail · Draft replies"),
        IntegrationItem(name: "LSU Moodle", systemImage: "graduationcap", access: "Remote browser", capabilities: "Retrieve assignments"),
        IntegrationItem(name: "Workday", systemImage: "briefcase", access: "Remote browser", capabilities: "Check information")
    ]
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let when: String
    let systemImage: String

    static let samples: [ActivityItem] = [
        ActivityItem(title: "Application launched", detail: "Interface preview", when: "1 min ago", systemImage: "power"),
        ActivityItem(title: "Backend check", detail: "Not connected", when: "5 min ago", systemImage: "heart.text.square"),
        ActivityItem(title: "Sample task", detail: "Example activity entry", when: "1 hr ago", systemImage: "checklist")
    ]
}
