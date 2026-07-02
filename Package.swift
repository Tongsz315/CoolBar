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
                // App
                "App/AppDelegate.swift",
                // Core
                "Core/StatusBarController.swift",
                "Core/DetailPanelController.swift",
                "Core/DashboardViewModel.swift",
                "Core/AppIcon.swift",
                "Core/DataProvider.swift",
                "Core/MonitorProtocol.swift",
                // Monitors
                "Monitors/CPUMonitor.swift",
                "Monitors/MemoryMonitor.swift",
                "Monitors/NetworkMonitor.swift",
                "Monitors/BatteryMonitor.swift",
                // BarManager
                "BarManager/OverflowController.swift",
                // UI
                "UI/DashboardView.swift",
                "UI/PopoverView.swift",
                "UI/DetailChart.swift",
                "UI/Preferences/PreferencesView.swift",
                "UI/Preferences/GeneralTab.swift",
                "UI/Preferences/MonitorsTab.swift",
                // Utils
                "Utils/Extensions.swift",
                "Utils/LaunchAtLogin.swift",
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI"),
            ]
        )
    ]
)
