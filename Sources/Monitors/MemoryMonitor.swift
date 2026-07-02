import Foundation

/// 内存使用率监控
final class MemoryMonitor: MonitorProtocol {
    let id = "memory"
    let title = "MEM"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "MEM --"

    func start() {
        displayText = "MEM --"
    }

    func stop() {}

    func refresh() { _ = update() }

    /// 使用 host_statistics64 获取内存信息
    func update() -> (used: UInt64, total: UInt64, pressure: Int) {
        // 物理内存总量
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        // 使用 host_statistics64 获取 VM 统计
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, totalBytes, 0)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let freePages = UInt64(vmStats.free_count)
        let activePages = UInt64(vmStats.active_count)
        let inactivePages = UInt64(vmStats.inactive_count)
        let wirePages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)

        let used = (activePages + wirePages + compressedPages) * pageSize

        // 内存压力：使用已用内存 / 总量估算
        let pressure: Int
        let ratio = Double(used) / Double(totalBytes)
        switch ratio {
        case 0..<0.5:  pressure = 1  // 低
        case 0.5..<0.75: pressure = 2  // 中
        case 0.75..<0.9: pressure = 3  // 高
        default:         pressure = 4  // 严重
        }

        let percent = Int(round(ratio * 100))

        displayText = String(format: "MEM %2d%%", percent)

        return (used, totalBytes, pressure)
    }

    func detailedInfo() -> [(String, String)] {
        let (used, total, pressure) = update()
        let usedGB = String(format: "%.1f GB", Double(used) / 1_073_741_824)
        let totalGB = String(format: "%.1f GB", Double(total) / 1_073_741_824)
        let pressureText: String = {
            switch pressure {
            case 1: return "低 🟢"
            case 2: return "中 🟡"
            case 3: return "高 🟠"
            default: return "严重 🔴"
            }
        }()
        let percent = Int(round(Double(used) / Double(total) * 100))
        return [
            ("已用", usedGB),
            ("总量", totalGB),
            ("使用率", "\(percent)%"),
            ("压力", pressureText)
        ]
    }
}
