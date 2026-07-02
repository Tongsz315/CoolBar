import SwiftUI

/// Dashboard 数据源 — 定期从监控模块拉取数据刷新 UI
final class DashboardViewModel: ObservableObject {
    @Published var timeString: String = ""
    @Published var cpuPercent: String = "--"
    @Published var cpuSystem: String = "--"
    @Published var cpuUser: String = "--"
    @Published var cpuIdle: String = "--"
    @Published var cpuCores: String = "--"
    @Published var cpuHistory: [Double] = []
    @Published var memPercent: String = "--"
    @Published var memUsed: String = "--"
    @Published var memTotal: String = "--"
    @Published var memPressure: String = "--"
    @Published var memHistory: [Double] = []
    @Published var netDownload: String = "--"
    @Published var netUpload: String = "--"
    @Published var netHistory: [Double] = []
    @Published var batteryPercent: String = "--"
    @Published var batteryState: String = "--"
    @Published var batteryTime: String = "--"
    @Published var batteryHealth: String = "--"
    @Published var batteryCycles: String = "--"
    @Published var batteryFraction: CGFloat = 0
    @Published var batteryIcon: String = "battery.0"
    @Published var batteryColor: Color = .gray

    private let cpu: CPUMonitor
    private let mem: MemoryMonitor
    private let net: NetworkMonitor
    private let bat: BatteryMonitor
    private var timer: Timer?
    private let fmt = DateFormatter()

    init(cpu: CPUMonitor, mem: MemoryMonitor, net: NetworkMonitor, bat: BatteryMonitor) {
        self.cpu = cpu
        self.mem = mem
        self.net = net
        self.bat = bat
        fmt.dateFormat = "HH:mm"
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit { timer?.invalidate() }

    func refresh() {
        timeString = fmt.string(from: Date())
        refreshCPU()
        refreshMemory()
        refreshNetwork()
        refreshBattery()
    }

    private func refreshCPU() {
        let usage = cpu.update()
        cpuPercent = String(format: "%.0f%%", usage)
        cpuHistory = cpu.getHistory()
        cpuCores = "\(ProcessInfo.processInfo.activeProcessorCount)核"
        cpuSystem = "--"
        cpuUser = "--"
        cpuIdle = String(format: "%.0f%%", 100 - usage)
    }

    private func refreshMemory() {
        let (used, total, pressure) = mem.update()
        memPercent = String(format: "%.0f%%", Double(used) / Double(total) * 100)
        memUsed = formatBytes(used)
        memTotal = formatBytes(total)
        memPressure = ["", "低", "中", "高", "严重"][max(1, min(4, pressure))]
        memHistory = mem.history
    }

    private func refreshNetwork() {
        let (down, up) = net.update()
        netDownload = formatSpeed(Int64(down))
        netUpload = formatSpeed(Int64(up))
        netHistory = net.history.suffix(20).map { $0.down }
    }

    private func refreshBattery() {
        let info = bat.update()
        batteryPercent = "\(info.percentage)%"
        batteryFraction = CGFloat(info.percentage) / 100.0
        batteryTime = info.timeRemaining
        batteryHealth = info.health
        batteryCycles = "\(info.cycleCount)"

        switch info.state {
        case .charging:
            batteryState = "充电中"
            batteryIcon = "battery.100.bolt"
            batteryColor = .green
        case .discharging:
            batteryState = "放电中"
            batteryIcon = batterySFName(info.percentage)
            batteryColor = info.percentage > 20 ? .blue : .red
        case .full:
            batteryState = "已充满"
            batteryIcon = "battery.100"
            batteryColor = .green
        case .unknown:
            batteryState = "未知"
            batteryIcon = "battery.0"
            batteryColor = .gray
        }
    }

    private func batterySFName(_ pct: Int) -> String {
        switch pct {
        case 0..<25:  return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default:      return "battery.100"
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    private func formatSpeed(_ bps: Int64) -> String {
        let absBps = abs(bps)
        if absBps < 1024 { return "0 KB/s" }
        if absBps < 1_048_576 { return String(format: "%.0f KB/s", Double(absBps) / 1024) }
        return String(format: "%.1f MB/s", Double(absBps) / 1_048_576)
    }
}
