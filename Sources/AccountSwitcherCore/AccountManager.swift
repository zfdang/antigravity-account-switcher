import Foundation
import Security
import AppKit

public struct Account: Codable, Identifiable, Equatable {
    public let id: String
    public var email: String
}

public enum ManagerError: LocalizedError {
    case message(String)
    public var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

/// Stores saved credentials in the login keychain. IDE writes are only performed after its processes exit.
public final class AccountManager {
    private let fm = FileManager.default
    private let service = "com.antigravity-account-switcher.saved"
    private let root: URL
    private let fallback: URL
    private let appURL: URL
    private let keychain: CredentialStore
    private let processCheck: (() throws -> Void)?
    private let launchOverride: (() throws -> Void)?
    private var metadataURL: URL { root.appendingPathComponent("accounts.json") }
    private var pendingURL: URL { root.appendingPathComponent("pending.json") }
    private let recoveryID = "__recovery__"
    public private(set) var accounts: [Account] = []
    public private(set) var pending: Bool = false
    public private(set) var currentEmail: String?

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser,
                appURL: URL = URL(fileURLWithPath: "/Applications/Antigravity.app"),
                keychain: CredentialStore = Keychain(), processCheck: (() throws -> Void)? = nil,
                launchOverride: (() throws -> Void)? = nil) throws {
        root = home.appendingPathComponent("Library/Application Support/Antigravity Account Switcher", isDirectory: true)
        fallback = home.appendingPathComponent(".gemini/jetski-standalone-oauth-token")
        self.appURL = appURL
        self.keychain = keychain
        self.processCheck = processCheck
        self.launchOverride = launchOverride
        try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if fm.fileExists(atPath: metadataURL.path) { accounts = try JSONDecoder().decode([Account].self, from: Data(contentsOf: metadataURL)) }
        pending = fm.fileExists(atPath: pendingURL.path)
        refreshCurrent()
    }
    private func persist() throws {
        let data = try JSONEncoder().encode(accounts)
        try data.write(to: metadataURL, options: .atomic)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }
    private func save(_ credential: Credential) throws -> Account {
        guard let email = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            throw ManagerError.message("无法识别登录账号。请在 Antigravity 中完成登录后重试。")
        }
        let account = accounts.first { $0.email.caseInsensitiveCompare(email) == .orderedSame } ?? Account(id: UUID().uuidString, email: email)
        try keychain.set(service: service, account: account.id, data: credential.json)
        if !accounts.contains(where: { $0.id == account.id }) { accounts.append(account) }
        try persist()
        return account
    }
    private func readLive() throws -> Credential {
        if let raw = try keychain.get(service: "gemini", account: "antigravity") { return try Credential(raw: raw) }
        guard fm.fileExists(atPath: fallback.path) else { throw ManagerError.message("未找到 Antigravity 登录信息，请先登录。") }
        return try Credential(raw: Data(contentsOf: fallback))
    }
    public func refreshCurrent() { currentEmail = (try? Data(contentsOf: fallback)).flatMap { try? Credential(raw: $0).email } }
    private func checkStopped() throws {
        if let processCheck { try processCheck(); return }
        let task = Process(); task.executableURL = URL(fileURLWithPath: "/bin/ps"); task.arguments = ["-axo", "comm="]
        let pipe = Pipe(); task.standardOutput = pipe; task.standardError = FileHandle.nullDevice
        try task.run(); let output = pipe.fileHandleForReading.readDataToEndOfFile(); task.waitUntilExit()
        guard task.terminationStatus == 0, let lines = String(data: output, encoding: .utf8) else { throw ManagerError.message("无法检查 Antigravity 进程。") }
        let running = lines.split(separator: "\n").contains { line in
            let path = line.trimmingCharacters(in: .whitespaces)
            return path.hasPrefix(appURL.path + "/Contents/") || URL(fileURLWithPath: path).lastPathComponent == "agy"
        }
        if running { throw ManagerError.message("请先退出 Antigravity 和 agy 命令行程序，保存工作后重试。") }
    }
    private func recovery() throws {
        let live = try readLive()
        _ = try save(live)
        try keychain.set(service: service, account: recoveryID, data: live.json)
        try Data("pending".utf8).write(to: pendingURL, options: .atomic)
        pending = true
    }
    private func writeLive(_ credential: Credential) throws {
        // Secure a backup before touching either copy. Never put a token in process arguments.
        try keychain.set(service: "gemini", account: "antigravity", data: credential.keychainValue)
        try fm.createDirectory(at: fallback.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temp = fallback.deletingLastPathComponent().appendingPathComponent(".switcher-\(UUID().uuidString)")
        guard fm.createFile(atPath: temp.path, contents: nil, attributes: [.posixPermissions: 0o600]) else { throw ManagerError.message("无法创建安全的临时凭据文件。") }
        defer { try? fm.removeItem(at: temp) }
        try credential.json.write(to: temp)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temp.path)
        if rename(temp.path, fallback.path) != 0 { throw ManagerError.message("无法更新备用凭据文件。") }
    }
    private func finishPending() throws {
        try fm.removeItem(at: pendingURL); pending = false
        try? keychain.delete(service: service, account: recoveryID)
    }
    public func saveCurrent() throws { try checkStopped(); let live = try readLive(); _ = try save(live); currentEmail = live.email }
    public func beginAdd() throws {
        guard !pending else { throw ManagerError.message("请先完成或恢复之前的操作。") }
        try checkStopped(); try recovery()
        do {
            try keychain.delete(service: "gemini", account: "antigravity")
            if fm.fileExists(atPath: fallback.path) { try fm.removeItem(at: fallback) }
            currentEmail = nil
            try launch()
        } catch { throw ManagerError.message("准备登录失败：\(error.localizedDescription)。请使用恢复操作。") }
    }
    public func finishAdd() throws {
        guard pending else { throw ManagerError.message("没有正在进行的添加账号操作。") }
        try checkStopped(); let credential = try readLive(); _ = try save(credential)
        currentEmail = credential.email; try launch(); try finishPending()
    }
    public func switchTo(_ account: Account) throws {
        guard !pending else { throw ManagerError.message("请先完成或恢复之前的操作。") }
        try checkStopped()
        guard let raw = try keychain.get(service: service, account: account.id) else { throw ManagerError.message("找不到保存的凭据，请重新添加账号。") }
        let target = try Credential(raw: raw)
        try recovery()
        do { try writeLive(target); currentEmail = target.email; try launch(); try finishPending() }
        catch { throw ManagerError.message("切换未完成：\(error.localizedDescription)。请使用恢复操作。") }
    }
    public func restore() throws {
        guard pending else { throw ManagerError.message("没有需要恢复的操作。") }
        try checkStopped()
        guard let raw = try keychain.get(service: service, account: recoveryID) else { throw ManagerError.message("找不到恢复凭据。") }
        let credential = try Credential(raw: raw); try writeLive(credential); currentEmail = credential.email; try launch(); try finishPending()
    }
    public func delete(_ account: Account) throws {
        guard !pending else { throw ManagerError.message("请先完成或恢复之前的操作。") }
        try keychain.delete(service: service, account: account.id)
        accounts.removeAll { $0.id == account.id }; try persist()
    }
    public func launch() throws {
        if let launchOverride { try launchOverride(); return }
        guard fm.fileExists(atPath: appURL.path) else { throw ManagerError.message("找不到 /Applications/Antigravity.app。") }
        guard NSWorkspace.shared.open(appURL) else { throw ManagerError.message("无法启动 Antigravity。") }
    }
}

public protocol CredentialStore {
    func get(service: String, account: String) throws -> Data?
    func set(service: String, account: String, data: Data) throws
    func delete(service: String, account: String) throws
}

public final class Keychain: CredentialStore {
    public init() {}
    private func query(service: String, account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }
    public func get(service: String, account: String) throws -> Data? {
        var q = query(service: service, account: account); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?; let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw error(status) }; return data
    }
    public func set(service: String, account: String, data: Data) throws {
        let q = query(service: service, account: account)
        let status = SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = q; item[kSecValueData as String] = data
            let added = SecItemAdd(item as CFDictionary, nil); guard added == errSecSuccess else { throw error(added) }
        } else if status != errSecSuccess { throw error(status) }
    }
    public func delete(service: String, account: String) throws {
        let status = SecItemDelete(query(service: service, account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw error(status) }
    }
    private func error(_ status: OSStatus) -> Error {
        ManagerError.message("钥匙串操作失败（\(status)）：\(SecCopyErrorMessageString(status, nil) as String? ?? "未知错误")")
    }
}
