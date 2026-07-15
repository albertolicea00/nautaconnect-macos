import Foundation
import Security

/// Minimal generic-password Keychain wrapper. The Nauta password never
/// touches UserDefaults or disk in plain text.
public enum KeychainHelper {
    private static let service = "com.nautaconnect.macos"

    @discardableResult
    public static func savePassword(_ password: String, account: String) -> Bool {
        let data = Data(password.utf8)
        var query = baseQuery(account: account)
        // Replace any existing item for this account.
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    public static func loadPassword(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    @discardableResult
    public static func deletePassword(account: String) -> Bool {
        SecItemDelete(baseQuery(account: account) as CFDictionary) == errSecSuccess
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
