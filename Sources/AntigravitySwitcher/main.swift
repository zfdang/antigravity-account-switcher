import SwiftUI
import AppKit
import AccountSwitcherCore

@MainActor final class Model: ObservableObject {
    @Published var manager: AccountManager?
    @Published var message: String?
    @Published var languagePreference: String = UserDefaults.standard.string(forKey: "language") ?? "system" {
        didSet { UserDefaults.standard.set(languagePreference, forKey: "language"); window?.title = t("Antigravity 账号管理", "Antigravity Account Switcher") }
    }
    var language: AppLanguage { AppLanguage.resolve(preference: languagePreference, preferredLanguages: Locale.preferredLanguages) }
    func t(_ zh: String, _ en: String) -> String { language.text(zh, en) }
    private var window: NSWindow?
    init() { reload() }
    func reload() { do { manager = try AccountManager() } catch { message = language.errorMessage(error) } }
    func openWizard(_ mode: WizardMode) {
        let view = WizardView(model: self, mode: mode)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 330), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = t("Antigravity 账号管理", "Antigravity Account Switcher"); window.contentView = NSHostingView(rootView: view)
        window.center(); window.isReleasedWhenClosed = false
        self.window = window; NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
    }
    func closeWizard() { window?.close(); window = nil; reload() }
    func requestQuit() {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.antigravity") { app.terminate() }
    }
    func remove(_ account: Account) {
        let alert = NSAlert(); alert.messageText = t("删除 \(account.email)？", "Remove \(account.email)?"); alert.informativeText = t("只删除本工具保存的账号和凭据，不删除 Google 账号或退出当前登录。", "This removes only the saved account and credentials from this app. Your Google account and current IDE login are unchanged.")
        alert.addButton(withTitle: t("删除", "Remove")); alert.addButton(withTitle: t("取消", "Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { try manager?.delete(account); objectWillChange.send() } catch { show(language.errorMessage(error)) }
    }
    func show(_ text: String) { let alert = NSAlert(); alert.messageText = text; alert.runModal() }
}

enum WizardMode { case add, switchAccount(Account), save, restore }
struct WizardView: View {
    @ObservedObject var model: Model
    let mode: WizardMode
    @State private var step = 0
    init(model: Model, mode: WizardMode) { self.model = model; self.mode = mode; _step = State(initialValue: model.manager?.pending == true ? 1 : 0) }
    @State private var error: String?
    private var heading: String { switch mode { case .add: return model.t("添加账号", "Add Account"); case .switchAccount: return model.t("切换账号", "Switch Account"); case .save: return model.t("保存当前账号", "Save Current Account"); case .restore: return model.t("恢复原账号", "Restore Previous Account") } }
    private var detail: String {
        switch mode {
        case .add:
            return step == 0 ? model.t("第 1 步：保存工作并关闭 Antigravity。我们会保存当前登录，然后打开 Antigravity 供你登录新账号。", "Step 1: Save your work and close Antigravity. Your current login will be saved before Antigravity opens for the new account.") : model.t("第 2 步：在 Antigravity 中登录新账号。登录成功后，保存工作并关闭 Antigravity，然后点击“完成登录”。", "Step 2: Sign in to the new account in Antigravity. Then save your work, close Antigravity, and click Finish Sign-in.")
        case .switchAccount(let account): return model.t("将切换到 \(account.email)。请先保存工作并关闭 Antigravity，切换后会自动重新打开。", "Switch to \(account.email). Save your work and close Antigravity first; it will reopen after the switch.")
        case .save: return model.t("保存当前已登录的账号，以便以后切换。请先保存工作并关闭 Antigravity。", "Save the current account for later switching. Save your work and close Antigravity first.")
        case .restore: return model.t("恢复上一次操作前的登录状态。请先保存工作并关闭 Antigravity。", "Restore the login from before the previous operation. Save your work and close Antigravity first.")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(heading).font(.title2.bold())
            Text(detail).fixedSize(horizontal: false, vertical: true)
            if let error { Text(error).foregroundColor(.red).fixedSize(horizontal: false, vertical: true).textSelection(.enabled) }
            Spacer()
            HStack {
                Button(model.t("关闭 Antigravity", "Close Antigravity")) { model.requestQuit() }
                Spacer()
                Button(model.t("取消", "Cancel")) { model.closeWizard() }
                Button(primaryTitle) { perform() }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 500, height: 330)
    }
    private var primaryTitle: String {
        switch mode { case .add: return step == 0 ? model.t("开始登录", "Start Sign-in") : model.t("完成登录", "Finish Sign-in"); case .switchAccount: return model.t("切换账号", "Switch Account"); case .save: return model.t("保存账号", "Save Account"); case .restore: return model.t("恢复账号", "Restore Account") }
    }
    private func perform() {
        guard let manager = model.manager else { return }
        do {
            switch mode {
            case .add:
                if step == 0 { try manager.beginAdd(); step = 1; error = nil; model.objectWillChange.send(); return }
                try manager.finishAdd()
            case .switchAccount(let account): try manager.switchTo(account)
            case .save: try manager.saveCurrent()
            case .restore: try manager.restore()
            }
            model.closeWizard()
        } catch { self.error = model.language.errorMessage(error) }
    }
}

@main struct AntigravitySwitcherApp: App {
    @StateObject private var model = Model()
    var body: some Scene {
        MenuBarExtra {
            if let m = model.manager {
                Text("\(model.t("当前", "Current")): \(m.currentEmail ?? model.t("未知或未登录", "Unknown or signed out"))")
                Divider()
                if m.accounts.isEmpty { Text(model.t("暂无已保存账号", "No saved accounts")) }
                ForEach(m.accounts) { account in
                    Button("\(account.email)\(account.email.caseInsensitiveCompare(m.currentEmail ?? "") == .orderedSame ? " ✓" : "")") { model.openWizard(.switchAccount(account)) }.disabled(m.pending)
                }
                Divider()
                if m.pending {
                    Button(model.t("继续添加账号…", "Continue Adding Account…")) { model.openWizard(.add) }
                    Button(model.t("恢复原账号…", "Restore Previous Account…")) { model.openWizard(.restore) }
                } else {
                    Button(model.t("保存当前账号…", "Save Current Account…")) { model.openWizard(.save) }
                    Button(model.t("添加账号…", "Add Account…")) { model.openWizard(.add) }
                    Menu(model.t("删除账号", "Remove Account")) { ForEach(m.accounts) { account in Button(account.email) { model.remove(account) } } }.disabled(m.accounts.isEmpty)
                }
                Button(model.t("刷新状态", "Refresh")) { model.reload() }
            } else { Button(model.t("重新检查", "Retry")) { model.reload() } }
            Divider()
            Menu(model.t("语言", "Language")) {
                Button("\(model.t("跟随系统", "Follow System"))\(model.languagePreference == "system" ? " ✓" : "")") { model.languagePreference = "system" }
                Button("简体中文\(model.languagePreference == "zh" ? " ✓" : "")") { model.languagePreference = "zh" }
                Button("English\(model.languagePreference == "en" ? " ✓" : "")") { model.languagePreference = "en" }
            }
            Button(model.t("退出", "Quit")) { NSApplication.shared.terminate(nil) }
        } label: {
            if let image = NSImage(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("MenuBarIcon.png")) { Image(nsImage: { image.isTemplate = true; image.size = NSSize(width: 18, height: 18); return image }()) } else { Image(systemName: "person.crop.circle") }
        }
    }
}
