import Foundation

protocol IntegrationService: Sendable {
    func integrations() async throws -> [IntegrationItem]
}

struct MockIntegrationService: IntegrationService {
    func integrations() async throws -> [IntegrationItem] { IntegrationItem.samples }
}
