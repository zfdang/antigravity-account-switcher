import Foundation

public struct Installation: Equatable {
    public let version: String?
    public let databaseURL: URL?
    public var isInstalled: Bool { version != nil }

    public init(version: String?, databaseURL: URL?) {
        self.version = version
        self.databaseURL = databaseURL
    }

    // Discovery is intentionally read-only; finding a database does not establish compatibility.
    public static func discover(appURL: URL = URL(fileURLWithPath: "/Applications/Antigravity.app"),
                                home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Installation {
        let bundle = Bundle(url: appURL)
        let version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let base = home.appendingPathComponent("Library/Application Support/Antigravity")
        let candidates = ["User/globalStorage/state.vscdb", "state.vscdb"]
        let db = candidates.map { base.appendingPathComponent($0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
        return Installation(version: version, databaseURL: db)
    }
}
