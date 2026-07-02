import Foundation

/// 时钟显示模块
final class ClockMonitor: MonitorProtocol {
    let id = "clock"
    let title = "CLK"
    let refreshInterval: TimeInterval = 1.0
    var isEnabled = true

    private(set) var displayText = "--:--"
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    func start() { displayText = formatter.string(from: Date()) }
    func stop() {}
    func refresh() { _ = update() }

    func update() -> String {
        let now = Date()
        let time = formatter.string(from: now)
        displayText = time
        return time
    }

    func detailedInfo() -> [(String, String)] {
        let now = Date()
        let full = DateFormatter(); full.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let tz = TimeZone.current
        return [
            ("当前时间", full.string(from: now)),
            ("时区", tz.identifier),
            ("偏移", "\(tz.abbreviation() ?? "-")"),
        ]
    }
}
