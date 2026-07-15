import Foundation

/// Persists everything except the password (that lives in the Keychain).
/// Keeping the session on disk is what makes logout survive app restarts.
public final class SessionStore {
    public static let shared = SessionStore()

    private let defaults: UserDefaults
    private enum Keys {
        static let session = "portalSession"
        static let username = "username"
        static let language = "language"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Session

    public var session: PortalSession? {
        get {
            guard let data = defaults.data(forKey: Keys.session) else { return nil }
            return try? JSONDecoder().decode(PortalSession.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.session)
            } else {
                defaults.removeObject(forKey: Keys.session)
            }
        }
    }

    // MARK: - Preferences

    public var username: String {
        get { defaults.string(forKey: Keys.username) ?? "" }
        set { defaults.set(newValue, forKey: Keys.username) }
    }

    public var language: Language {
        get {
            guard let raw = defaults.string(forKey: Keys.language),
                  let lang = Language(rawValue: raw) else { return Language.system }
            return lang
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.language) }
    }
}
