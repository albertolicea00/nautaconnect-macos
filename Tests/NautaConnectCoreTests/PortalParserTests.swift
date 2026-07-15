import XCTest
@testable import NautaConnectCore

final class PortalParserTests: XCTestCase {
    private func fixture(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: name,
            withExtension: "html",
            subdirectory: "Fixtures"
        ))
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testParsesLoginPageTokens() throws {
        let html = try fixture("login_page")
        XCTAssertEqual(
            PortalParser.hiddenInputValue(named: "CSRFHW", in: html),
            "39dd52d464cb68d8e512d64a56f274d9"
        )
        XCTAssertEqual(
            PortalParser.hiddenInputValue(named: "wlanuserip", in: html),
            "10.181.141.250"
        )
        XCTAssertEqual(
            PortalParser.hiddenInputValue(named: "loggerId", in: html),
            "20260715163945368"
        )
    }

    func testMissingInputReturnsNil() throws {
        let html = try fixture("login_page")
        XCTAssertNil(PortalParser.hiddenInputValue(named: "doesNotExist", in: html))
    }

    func testParsesAttributeUUIDFromOnlinePage() throws {
        let html = try fixture("online_page")
        XCTAssertEqual(
            PortalParser.attributeUUID(in: html),
            "B2F6AAB9A9868BABC0BDA09B7F0E26FF"
        )
    }

    func testLoginPageHasNoAttributeUUID() throws {
        let html = try fixture("login_page")
        XCTAssertNil(PortalParser.attributeUUID(in: html))
    }

    func testParsesAlertMessageFromFailedLogin() throws {
        let html = try fixture("login_failed")
        XCTAssertEqual(
            PortalParser.alertMessage(in: html),
            "Entre el nombre de usuario y contraseña correctos."
        )
    }

    func testParsesTimeString() {
        XCTAssertEqual(PortalParser.timeString(in: "04:29:37"), "04:29:37")
        XCTAssertEqual(PortalParser.timeString(in: "<div>123:00:05</div>"), "123:00:05")
        XCTAssertNil(PortalParser.timeString(in: "errorop"))
    }

    func testFormEncodingEscapesReservedCharacters() {
        let encoded = PortalClient.encodeForm([
            ("username", "user@nauta.com.cu"),
            ("loggerId", "20260715163945368+user@nauta.com.cu"),
        ])
        XCTAssertEqual(
            encoded,
            "username=user%40nauta.com.cu&loggerId=20260715163945368%2Buser%40nauta.com.cu"
        )
    }
}
