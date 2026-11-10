import XCTest
@testable import AccountSwitcherCore

final class InstallationTests: XCTestCase {
    func testDiscoveryDoesNotCreateMissingPaths() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let result = Installation.discover(appURL: root.appendingPathComponent("missing.app"), home: root)
        XCTAssertFalse(result.isInstalled)
        XCTAssertNil(result.databaseURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
    }

    func testDiscoversKnownDatabasePathWithoutReadingContents() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let db = root.appendingPathComponent("Library/Application Support/Antigravity/User/globalStorage/state.vscdb")
        try FileManager.default.createDirectory(at: db.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: db)
        let result = Installation.discover(appURL: root.appendingPathComponent("missing.app"), home: root)
        XCTAssertEqual(result.databaseURL, db)
        XCTAssertEqual(try Data(contentsOf: db), Data("fixture".utf8))
    }
}
