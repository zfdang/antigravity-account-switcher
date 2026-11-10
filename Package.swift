// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AntigravitySwitcher",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "AntigravitySwitcher", targets: ["AntigravitySwitcher"])],
    targets: [
        .target(name: "AccountSwitcherCore"),
        .executableTarget(name: "AntigravitySwitcher", dependencies: ["AccountSwitcherCore"]),
        .testTarget(name: "AccountSwitcherCoreTests", dependencies: ["AccountSwitcherCore"])
    ]
)
