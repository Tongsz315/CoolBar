import Foundation

/// CPU 使用率监控
final class CPUMonitor: MonitorProtocol {
    let id = "cpu"
    let refreshInterval: TimeInterval = 1.0
    var isEnabled = true

    private(set) var displayText = "CPU --"
    private(set) var currentUsage: Double = 0
    private(set) var cores: Int = 0
    private(set) var history: [Double] = []

    private let lock = NSLock()
    private var previousInfo: host_cpu_load_info?

    func start() {
        lock.withLock {
            displayText = "CPU --"
            cores = ProcessInfo.processInfo.activeProcessorCount
        }
    }

    func stop() {}

    func update() {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else {
            lock.withLock { displayText = "CPU --" }
            return
        }

        guard let prev = previousInfo else {
            previousInfo = info
            return
        }

        func safeDiff(_ current: UInt32, _ previous: UInt32) -> Double {
            if current >= previous { return Double(current - previous) }
            return Double(UInt32.max - previous) + Double(current) + 1
        }

        let userDiff = safeDiff(info.cpu_ticks.0, prev.cpu_ticks.0)
        let systemDiff = safeDiff(info.cpu_ticks.1, prev.cpu_ticks.1)
        let idleDiff = safeDiff(info.cpu_ticks.2, prev.cpu_ticks.2)
        let niceDiff = safeDiff(info.cpu_ticks.3, prev.cpu_ticks.3)
        let total = userDiff + systemDiff + idleDiff + niceDiff

        previousInfo = info

        guard total > 0 else {
            lock.withLock { displayText = "CPU --" }
            return
        }

        let usage = ((userDiff + systemDiff + niceDiff) / total) * 100.0
        let rounded = min(100, max(0, round(usage)))

        lock.withLock {
            currentUsage = rounded
            history.append(rounded)
            if history.count > 20 { history.removeFirst() }
            displayText = String(format: "CPU %2.0f%%", rounded)
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            [
                ("使用率", String(format: "%.1f%%", currentUsage)),
                ("核心数", "\(cores) 核"),
                ("架构", "Apple Silicon (ARM64)")
            ]
        }
    }

    func getHistory() -> [Double] {
        lock.withLock { Array(history) }
    }
}
