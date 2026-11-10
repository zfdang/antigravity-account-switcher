import XCTest
@testable import AccountSwitcherCore

final class CredentialTests: XCTestCase {
    func testFallbackAndKeychainRoundTripPreserveUnknownFields() throws {
        let fixture = Data(#"{"token":{"refresh_token":"example"},"id_token_email":"test@example.invalid","future":42}"#.utf8)
        let credential = try Credential(raw: fixture)
        XCTAssertEqual(credential.email, "test@example.invalid")
        XCTAssertEqual(try Credential(raw: credential.keychainValue).json, fixture)
    }

    func testRejectsMissingRefreshToken() {
        XCTAssertThrowsError(try Credential(raw: Data(#"{"token":{}}"#.utf8)))
    }
}
