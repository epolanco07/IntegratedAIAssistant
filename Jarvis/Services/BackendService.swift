import Foundation

protocol BackendService: Sendable {
    func healthCheck() async throws
}

struct HTTPBackendService: BackendService {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func healthCheck() async throws {
        let endpoint = baseURL.appending(path: "health")
        var request = URLRequest(url: endpoint)
        // Startup status must never hold up the voice listener. A short probe
        // also detects an orphaned or hung local backend promptly.
        request.timeoutInterval = 2
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
