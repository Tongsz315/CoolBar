import Foundation
import IOKit

/// 磁盘读写速率监控
final class DiskMonitor: MonitorProtocol {
    let id = "disk"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "DSK --"
    private(set) var readRate: Double = 0
    private(set) var writeRate: Double = 0
    private(set) var history: [(read: Double, write: Double)] = []

    private let lock = NSLock()
    private var prevRead: UInt64 = 0
    private var prevWrite: UInt64 = 0
    private var prevTime: Date?

    func start() {
        lock.withLock {
            displayText = "DSK --"
            history = []
            prevRead = 0; prevWrite = 0; prevTime = nil
        }
    }

    func stop() {}

    func update() {
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

        lock.withLock {
            self.readRate = readRate
            self.writeRate = writeRate
            history.append((read: readRate, write: writeRate))
            if history.count > 30 { history.removeFirst() }

            if readRate < 1024 && writeRate < 1024 {
                displayText = "DSK 0"
            } else if readRate > writeRate {
                displayText = "📖\(Formatters.diskSpeed(readRate))"
            } else {
                displayText = "📝\(Formatters.diskSpeed(writeRate))"
            }
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            [
                ("读取", Formatters.speed(readRate)),
                ("写入", Formatters.speed(writeRate)),
                ("来源", "IOBlockStorageDriver")
            ]
        }
    }

    func getHistory() -> [Double] {
        lock.withLock { history.suffix(20).map(\.read) }
    }

    func getWriteHistory() -> [Double] {
        lock.withLock { history.suffix(20).map(\.write) }
    }

    private func getDiskStats() -> (read: UInt64, write: UInt64) {
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        var iterator: io_iterator_t = 0
        guard let match = IOServiceMatching("IOBlockStorageDriver") else { return (0, 0) }
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator)
        guard result == KERN_SUCCESS else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }
            if let props = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] {
                if let readBytes = props["Bytes (Read)"] as? UInt64 { totalRead &+= readBytes }
                if let writeBytes = props["Bytes (Write)"] as? UInt64 { totalWrite &+= writeBytes }
            }
        }

        return (totalRead, totalWrite)
    }
}
