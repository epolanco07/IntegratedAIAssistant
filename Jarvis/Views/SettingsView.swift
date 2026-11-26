import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general, appearance, voice, aiModel, integrations, remoteAgent, memory, privacy
    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .voice: return "Voice"
        case .aiModel: return "AI model"
        case .integrations: return "Integrations"
        case .remoteAgent: return "Remote agent"
        case .memory: return "Memory"
        case .privacy: return "Privacy & permissions"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .voice: return "waveform"
        case .aiModel: return "cpu"
        case .integrations: return "puzzlepiece.extension"
        case .remoteAgent: return "laptopcomputer.and.arrow.down"
        case .memory: return "brain"
        case .privacy: return "lock.shield"
        }
    }
}

struct SettingsView: View {
    @State private var section: SettingsSection = .general
    @State private var backendURL = "http://127.0.0.1:8000"
    @AppStorage(AudioConfiguration.speechRateKey) private var speechRate = AudioConfiguration.defaultSpeechRate

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsSection.allCases) { item in
                    Button { section = item } label: {
                        Label(item.title, systemImage: item.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(section == item ? Theme.accent.opacity(0.14) : .clear)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(12)
            .frame(width: 210)

            Divider().overlay(Theme.border)

            Form { content }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .general:
            Section("Backend") {
                row("Backend URL", "Local FastAPI server.", tag: "Placeholder") {
                    TextField("", text: $backendURL).textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                }
                row("Connection", nil, tag: "Needs backend") {
                    StatusBadge(text: "Not connected", kind: .neutral)
                }
                row("Preferred behavior", "How the assistant should respond.", tag: "Placeholder") {
                    Text("Balanced").foregroundStyle(Theme.textSecondary)
                }
            }
        case .appearance:
            Section("Appearance") {
                row("Theme", "The interface is dark only.", tag: "Static") {
                    Text("Dark").foregroundStyle(Theme.textSecondary)
                }
                row("Accent colour", nil, tag: "Placeholder") {
                    Text("Cyan / blue").foregroundStyle(Theme.textSecondary)
                }
            }
        case .voice:
            Section("Voice") {
                row("Voice profile", "British English, calm, and local to macOS.", tag: "Local") {
                    Text("System voice").foregroundStyle(Theme.textSecondary)
                }
                row("Speaking speed", "Applies to Arthur’s next spoken response.", tag: "Live") {
                    VStack(alignment: .trailing, spacing: 4) {
                        Slider(value: $speechRate, in: 0.28...0.62, step: 0.02)
                            .frame(width: 160)
                        Text(speedLabel)
                            .font(.caption2.monospaced())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                row("Input device", nil, tag: "Placeholder") {
                    Text("System default").foregroundStyle(Theme.textSecondary)
                }
            }
        case .aiModel:
            Section("AI model") {
                row("Model selection", "Managed by the backend.", tag: "Needs backend") {
                    Text("Unavailable").foregroundStyle(Theme.textSecondary)
                }
            }
        case .integrations:
            Section("Integrations") {
                Text("Nothing is connected.").font(.caption).foregroundStyle(Theme.textSecondary)
                ForEach(IntegrationItem.samples) { item in
                    HStack {
                        Label(item.name, systemImage: item.systemImage)
                        Spacer()
                        Text(item.access).font(.caption).foregroundStyle(Theme.textSecondary)
                        StatusBadge(text: "Placeholder", kind: .neutral)
                    }
                }
            }
        case .remoteAgent:
            Section("Remote agent") {
                row("Host", nil, tag: "Needs backend") { Text("Not set").foregroundStyle(Theme.textSecondary) }
                row("User", nil, tag: "Needs backend") { Text("Not set").foregroundStyle(Theme.textSecondary) }
                row("Status", nil, tag: "Needs backend") { StatusBadge(text: "Unknown", kind: .neutral) }
            }
        case .memory:
            Section("Memory") {
                row("Stored memories", nil, tag: "Needs backend") { Text("Unavailable").foregroundStyle(Theme.textSecondary) }
                row("Clear memory", nil, tag: "Needs backend") { Button("Clear…") {}.disabled(true) }
            }
        case .privacy:
            Section("Privacy & permissions") {
                row("Microphone", nil, tag: "Placeholder") { StatusBadge(text: "Not requested", kind: .neutral) }
                row("Confirm sensitive actions", "Sending, deleting or rescheduling will require confirmation.", tag: "Needs backend") {
                    Text("Planned").foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var speedLabel: String {
        switch speechRate {
        case ..<0.38: "SLOW"
        case 0.54...: "FAST"
        default: "NORMAL"
        }
    }

    private func row<Control: View>(_ title: String, _ detail: String?, tag: String,
                                    @ViewBuilder control: () -> Control) -> some View {
        LabeledContent {
            control()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                    StatusBadge(text: tag, kind: .neutral)
                }
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
