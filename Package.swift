// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeularMacropad",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TimeularMacropad",
            path: "TimeularMacropad",
            exclude: [
                "Info.plist",
                "TimeularMacropad.entitlements",
            ],
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
    ]
)
