import Foundation

public enum AppLanguage: String {
    case chinese = "zh", english = "en"

    public static func resolve(preference: String?, preferredLanguages: [String]) -> AppLanguage {
        if let preference, let chosen = AppLanguage(rawValue: preference) { return chosen }
        return preferredLanguages.first?.lowercased().hasPrefix("zh") == true ? .chinese : .english
    }

    public func text(_ chinese: String, _ english: String) -> String {
        self == .chinese ? chinese : english
    }

    public func errorMessage(_ error: Error) -> String {
        let message = error.localizedDescription
        guard self == .english else { return message }
        let translations = [
            "无法识别登录账号。请在 Antigravity 中完成登录后重试。": "Could not identify the account. Finish signing in to Antigravity and try again.",
            "未找到 Antigravity 登录信息，请先登录。": "No Antigravity login was found. Sign in first.",
            "无法检查 Antigravity 进程。": "Could not check Antigravity processes.",
            "请先退出 Antigravity 和 agy 命令行程序，保存工作后重试。": "Save your work and quit Antigravity and the agy command-line tool, then try again.",
            "无法创建安全的临时凭据文件。": "Could not create a secure temporary credentials file.",
            "无法更新备用凭据文件。": "Could not update the fallback credentials file.",
            "请先完成或恢复之前的操作。": "Complete or restore the previous operation first.",
            "没有正在进行的添加账号操作。": "There is no account addition in progress.",
            "找不到保存的凭据，请重新添加账号。": "Saved credentials were not found. Add the account again.",
            "没有需要恢复的操作。": "There is no operation to restore.",
            "找不到恢复凭据。": "Recovery credentials were not found.",
            "找不到 /Applications/Antigravity.app。": "Could not find /Applications/Antigravity.app.",
            "无法启动 Antigravity。": "Could not start Antigravity.",
            "准备登录失败：": "Could not prepare sign-in: ",
            "切换未完成：": "Switch was not completed: ",
            "。请使用恢复操作。": ". Use Restore to recover the previous account.",
            "钥匙串操作失败（": "Keychain operation failed (",
            "）：": "): ",
            "未知错误": "Unknown error"
        ]
        if let exact = translations[message] { return exact }
        return translations.reduce(message) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
    }
}
