import Foundation

/// 网络速率监控（上下行）
final class NetworkMonitor: MonitorProtocol {
    let id = "network"
    let refreshInterval: TimeInterval = 2.0
    var isEnabled = true

    private(set) var displayText = "NET --"
    private(set) var download: Double = 0
    private(set) var upload: Double = 0
    private(set) var history: [(down: Double, up: Double)] = []

    private let lock = NSLock()
    private var previousBytes: (in: UInt64, out: UInt64)?
    private var previousTime: Date?

    func start() {
        lock.withLock {
            displayText = "NET --"
            history = []
            previousBytes = nil
            previousTime = nil
        }
    }

    func stop() {}

    func update() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            lock.withLock { displayText = "NET --" }
            return
        }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = first
        while true {
            let interface = ptr.pointee

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
                totalIn &+= UInt64(data.ifi_ibytes)
                totalOut &+= UInt64(data.ifi_obytes)
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        freeifaddrs(ifaddr)

        let now = Date()
        var download: Double = 0
        var upload: Double = 0

        if let prev = previousBytes, let prevTime = previousTime {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 {
                let inDiff: Double = totalIn >= prev.in ? Double(totalIn &- prev.in) / elapsed : 0
                let outDiff: Double = totalOut >= prev.out ? Double(totalOut &- prev.out) / elapsed : 0
                download = inDiff
                upload = outDiff
            }
        }

        previousBytes = (totalIn, totalOut)
        previousTime = now

        lock.withLock {
            self.download = download
            self.upload = upload
            history.append((down: download, up: upload))
            if history.count > 30 { history.removeFirst() }

            let downStr = Formatters.speed(download)
            displayText = "↓\(downStr)"
            if download < 1024 && upload >= 1024 {
                displayText = "↑\(Formatters.speed(upload))"
            }
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            [
                ("下载", Formatters.speed(download)),
                ("上传", Formatters.speed(upload)),
                ("接口", "en0 (Wi-Fi)")
            ]
        }
    }
}
