import Foundation

/// 内存使用率监控
final class MemoryMonitor: MonitorProtocol {
    let id = "memory"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "MEM --"
    private(set) var usedBytes: UInt64 = 0
    private(set) var totalBytes: UInt64 = 0
    private(set) var pressure: Int = 0
    private(set) var history: [Double] = []

    private let lock = NSLock()

    func start() {
        lock.withLock {
            displayText = "MEM --"
            history = []
        }
    }

    func stop() {}

    func update() {
        let total = ProcessInfo.processInfo.physicalMemory

        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else {
            lock.withLock { displayText = "MEM --" }
            return
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let activePages = UInt64(vmStats.active_count)
        let wirePages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)
        let used = (activePages + wirePages + compressedPages) * pageSize

        let ratio = Double(used) / Double(total)
        let pressureLevel: Int
        switch ratio {
        case 0..<0.5:  pressureLevel = 1
        case 0.5..<0.75: pressureLevel = 2
        case 0.75..<0.9: pressureLevel = 3
        default:         pressureLevel = 4
        }

        let percent = Int(round(ratio * 100))

        lock.withLock {
            usedBytes = used
            totalBytes = total
            pressure = pressureLevel
            history.append(Double(percent))
            if history.count > 30 { history.removeFirst() }
            displayText = String(format: "MEM %2d%%", percent)
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            let usedGB = String(format: "%.1f GB", Double(usedBytes) / 1_073_741_824)
            let totalGB = String(format: "%.1f GB", Double(totalBytes) / 1_073_741_824)
            let pressureText: String = {
                switch pressure {
                case 1: return "低 🟢"
                case 2: return "中 🟡"
                case 3: return "高 🟠"
                default: return "严重 🔴"
                }
            }()
            let percent = totalBytes > 0 ? Int(round(Double(usedBytes) / Double(totalBytes) * 100)) : 0
            return [
                ("已用", usedGB),
                ("总量", totalGB),
                ("使用率", "\(percent)%"),
                ("压力", pressureText)
            ]
        }
    }

    func getHistory() -> [Double] {
        lock.withLock { Array(history) }
    }
}
