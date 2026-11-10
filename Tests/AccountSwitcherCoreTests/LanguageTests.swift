import XCTest
@testable import AccountSwitcherCore

final class LanguageTests: XCTestCase {
    func testSystemLanguageAndOverrides() {
        XCTAssertEqual(AppLanguage.resolve(preference: nil, preferredLanguages: ["zh-Hans-SG"]), .chinese)
        XCTAssertEqual(AppLanguage.resolve(preference: "system", preferredLanguages: ["ja-JP", "zh-Hans"]), .english)
        XCTAssertEqual(AppLanguage.resolve(preference: "en", preferredLanguages: ["zh-Hans"]), .english)
        XCTAssertEqual(AppLanguage.resolve(preference: "zh", preferredLanguages: ["en-US"]), .chinese)
        XCTAssertEqual(AppLanguage.resolve(preference: nil, preferredLanguages: []), .english)
    }

    func testEnglishError() {
        let error = ManagerError.message("请先完成或恢复之前的操作。")
        XCTAssertEqual(AppLanguage.english.errorMessage(error), "Complete or restore the previous operation first.")
        XCTAssertEqual(AppLanguage.chinese.errorMessage(error), error.localizedDescription)
    }
}
