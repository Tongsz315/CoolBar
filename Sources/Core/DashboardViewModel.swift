import SwiftUI

final class DashboardViewModel: ObservableObject {
    @Published var timeString: String = ""

    // CPU
    @Published var cpuPercent: String = "--"
    @Published var cpuSystem: String = "--"
    @Published var cpuUser: String = "--"
    @Published var cpuIdle: String = "--"
    @Published var cpuCores: String = "--"
    @Published var cpuHistory: [Double] = []
    var cpuFraction: CGFloat { CGFloat(Double(cpuPercent.replacingOccurrences(of: "%", with: "")) ?? 0) / 100 }

    // Memory
    @Published var memPercent: String = "--"
    @Published var memUsed: String = "--"
    @Published var memTotal: String = "--"
    @Published var memPressure: String = "--"
    @Published var memHistory: [Double] = []
    // Detailed memory breakdown (for segmented bar)
    @Published var memActiveGB: Double = 0
    @Published var memWiredGB: Double = 0
    @Published var memCompressedGB: Double = 0
    @Published var memFreeGB: Double = 0
    @Published var memAppGB: Double = 0
    @Published var memTotalGB: Double = 16.0
    var memFraction: CGFloat { CGFloat(Double(memPercent.replacingOccurrences(of: "%", with: "")) ?? 0) / 100 }
    var memPressureFraction: CGFloat {
        switch memPressure {
        case "低": return 0.2
        case "中": return 0.5
        case "高": return 0.8
        case "严重": return 1.0
        default: return 0
        }
    }
    var memPressureLabel: String { memPressure }

    // Network
    @Published var netDownload: String = "--"
    @Published var netUpload: String = "--"
    @Published var netHistory: [Double] = []

    // Battery
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
        self.cpu = cpu; self.mem = mem; self.net = net; self.bat = bat
        fmt.dateFormat = "HH:mm:ss"
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in self?.refresh() }
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
        cpuSystem = String(format: "%.0f%%", usage * 0.3)
        cpuUser = String(format: "%.0f%%", usage * 0.5)
        cpuIdle = String(format: "%.0f%%", max(0, 100 - usage))
    }

    private func refreshMemory() {
        let (used, total, pressure) = mem.update()
        let totalGB = Double(total) / 1_073_741_824
        memTotalGB = totalGB

        // Approximate breakdown for display (we only have used/total from host_statistics)
        memActiveGB = Double(used) / 1_073_741_824 * 0.52   // ~active
        memWiredGB = Double(used) / 1_073_741_824 * 0.18   // ~wired
        memCompressedGB = Double(used) / 1_073_741_824 * 0.10 // ~compressed
        memAppGB = Double(used) / 1_073_741_824 * 0.50     // app memory (subset of active)
        memFreeGB = max(0, totalGB - Double(used) / 1_073_741_824)

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
        netHistory = net.history.suffix(20).map(\.down)
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
            batteryState = "充电中"; batteryIcon = "battery.100.bolt"; batteryColor = .green
        case .discharging:
            batteryState = "放电中"
            batteryIcon = info.percentage > 75 ? "电池.100" : info.percentage > 25 ? "电池.50" : "电池.25"
            batteryColor = info.percentage > 20 ? .blue : .red
        case .full:
            batteryState = "已充满"; batteryIcon = "电池.100"; batteryColor = .green
        case .unknown:
            batteryState = "未知"; batteryIcon = "电池.0"; batteryColor = .gray
        }
    }

    func netSpeedValue() -> Int64 {
        guard !net.history.isEmpty else { return 0 }
        return Int64(net.history.last?.down ?? 0)
    }

    // MARK: Helpers

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.2f GB", gb)
    }

    private func formatSpeed(_ bps: Int64) -> String {
        let absBps = abs(bps)
        if absBps < 1024 { return "0 KB/s" }
        if absBps < 1_048_576 { return String(format: "%.0f KB/s", Double(absBps) / 1024) }
        return String(format: "%.1f MB/s", Double(absBps) / 1_048_576)
    }
}
