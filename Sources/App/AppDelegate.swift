import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let log = "/tmp/coolbar-debug.log"
        "CoolBar launched (floating window mode)\n".data(using: .utf8)?.appendToFile(log)

        // 创建监控模块
        let monitors: [MonitorProtocol] = [
            CPUMonitor(),
            MemoryMonitor(),
            NetworkMonitor(),
            BatteryMonitor()
        ]

        statusBarController = StatusBarController()
        statusBarController?.start(with: monitors)

        "Monitors started: \(monitors.map { $0.id })\n".data(using: .utf8)?.appendToFile(log)

        // 监听系统外观变化
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // 屏幕参数变化时不需要额外处理
        }
    }
}

extension Data {
    func appendToFile(_ path: String) {
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(self)
            handle.closeFile()
        } else {
            try? write(to: URL(fileURLWithPath: path))
        }
    }
}
