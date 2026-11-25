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
        let (_, response) = try await session.data(from: endpoint)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
