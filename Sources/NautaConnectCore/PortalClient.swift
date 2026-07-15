import Foundation

/// A live (or restorable) portal session. Everything needed to log out later.
public struct PortalSession: Codable, Equatable {
    public var username: String
    public var csrfhw: String
    public var wlanUserIP: String
    public var attributeUUID: String
    public var loginDate: Date

    public init(username: String, csrfhw: String, wlanUserIP: String, attributeUUID: String, loginDate: Date) {
        self.username = username
        self.csrfhw = csrfhw
        self.wlanUserIP = wlanUserIP
        self.attributeUUID = attributeUUID
        self.loginDate = loginDate
    }

    public var elapsed: TimeInterval { Date().timeIntervalSince(loginDate) }
}

public enum PortalError: LocalizedError, Equatable {
    case portalUnreachable
    case missingToken(String)
    case loginRejected(String)
    case logoutFailed
    case badResponse

    public var errorDescription: String? {
        switch self {
        case .portalUnreachable: return "The ETECSA portal is not reachable. Are you on a Nauta network?"
        case .missingToken(let name): return "Could not find '\(name)' in the portal page."
        case .loginRejected(let message): return message
        case .logoutFailed: return "The portal did not confirm the logout."
        case .badResponse: return "Unexpected response from the portal."
        }
    }
}

/// Tokens scraped from the captive portal login page.
public struct LoginPage {
    public let csrfhw: String
    public let wlanUserIP: String
    public let loggerID: String
}

/// HTTP client for the ETECSA captive portal at secure.etecsa.net:8443.
///
/// The flow mirrors what the official web form does:
///   GET / → tokens, POST //LoginServlet → ATTRIBUTE_UUID,
///   GET /LogoutServlet → "SUCCESS", POST /EtecsaQueryServlet → "HH:MM:SS".
public final class PortalClient {
    public static let baseURL = URL(string: "https://secure.etecsa.net:8443")!

    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "NautaConnect-macOS/1.0",
            "Accept": "text/html,application/xhtml+xml,*/*",
        ]
        self.session = URLSession(configuration: config)
    }

    /// Quick reachability probe. The portal only answers from inside an ETECSA network.
    public func isPortalReachable() async -> Bool {
        var request = URLRequest(url: Self.baseURL)
        request.timeoutInterval = 5
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse) != nil
        } catch {
            return false
        }
    }

    /// GET / and scrape CSRFHW, wlanuserip and loggerId from the login form.
    public func fetchLoginPage() async throws -> LoginPage {
        let html: String
        do {
            html = try await get(Self.baseURL)
        } catch {
            throw PortalError.portalUnreachable
        }
        guard let csrfhw = PortalParser.hiddenInputValue(named: "CSRFHW", in: html) else {
            throw PortalError.missingToken("CSRFHW")
        }
        guard let ip = PortalParser.hiddenInputValue(named: "wlanuserip", in: html) else {
            throw PortalError.missingToken("wlanuserip")
        }
        let loggerID = PortalParser.hiddenInputValue(named: "loggerId", in: html) ?? ""
        return LoginPage(csrfhw: csrfhw, wlanUserIP: ip, loggerID: loggerID)
    }

    /// Full login: fetch tokens, POST credentials, extract ATTRIBUTE_UUID.
    public func login(username: String, password: String) async throws -> PortalSession {
        let page = try await fetchLoginPage()
        // The double slash in //LoginServlet matches the portal form action exactly.
        let url = URL(string: "\(Self.baseURL.absoluteString)//LoginServlet")!
        let form: [(String, String)] = [
            ("wlanuserip", page.wlanUserIP),
            ("wlanacname", ""),
            ("wlanmac", ""),
            ("firsturl", "notFound.jsp"),
            ("ssid", ""),
            ("usertype", ""),
            ("gotopage", "/nauta_etecsa/LoginURL/pc_login.jsp"),
            ("successpage", "/nauta_etecsa/OnlineURL/pc_index.jsp"),
            ("loggerId", "\(page.loggerID)+\(username)"),
            ("lang", "es_ES"),
            ("username", username),
            ("password", password),
            ("CSRFHW", page.csrfhw),
        ]
        let body = try await post(url, form: form)
        if let uuid = PortalParser.attributeUUID(in: body) {
            return PortalSession(
                username: username,
                csrfhw: page.csrfhw,
                wlanUserIP: page.wlanUserIP,
                attributeUUID: uuid,
                loginDate: Date()
            )
        }
        if let message = PortalParser.alertMessage(in: body) {
            throw PortalError.loginRejected(message)
        }
        throw PortalError.badResponse
    }

    /// Ends the session. The portal answers logoutcallback('SUCCESS') on success.
    public func logout(_ portalSession: PortalSession) async throws {
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent("LogoutServlet"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "ATTRIBUTE_UUID", value: portalSession.attributeUUID),
            URLQueryItem(name: "CSRFHW", value: portalSession.csrfhw),
            URLQueryItem(name: "wlanuserip", value: portalSession.wlanUserIP),
            URLQueryItem(name: "username", value: portalSession.username),
            URLQueryItem(name: "remove", value: "1"),
        ]
        let body = try await get(components.url!)
        guard body.uppercased().contains("SUCCESS") else {
            throw PortalError.logoutFailed
        }
    }

    /// Remaining account time as "HH:MM:SS".
    public func remainingTime(for portalSession: PortalSession) async throws -> String {
        let url = Self.baseURL.appendingPathComponent("EtecsaQueryServlet")
        let form: [(String, String)] = [
            ("op", "getLeftTime"),
            ("ATTRIBUTE_UUID", portalSession.attributeUUID),
            ("CSRFHW", portalSession.csrfhw),
            ("wlanuserip", portalSession.wlanUserIP),
            ("username", portalSession.username),
        ]
        let body = try await post(url, form: form)
        guard let time = PortalParser.timeString(in: body) else {
            throw PortalError.badResponse
        }
        return time
    }

    // MARK: - HTTP plumbing

    private func get(_ url: URL) async throws -> String {
        let (data, _) = try await session.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }

    private func post(_ url: URL, form: [(String, String)]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.encodeForm(form).data(using: .utf8)
        let (data, _) = try await session.data(for: request)
        return String(decoding: data, as: UTF8.self)
    }

    /// application/x-www-form-urlencoded encoding ('+', '@', '&', '=' must be escaped).
    static func encodeForm(_ form: [(String, String)]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._*")
        return form
            .map { key, value in
                let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(k)=\(v)"
            }
            .joined(separator: "&")
    }
}
