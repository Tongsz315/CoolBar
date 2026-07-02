import Foundation
import IOKit

/// 电池状态监控 — 通过 IOKit 注册表直接读取
final class BatteryMonitor: MonitorProtocol {
    let id = "battery"
    let title = "BAT"
    let refreshInterval: TimeInterval = 5.0
    var isEnabled = true

    private(set) var displayText = "BAT --"

    func start() {
        displayText = "BAT --"
    }

    func stop() {}

    func refresh() { _ = update() }

    enum BatteryState {
        case charging, discharging, full, unknown
    }

    struct BatteryInfo {
        let percentage: Int
        let state: BatteryState
        let timeRemaining: String
        let cycleCount: Int
        let health: String
    }

    /// 通过 IOKit 注册表获取电池信息（避免依赖 IOPowerSources C API）
    func update() -> BatteryInfo {
        guard let battery = getBatteryService() else {
            displayText = "BAT --"
            return BatteryInfo(percentage: 0, state: .unknown, timeRemaining: "--", cycleCount: 0, health: "--")
        }
        defer { IOObjectRelease(battery) }

        let currentCapacity = readIntProperty(battery, key: "CurrentCapacity")
        let maxCapacity = readIntProperty(battery, key: "MaxCapacity")
        let designCapacity = readIntProperty(battery, key: "DesignCapacity")
        let cycleCount = readIntProperty(battery, key: "CycleCount")
        let isCharging = readBoolProperty(battery, key: "IsCharging")
        let isFullyCharged = readBoolProperty(battery, key: "FullyCharged")
        let timeToEmpty = readIntProperty(battery, key: "TimeToEmpty")
        let timeToFullCharge = readIntProperty(battery, key: "AvgTimeToFull")
        let externalConnected = readBoolProperty(battery, key: "ExternalConnected")
        let rawMaxCapacity = readIntProperty(battery, key: "AppleRawMaxCapacity")

        // 电量百分比
        let percentage: Int
        if let current = currentCapacity, let max = maxCapacity, max > 0 {
            percentage = Int(round(Double(current) / Double(max) * 100.0))
        } else {
            percentage = 0
        }

        // 充电状态
        let state: BatteryState
        if isFullyCharged == true || (externalConnected == true && percentage >= 99) {
            state = .full
        } else if isCharging == true || externalConnected == true {
            state = .charging
        } else if externalConnected == false && isCharging == false {
            state = .discharging
        } else {
            state = .unknown
        }

        // 剩余时间
        let timeRemaining: String
        if state == .discharging, let minutes = timeToEmpty, minutes > 0 {
            let h = minutes / 60, m = minutes % 60
            timeRemaining = "\(h)h \(m)m"
        } else if state == .charging, let minutes = timeToFullCharge, minutes > 0 {
            let h = minutes / 60, m = minutes % 60
            timeRemaining = "充满约 \(h)h \(m)m"
        } else if state == .full {
            timeRemaining = "已充满"
        } else {
            timeRemaining = "--"
        }

        // 电池健康度
        let health: String
        if let raw = rawMaxCapacity, let design = designCapacity, design > 0 {
            health = String(format: "%.0f%%", Double(raw) / Double(design) * 100)
        } else {
            health = "--"
        }

        // 显示文本
        let icon = stateIcon(state, percentage: percentage)
        displayText = "\(icon) \(percentage)%"

        return BatteryInfo(
            percentage: percentage,
            state: state,
            timeRemaining: timeRemaining,
            cycleCount: cycleCount ?? 0,
            health: health
        )
    }

    func detailedInfo() -> [(String, String)] {
        let info = update()
        let stateText: String = {
            switch info.state {
            case .charging:    return "充电中 ⚡"
            case .discharging: return "放电中 🔋"
            case .full:        return "已充满 🔌"
            case .unknown:     return "未知"
            }
        }()
        return [
            ("电量", "\(info.percentage)%"),
            ("状态", stateText),
            ("剩余", info.timeRemaining),
            ("健康度", info.health),
            ("循环次数", "\(info.cycleCount)")
        ]
    }

    // MARK: - Helpers

    private func getBatteryService() -> io_service_t? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPMPowerSource")
        )
        return service != 0 ? service : nil
    }

    private func readIntProperty(_ service: io_service_t, key: String) -> Int? {
        guard let cfValue = IORegistryEntryCreateCFProperty(
            service, key as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() else { return nil }
        return cfValue as? Int
    }

    private func readBoolProperty(_ service: io_service_t, key: String) -> Bool? {
        guard let cfValue = IORegistryEntryCreateCFProperty(
            service, key as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() else { return nil }
        return cfValue as? Bool
    }

    private func stateIcon(_ state: BatteryState, percentage: Int) -> String {
        switch state {
        case .charging:    return "⚡"
        case .full:        return "🔌"
        case .discharging: return percentage > 20 ? "🔋" : "🪫"
        case .unknown:     return "❓"
        }
    }
}
