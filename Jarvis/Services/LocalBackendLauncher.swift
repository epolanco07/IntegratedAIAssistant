import Foundation
import Combine

/// Starts Arthur's bundled development backend when the macOS app launches.
///
/// The launcher invokes the Python interpreter inside `backend/.venv` directly.
/// It never requires `source .venv/bin/activate`: activation only changes shell
/// environment variables, while this process uses the virtual environment's
/// executable itself.
@MainActor
final class LocalBackendLauncher: ObservableObject {
    // This published state gives SwiftUI an observation publisher for the
    // StateObject that owns the launcher.
    @Published private(set) var isRunning = false
    private var process: Process?
    private let backendURL: URL?
    private let service: any BackendService

    init() {
        let backendURL = Self.findBackendDirectory()
        self.backendURL = backendURL
        self.service = HTTPBackendService(
            baseURL: URL(string: "http://127.0.0.1:8000")!
        )
    }

    func startIfNeeded() async -> BackendConnectionStatus {
        if await isHealthy() { return .connected }

        guard let backendURL else {
            return .failed("Arthur backend folder was not found.")
        }

        do {
            try launchBackend(in: backendURL)
        } catch {
            return .failed(error.localizedDescription)
        }

        for _ in 0..<24 {
            try? await Task.sleep(for: .milliseconds(250))
            if await isHealthy() { return .connected }
        }
        return .failed("Arthur backend did not start. Check backend/.env.")
    }

    private func isHealthy() async -> Bool {
        do {
            try await service.healthCheck()
            return true
        } catch {
            return false
        }
    }

    private func launchBackend(in backendURL: URL) throws {
        guard process?.isRunning != true else { return }

        let python = backendURL.appending(path: ".venv/bin/python")
        guard FileManager.default.isExecutableFile(atPath: python.path) else {
            throw LauncherError.virtualEnvironmentMissing
        }

        let process = Process()
        process.executableURL = python
        process.arguments = [
            "-m", "uvicorn", "app.main:app",
            "--host", "127.0.0.1", "--port", "8000",
        ]
        process.currentDirectoryURL = backendURL
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        self.process = process
        isRunning = true
    }

    private static func findBackendDirectory() -> URL? {
        var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        for _ in 0..<6 {
            let candidate = directory.appending(path: "backend")
            if FileManager.default.fileExists(atPath: candidate.appending(path: "app/main.py").path) {
                return candidate
            }
            directory.deleteLastPathComponent()
        }
        return nil
    }

    private enum LauncherError: LocalizedError {
        case virtualEnvironmentMissing

        var errorDescription: String? {
            "Arthur's Python environment is missing. Run backend setup once."
        }
    }
}
