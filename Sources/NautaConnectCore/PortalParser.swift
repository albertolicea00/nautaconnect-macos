import Foundation

/// Pure parsing helpers for ETECSA captive portal HTML responses.
/// Kept free of networking so they can be unit-tested against fixtures.
public enum PortalParser {
    /// Value of a hidden form input, matched by its `name` attribute.
    public static func hiddenInputValue(named name: String, in html: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        return firstMatch("name=[\"']\(escaped)[\"'][^>]*?value=[\"']([^\"']*)[\"']", in: html)
    }

    /// Session handle required by LogoutServlet, present after a successful login.
    public static func attributeUUID(in html: String) -> String? {
        firstMatch("ATTRIBUTE_UUID=([A-Fa-f0-9]+)", in: html)
    }

    /// Error message the portal reports through a JavaScript alert().
    public static func alertMessage(in html: String) -> String? {
        firstMatch("alert\\s*\\(\\s*[\"']([^\"']+)[\"']", in: html)
    }

    /// Remaining time (`HH:MM:SS`, hours may exceed two digits) from EtecsaQueryServlet.
    public static func timeString(in body: String) -> String? {
        firstMatch("(\\d{1,3}:\\d{2}:\\d{2})", in: body)
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let group = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[group])
    }
}
