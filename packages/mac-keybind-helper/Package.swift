// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "KeybindHelper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "keybind-helper-daemon", targets: ["KeybindHelperDaemon"]),
        .executable(name: "keybind-helper-client", targets: ["KeybindHelperClient"]),
        .library(name: "KeybindHelperCore", targets: ["KeybindHelperCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0")
    ],
    targets: [
        // Shared core library with data models and utilities
        .target(
            name: "KeybindHelperCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        
        // Background daemon executable
        .executableTarget(
            name: "KeybindHelperDaemon",
            dependencies: ["KeybindHelperCore"]
        ),
        
        // Client communication helper executable
        .executableTarget(
            name: "KeybindHelperClient",
            dependencies: [
                "KeybindHelperCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        
        // Tests
        .testTarget(
            name: "KeybindHelperCoreTests",
            dependencies: ["KeybindHelperCore"]
        )
    ]
)