import Foundation

/// 时钟显示模块
final class ClockMonitor: MonitorProtocol {
    let id = "clock"
    let refreshInterval: TimeInterval = 1.0
    var isEnabled = true

    private(set) var displayText = "--:--"
    private(set) var currentTime = "--:--"

    private let lock = NSLock()

    func start() {
        lock.withLock {
            currentTime = Formatters.timeFormatter.string(from: Date())
            displayText = currentTime
        }
    }

    func stop() {}

    func update() {
        let now = Date()
        let time = Formatters.timeFormatter.string(from: now)
        lock.withLock {
            currentTime = time
            displayText = time
        }
    }

    func detailedInfo() -> [(String, String)] {
        let now = Date()
        let tz = TimeZone.current
        return [
            ("当前时间", Formatters.fullDateFormatter.string(from: now)),
            ("时区", tz.identifier),
            ("偏移", tz.abbreviation() ?? "-")
        ]
    }
}
