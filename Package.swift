// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoolBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CoolBar", targets: ["CoolBar"])
    ],
    targets: [
        .executableTarget(
            name: "CoolBar",
            path: "Sources",
            sources: [
                "main.swift",
                "App/AppDelegate.swift",
                "Core/AppIcon.swift",
                "Core/StatusBarController.swift",
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
