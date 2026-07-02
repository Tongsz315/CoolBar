// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoolBar",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CoolBar", targets: ["CoolBar"])],
    targets: [
        .executableTarget(
            name: "CoolBar",
            path: "Sources",
            sources: [
                "main.swift",
                "App/AppDelegate.swift",
                "Core/StatusBarController.swift",
                "Core/DetailPanelController.swift",
                "Core/DashboardViewModel.swift",
                "Core/AppIcon.swift",
                "Core/DataProvider.swift",
                "Core/MonitorProtocol.swift",
                "Monitors/CPUMonitor.swift",
                "Monitors/GPUMonitor.swift",
                "Monitors/MemoryMonitor.swift",
                "Monitors/DiskMonitor.swift",
                "Monitors/NetworkMonitor.swift",
                "Monitors/BatteryMonitor.swift",
                "Monitors/BluetoothMonitor.swift",
                "Monitors/ClockMonitor.swift",
                "BarManager/OverflowController.swift",
                "UI/StatsWindowView.swift",
                "UI/StatsPages.swift",
                "UI/PopoverView.swift",
                "UI/DetailChart.swift",
                "UI/Preferences/PreferencesView.swift",
                "UI/Preferences/GeneralTab.swift",
                "UI/Preferences/MonitorsTab.swift",
                "Utils/Extensions.swift",
                "Utils/LaunchAtLogin.swift",
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Metal"),
                .linkedFramework("IOBluetooth"),
            ]
        )
    ]
)
