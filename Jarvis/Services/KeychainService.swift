import Foundation
import Security

protocol KeychainService: Sendable {
    func save(_ value: Data, account: String) throws
    func read(account: String) throws -> Data?
    func delete(account: String) throws
}

struct SystemKeychainService: KeychainService {
    private let service = "com.arthur.personal-assistant"

    func save(_ value: Data, account: String) throws {
        try delete(account: account)
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account, kSecValueData: value]
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw KeychainError.writeFailed }
    }
    func read(account: String) throws -> Data? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.readFailed }
        return result as? Data
    }
    func delete(account: String) throws {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.deleteFailed }
    }
}

enum KeychainError: Error { case writeFailed, readFailed, deleteFailed }
