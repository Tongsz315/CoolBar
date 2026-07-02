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
                "Core/FloatingBarController.swift",
                "Core/DetailPanelController.swift",
                "Core/DashboardViewModel.swift",
                "Core/MonitorProtocol.swift",
                "Core/MonitorScheduler.swift",
                "Monitors/CPUMonitor.swift",
                "Monitors/GPUMonitor.swift",
                "Monitors/MemoryMonitor.swift",
                "Monitors/DiskMonitor.swift",
                "Monitors/NetworkMonitor.swift",
                "Monitors/BatteryMonitor.swift",
                "Monitors/BluetoothMonitor.swift",
                "Monitors/ClockMonitor.swift",
                "UI/StatsWindowView.swift",
                "UI/StatsPages.swift",
                "Utils/Formatters.swift",
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
