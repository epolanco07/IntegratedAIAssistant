import Foundation

enum BackendConnectionStatus: Equatable, Sendable {
    case disconnected, checking, connected, failed(String)

    var label: String {
        switch self { case .disconnected: "Not connected"; case .checking: "Checking…"; case .connected: "Connected"; case .failed: "Unavailable" }
    }
}
