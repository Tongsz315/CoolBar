import Foundation

/// 网络速率监控（上下行）
final class NetworkMonitor: MonitorProtocol {
    let id = "network"
    let title = "NET"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "NET --"
    private(set) var history: [(down: Double, up: Double)] = []
    private var previousBytes: (in: UInt64, out: UInt64)?
    private var previousTime: Date?

    func start() {
        displayText = "NET --"
        history = []
        previousBytes = nil
        previousTime = nil
    }

    func stop() {}

    func refresh() { _ = update() }

    /// 使用 getifaddrs 获取网络接口流量
    func update() -> (download: Double, upload: Double) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return (0, 0)
        }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = first
        while true {
            let interface = ptr.pointee

            // 跳过不符合条件的接口
            let shouldSkip: Bool
            if let name = String(validatingUTF8: interface.ifa_name) {
                if name == "lo0" || name.hasPrefix("utun") || name.hasPrefix("llw") || name.hasPrefix("anpi") {
                    shouldSkip = true
                } else if let addr = interface.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                    shouldSkip = false
                } else {
                    shouldSkip = true
                }
            } else {
                shouldSkip = true
            }

            if !shouldSkip, let ifaData = interface.ifa_data {
                let data = ifaData.assumingMemoryBound(to: if_data.self).pointee
                totalIn += UInt64(data.ifi_ibytes)
                totalOut += UInt64(data.ifi_obytes)
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        freeifaddrs(ifaddr)

        let now = Date()
        let download: Double
        let upload: Double

        if let prev = previousBytes, let prevTime = previousTime {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 {
                // 安全减法：防止计数器回绕/重置导致 UInt64 下溢崩溃
                let inDiff: Double
                let outDiff: Double
                if totalIn >= prev.in {
                    inDiff = Double(totalIn - prev.in) / elapsed
                } else {
                    inDiff = 0  // 计数器重置或回绕
                }
                if totalOut >= prev.out {
                    outDiff = Double(totalOut - prev.out) / elapsed
                } else {
                    outDiff = 0
                }
                download = inDiff
                upload = outDiff
            } else {
                download = 0
                upload = 0
            }
        } else {
            download = 0
            upload = 0
        }

        previousBytes = (totalIn, totalOut)
        previousTime = now

        // 格式化显示
        let downStr = formatSpeed(download)
        displayText = "↓\(downStr)"

        // 如果下载几乎为 0，显示上传
        if download < 1024 && upload >= 1024 {
            let upStr = formatSpeed(upload)
            displayText = "↑\(upStr)"
        }

        // 记录历史
        history.append((down: download, up: upload))
        if history.count > 30 { history.removeFirst() }

        return (download, upload)
    }

    func detailedInfo() -> [(String, String)] {
        let (down, up) = update()
        return [
            ("下载", formatSpeed(down)),
            ("上传", formatSpeed(up)),
            ("接口", "en0 (Wi-Fi)")
        ]
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return "0 KB/s"
        } else if bytesPerSec < 1_048_576 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576)
        }
    }
}
