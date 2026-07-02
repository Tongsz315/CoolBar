import SwiftUI

// MARK: - Snapshots

struct CPUSnapshot: Equatable {
    var percent = "--"; var system = "--"; var user = "--"; var idle = "--"; var cores = "--"
    var history: [Double] = []; var fraction: CGFloat = 0
}

struct MemSnapshot: Equatable {
    var percent = "--"; var used = "--"; var total = "--"; var pressure = "--"
    var history: [Double] = []
    var activeGB = 0.0; var wiredGB = 0.0; var compressedGB = 0.0; var freeGB = 0.0
    var appGB = 0.0; var totalGB = 16.0
    var fraction: CGFloat = 0; var pressureFraction: CGFloat = 0; var pressureLabel = "--"
}

struct GPUSnapshot: Equatable {
    var percent = "--"; var history: [Double] = []; var name = "Apple GPU"; var fraction: CGFloat = 0
}

struct DiskSnapshot: Equatable {
    var read = "--"; var write = "--"
    var history: [Double] = []; var writeHistory: [Double] = []
}

struct NetworkSnapshot: Equatable {
    var download = "--"; var upload = "--"; var history: [Double] = []
}

struct BatterySnapshot: Equatable {
    var percent = "--"; var state = "--"; var time = "--"; var health = "--"; var cycles = "--"
    var fraction: CGFloat = 0
    var stateEnum: BatteryMonitor.BatteryState = .unknown
}

struct BluetoothDeviceSnapshot: Equatable {
    var name = ""
    var battery = 0
}

struct BluetoothSnapshot: Equatable {
    var devices: [BluetoothDeviceSnapshot] = []
}

struct ClockSnapshot: Equatable {
    var time = "--:--"; var full = ""; var tz = ""
}

struct DashboardSnapshot: Equatable {
    var cpu = CPUSnapshot()
    var mem = MemSnapshot()
    var gpu = GPUSnapshot()
    var disk = DiskSnapshot()
    var net = NetworkSnapshot()
    var battery = BatterySnapshot()
    var bluetooth = BluetoothSnapshot()
    var clock = ClockSnapshot()
}

// MARK: - View Model

final class DashboardViewModel: ObservableObject {
    @Published private(set) var snapshot = DashboardSnapshot()

    // CPU
    var cpuPercent: String { snapshot.cpu.percent }
    var cpuSystem: String { snapshot.cpu.system }
    var cpuUser: String { snapshot.cpu.user }
    var cpuIdle: String { snapshot.cpu.idle }
    var cpuCores: String { snapshot.cpu.cores }
    var cpuHistory: [Double] { snapshot.cpu.history }
    var cpuFraction: CGFloat { snapshot.cpu.fraction }

    // Memory
    var memPercent: String { snapshot.mem.percent }
    var memUsed: String { snapshot.mem.used }
    var memTotal: String { snapshot.mem.total }
    var memPressure: String { snapshot.mem.pressure }
    var memHistory: [Double] { snapshot.mem.history }
    var memActiveGB: Double { snapshot.mem.activeGB }
    var memWiredGB: Double { snapshot.mem.wiredGB }
    var memCompressedGB: Double { snapshot.mem.compressedGB }
    var memFreeGB: Double { snapshot.mem.freeGB }
    var memAppGB: Double { snapshot.mem.appGB }
    var memTotalGB: Double { snapshot.mem.totalGB }
    var memFraction: CGFloat { snapshot.mem.fraction }
    var memPressureFraction: CGFloat { snapshot.mem.pressureFraction }
    var memPressureLabel: String { snapshot.mem.pressureLabel }

    // GPU
    var gpuPercent: String { snapshot.gpu.percent }
    var gpuHistory: [Double] { snapshot.gpu.history }
    var gpuName: String { snapshot.gpu.name }
    var gpuFraction: CGFloat { snapshot.gpu.fraction }

    // Disk
    var diskRead: String { snapshot.disk.read }
    var diskWrite: String { snapshot.disk.write }
    var diskHistory: [Double] { snapshot.disk.history }
    var diskWriteHistory: [Double] { snapshot.disk.writeHistory }

    // Network
    var netDownload: String { snapshot.net.download }
    var netUpload: String { snapshot.net.upload }
    var netHistory: [Double] { snapshot.net.history }

    // Battery
    var batteryPercent: String { snapshot.battery.percent }
    var batteryState: String { snapshot.battery.state }
    var batteryTime: String { snapshot.battery.time }
    var batteryHealth: String { snapshot.battery.health }
    var batteryCycles: String { snapshot.battery.cycles }
    var batteryFraction: CGFloat { snapshot.battery.fraction }
    var batteryColor: Color {
        switch snapshot.battery.stateEnum {
        case .charging: return .green
        case .full: return .blue
        default: return snapshot.battery.fraction > 0.2 ? .blue : .red
        }
    }

    // Bluetooth
    var btDevices: [BluetoothDeviceSnapshot] { snapshot.bluetooth.devices }

    // Clock
    var clockTime: String { snapshot.clock.time }
    var clockFull: String { snapshot.clock.full }
    var clockTz: String { snapshot.clock.tz }

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
    }

    deinit { timer?.invalidate() }

    func startUpdating() {
        guard timer == nil else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func pauseUpdating() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        var new = snapshot

        // CPU
        let usage = cpu.currentUsage
        new.cpu.percent = String(format: "%.0f%%", usage)
        new.cpu.system = String(format: "%.0f%%", usage * 0.3)
        new.cpu.user = String(format: "%.0f%%", usage * 0.5)
        new.cpu.idle = String(format: "%.0f%%", max(0, 100 - usage))
        new.cpu.cores = "\(cpu.cores)核"
        new.cpu.history = cpu.getHistory()
        new.cpu.fraction = CGFloat(usage / 100)

        // Memory
        let u = Double(mem.usedBytes)
        let t = Double(mem.totalBytes)
        let tg = t / 1_073_741_824
        let ug = u / 1_073_741_824
        new.mem.totalGB = tg
        new.mem.activeGB = ug * 0.52
        new.mem.wiredGB = ug * 0.18
        new.mem.compressedGB = ug * 0.10
        new.mem.appGB = ug * 0.50
        new.mem.freeGB = max(0, tg - ug)
        let pct = t > 0 ? u / t * 100 : 0
        new.mem.percent = String(format: "%.0f%%", pct)
        new.mem.used = String(format: "%.2f GB", ug)
        new.mem.total = String(format: "%.2f GB", tg)
        new.mem.pressure = ["", "低", "中", "高", "严重"][max(1, min(4, mem.pressure))]
        new.mem.pressureLabel = new.mem.pressure
        new.mem.pressureFraction = CGFloat(mem.pressure) / 4
        new.mem.history = mem.getHistory()
        new.mem.fraction = CGFloat(pct / 100)

        // GPU
        let g = gpu.currentUsage
        new.gpu.percent = String(format: "%.0f%%", g)
        new.gpu.history = gpu.getHistory()
        new.gpu.name = gpu.gpuName
        new.gpu.fraction = CGFloat(g / 100)

        // Disk
        new.disk.read = Formatters.speed(disk.readRate)
        new.disk.write = Formatters.speed(disk.writeRate)
        new.disk.history = disk.getHistory()
        new.disk.writeHistory = disk.getWriteHistory()

        // Network
        new.net.download = Formatters.speed(net.download)
        new.net.upload = Formatters.speed(net.upload)
        new.net.history = net.history.suffix(20).map(\.down)

        // Battery
        let bi = bat.info
        new.battery.percent = "\(bi.percentage)%"
        new.battery.fraction = CGFloat(bi.percentage) / 100
        new.battery.time = bi.timeRemaining
        new.battery.health = bi.health
        new.battery.cycles = "\(bi.cycleCount)"
        new.battery.stateEnum = bi.state
        switch bi.state {
        case .charging: new.battery.state = "充电中"
        case .discharging: new.battery.state = "放电中"
        case .full: new.battery.state = "已充满"
        case .unknown: new.battery.state = "未知"
        }

        // Bluetooth
        new.bluetooth.devices = bt.devices.map { BluetoothDeviceSnapshot(name: $0.name, battery: $0.battery) }

        // Clock
        new.clock.time = clk.currentTime
        new.clock.full = Formatters.fullDateFormatter.string(from: Date())
        new.clock.tz = TimeZone.current.identifier

        if new != snapshot {
            snapshot = new
        }
    }
}
