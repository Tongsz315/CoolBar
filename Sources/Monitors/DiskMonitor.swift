import Foundation
import IOKit

/// 磁盘读写速率监控
/// 通过 IOKit IOBlockStorageDriver 获取统计
final class DiskMonitor: MonitorProtocol {
    let id = "disk"
    let title = "DSK"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "DSK --"
    private(set) var history: [(read: Double, write: Double)] = []
    private var prevRead: UInt64 = 0
    private var prevWrite: UInt64 = 0
    private var prevTime: Date?

    func start() {
        displayText = "DSK --"
        history = []
        prevRead = 0; prevWrite = 0; prevTime = nil
    }

    func stop() {}

    func refresh() { _ = update() }

    func update() -> (read: Double, write: Double) {
        let (totalRead, totalWrite) = getDiskStats()
        let now = Date()

        let readRate: Double
        let writeRate: Double

        if let pt = prevTime, prevRead > 0 || prevWrite > 0 {
            let elapsed = now.timeIntervalSince(pt)
            if elapsed > 0 {
                let readDiff = totalRead >= prevRead ? Double(totalRead - prevRead) / elapsed : 0
                let writeDiff = totalWrite >= prevWrite ? Double(totalWrite - prevWrite) / elapsed : 0
                readRate = readDiff
                writeRate = writeDiff
            } else {
                readRate = 0; writeRate = 0
            }
        } else {
            readRate = 0; writeRate = 0
        }

        prevRead = totalRead; prevWrite = totalWrite; prevTime = now

        history.append((read: readRate, write: writeRate))
        if history.count > 30 { history.removeFirst() }

        if readRate < 1024 && writeRate < 1024 {
            displayText = "DSK 0"
        } else {
            let r = formatSpeed(readRate)
            let w = formatSpeed(writeRate)
            if readRate > writeRate {
                displayText = "📖\(r)"
            } else {
                displayText = "📝\(w)"
            }
        }

        return (readRate, writeRate)
    }

    func getHistory() -> [Double] {
        // Return read rates for chart
        history.suffix(20).map(\.read)
    }

    func getWriteHistory() -> [Double] {
        history.suffix(20).map(\.write)
    }

    func detailedInfo() -> [(String, String)] {
        let (read, write) = update()
        return [
            ("读取", formatSpeed(read)),
            ("写入", formatSpeed(write)),
            ("来源", "IOBlockStorageDriver"),
        ]
    }

    // MARK: - IOKit

    private func getDiskStats() -> (read: UInt64, write: UInt64) {
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        var iterator: io_iterator_t = 0
        guard let match = IOServiceMatching("IOBlockStorageDriver") else {
            return (0, 0)
        }
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator)
        guard result == KERN_SUCCESS else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }

            if let props = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] {
                if let readBytes = props["Bytes (Read)"] as? UInt64 {
                    totalRead += readBytes
                }
                if let writeBytes = props["Bytes (Write)"] as? UInt64 {
                    totalWrite += writeBytes
                }
            }
        }

        return (totalRead, totalWrite)
    }

    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return "0" }
        if bps < 1_048_576 { return String(format: "%.0fK", bps / 1024) }
        return String(format: "%.1fM", bps / 1_048_576)
    }
}
