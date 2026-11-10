import XCTest
@testable import AccountSwitcherCore

private final class MemoryStore: CredentialStore {
    var items: [String: Data] = [:]
    func get(service: String, account: String) throws -> Data? { items[service + ":" + account] }
    func set(service: String, account: String, data: Data) throws { items[service + ":" + account] = data }
    func delete(service: String, account: String) throws { items.removeValue(forKey: service + ":" + account) }
}

final class AccountManagerTests: XCTestCase {
    func testAddSwitchDeleteAndRecovery() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MemoryStore()
        let first = Data(#"{"token":{"refresh_token":"a"},"id_token_email":"a@example.invalid"}"#.utf8)
        let second = Data(#"{"token":{"refresh_token":"b"},"id_token_email":"b@example.invalid"}"#.utf8)
        try store.set(service: "gemini", account: "antigravity", data: Credential(raw: first).keychainValue)
        let manager = try AccountManager(home: root, keychain: store, processCheck: {}, launchOverride: {})
        try manager.saveCurrent()
        XCTAssertEqual(manager.accounts.count, 1)
        try manager.beginAdd()
        XCTAssertTrue(manager.pending)
        XCTAssertNil(try store.get(service: "gemini", account: "antigravity"))
        try store.set(service: "gemini", account: "antigravity", data: Credential(raw: second).keychainValue)
        try manager.finishAdd()
        XCTAssertEqual(manager.accounts.count, 2)
        let a = try XCTUnwrap(manager.accounts.first { $0.email.hasPrefix("a@") })
        try manager.switchTo(a)
        XCTAssertEqual(manager.currentEmail, "a@example.invalid")
        let fallback = root.appendingPathComponent(".gemini/jetski-standalone-oauth-token")
        XCTAssertEqual(try Data(contentsOf: fallback), first)
        XCTAssertEqual((try FileManager.default.attributesOfItem(atPath: fallback.path)[.posixPermissions] as? Int), 0o600)
        try manager.beginAdd()
        try manager.restore()
        XCTAssertEqual(manager.currentEmail, "a@example.invalid")
        try manager.delete(a)
        XCTAssertEqual(manager.accounts.count, 1)
        XCTAssertEqual(manager.currentEmail, "a@example.invalid")
    }
}

final class KeychainTests: XCTestCase {
    func testRealKeychainRoundTrip() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["SKIP_LIVE_KEYCHAIN_TESTS"] == "1", "CI does not have an interactive login keychain")
        let store = Keychain()
        let service = "com.antigravity-account-switcher.test.\(UUID().uuidString)"
        defer { try? store.delete(service: service, account: "test") }
        try store.set(service: service, account: "test", data: Data("test-only".utf8))
        XCTAssertEqual(try store.get(service: service, account: "test"), Data("test-only".utf8))
        try store.delete(service: service, account: "test")
        XCTAssertNil(try store.get(service: service, account: "test"))
    }
}
