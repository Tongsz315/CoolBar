import Foundation

/// CPU 使用率监控
final class CPUMonitor: MonitorProtocol {
    let id = "cpu"
    let title = "CPU"
    let refreshInterval: TimeInterval = 1.0
    var isEnabled = true

    private(set) var displayText = "CPU --"
    private var previousInfo: host_cpu_load_info?
    private var history: [Double] = []

    func start() {
        displayText = "CPU --"
    }

    func stop() {}

    func refresh() { _ = update() }

    /// 使用 host_processor_info 获取 CPU 使用率
    func update() -> Double {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        guard let prev = previousInfo else {
            previousInfo = info
            return 0
        }

        // 安全减法：处理 cpu_ticks (UInt32) 回绕
        func safeDiff(_ current: UInt32, _ previous: UInt32) -> Double {
            if current >= previous {
                return Double(current - previous)
            }
            // 回绕：current 从 0 重新开始
            return Double(UInt32.max - previous) + Double(current) + 1
        }

        let userDiff = safeDiff(info.cpu_ticks.0, prev.cpu_ticks.0)
        let systemDiff = safeDiff(info.cpu_ticks.1, prev.cpu_ticks.1)
        let idleDiff = safeDiff(info.cpu_ticks.2, prev.cpu_ticks.2)
        let niceDiff = safeDiff(info.cpu_ticks.3, prev.cpu_ticks.3)
        let total = userDiff + systemDiff + idleDiff + niceDiff

        previousInfo = info

        guard total > 0 else { return 0 }

        let usage = ((userDiff + systemDiff + niceDiff) / total) * 100.0
        let rounded = min(100, max(0, round(usage)))

        // 记录历史（最多 20 个点给迷你图）
        history.append(rounded)
        if history.count > 20 { history.removeFirst() }

        displayText = String(format: "CPU %2.0f%%", rounded)
        return rounded
    }

    func detailedInfo() -> [(String, String)] {
        let usage = update()
        let cores = ProcessInfo.processInfo.activeProcessorCount
        return [
            ("使用率", String(format: "%.1f%%", usage)),
            ("核心数", "\(cores) 核"),
            ("架构", "Apple Silicon (ARM64)")
        ]
    }

    func getHistory() -> [Double] { history }
}
