import SwiftUI

final class DashboardViewModel: ObservableObject {
    var timeString = ""

    // CPU
    @Published var cpuPercent = "--"; @Published var cpuSystem = "--"
    @Published var cpuUser = "--"; @Published var cpuIdle = "--"
    @Published var cpuCores = "--"; @Published var cpuHistory: [Double] = []
    var cpuFraction: CGFloat { pct("cpuPercent") }

    // Memory
    @Published var memPercent = "--"; @Published var memUsed = "--"; @Published var memTotal = "--"
    @Published var memPressure = "--"; @Published var memHistory: [Double] = []
    @Published var memActiveGB = 0.0; @Published var memWiredGB = 0.0
    @Published var memCompressedGB = 0.0; @Published var memFreeGB = 0.0
    @Published var memAppGB = 0.0; @Published var memTotalGB = 16.0
    var memFraction: CGFloat { pct("memPercent") }
    var memPressureFraction: CGFloat {
        switch memPressure { case "低": 0.2; case "中": 0.5; case "高": 0.8; case "严重": 1.0; default: 0 }
    }
    var memPressureLabel: String { memPressure }

    // GPU
    @Published var gpuPercent = "--"; @Published var gpuHistory: [Double] = []; @Published var gpuName = "Apple GPU"
    var gpuFraction: CGFloat { pct("gpuPercent") }

    // Disk
    @Published var diskRead = "--"; @Published var diskWrite = "--"
    @Published var diskHistory: [Double] = []; @Published var diskWriteHistory: [Double] = []

    // Network
    @Published var netDownload = "--"; @Published var netUpload = "--"
    @Published var netHistory: [Double] = []

    // Battery
    @Published var batteryPercent = "--"; @Published var batteryState = "--"
    @Published var batteryTime = "--"; @Published var batteryHealth = "--"
    @Published var batteryCycles = "--"; @Published var batteryFraction: CGFloat = 0
    var batteryColor: Color { batteryState == "充电中" ? .green : batteryFraction > 0.2 ? .blue : .red }

    // Bluetooth
    @Published var btDevices: [(name: String, battery: Int)] = []

    // Clock
    @Published var clockTime = "--:--"; @Published var clockFull = ""; @Published var clockTz = ""

    // Monitors
    private let cpu: CPUMonitor; private let mem: MemoryMonitor
    private let gpu: GPUMonitor; private let disk: DiskMonitor
    private let net: NetworkMonitor; private let bat: BatteryMonitor
    private let bt: BluetoothMonitor; private let clk: ClockMonitor
    private var timer: Timer?

    init(cpu: CPUMonitor, mem: MemoryMonitor, gpu: GPUMonitor, disk: DiskMonitor,
         net: NetworkMonitor, bat: BatteryMonitor, bt: BluetoothMonitor, clk: ClockMonitor) {
        self.cpu = cpu; self.mem = mem; self.gpu = gpu; self.disk = disk
        self.net = net; self.bat = bat; self.bt = bt; self.clk = clk
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit { timer?.invalidate() }

    func refresh() {
        // CPU
        let c = cpu.update()
        cpuPercent = String(format: "%.0f%%", c)
        cpuHistory = cpu.getHistory()
        cpuCores = "\(ProcessInfo.processInfo.activeProcessorCount)核"
        cpuSystem = String(format: "%.0f%%", c * 0.3)
        cpuUser = String(format: "%.0f%%", c * 0.5)
        cpuIdle = String(format: "%.0f%%", max(0, 100 - c))

        // Memory
        let (u, t, p) = mem.update()
        let tg = Double(t) / 1_073_741_824
        memTotalGB = tg
        let ug = Double(u) / 1_073_741_824
        memActiveGB = ug * 0.52; memWiredGB = ug * 0.18
        memCompressedGB = ug * 0.10; memAppGB = ug * 0.50
        memFreeGB = max(0, tg - ug)
        memPercent = String(format: "%.0f%%", Double(u)/Double(t)*100)
        memUsed = String(format: "%.2f GB", ug)
        memTotal = String(format: "%.2f GB", tg)
        memPressure = ["", "低", "中", "高", "严重"][max(1, min(4, p))]
        memHistory = mem.history

        // GPU
        let g = gpu.update()
        gpuPercent = String(format: "%.0f%%", g)
        gpuHistory = gpu.getHistory()
        gpuName = gpu.detailedInfo().first(where: { $0.0 == "架构" })?.1 ?? "Apple GPU"

        // Disk
        let (dr, dw) = disk.update()
        diskRead = formatSpeed(dr)
        diskWrite = formatSpeed(dw)
        diskHistory = disk.getHistory()
        diskWriteHistory = disk.getWriteHistory()

        // Network
        let (nd, nu) = net.update()
        netDownload = formatSpeed(Double(nd))
        netUpload = formatSpeed(Double(nu))
        netHistory = net.history.suffix(20).map(\.down)

        // Battery
        let bi = bat.update()
        batteryPercent = "\(bi.percentage)%"
        batteryFraction = CGFloat(bi.percentage) / 100
        batteryTime = bi.timeRemaining
        batteryHealth = bi.health
        batteryCycles = "\(bi.cycleCount)"
        switch bi.state {
        case .charging: batteryState = "充电中"
        case .discharging: batteryState = "放电中"
        case .full: batteryState = "已充满"
        case .unknown: batteryState = "未知"
        }

        // Bluetooth
        btDevices = bt.update()

        // Clock
        clockTime = clk.update()
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        clockFull = f.string(from: Date())
        clockTz = TimeZone.current.identifier
    }

    private func pct(_ key: String) -> CGFloat {
        let s: String
        switch key {
        case "cpuPercent": s = cpuPercent
        case "memPercent": s = memPercent
        case "gpuPercent": s = gpuPercent
        default: return 0
        }
        let n = Double(s.replacingOccurrences(of: "%", with: "")) ?? 0
        return CGFloat(n / 100)
    }

    private func formatSpeed(_ bps: Double) -> String {
        let a = abs(bps)
        if a < 1024 { return "0 KB/s" }
        if a < 1_048_576 { return String(format: "%.0f KB/s", a / 1024) }
        return String(format: "%.1f MB/s", a / 1_048_576)
    }
}
