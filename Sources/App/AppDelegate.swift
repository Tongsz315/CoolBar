import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let monitors: [MonitorProtocol] = [
            CPUMonitor(),
            GPUMonitor(),
            MemoryMonitor(),
            DiskMonitor(),
            NetworkMonitor(),
            BatteryMonitor(),
            BluetoothMonitor(),
            ClockMonitor(),
        ]

        statusBarController = StatusBarController()
        statusBarController?.start(with: monitors)

        "CoolBar launched: \(monitors.map(\.id))\n".data(using: .utf8)?.appendToFile("/tmp/coolbar-debug.log")
    }
}

extension Data {
    func appendToFile(_ path: String) {
        if let h = FileHandle(forWritingAtPath: path) { h.seekToEndOfFile(); h.write(self); h.closeFile() }
        else { try? write(to: URL(fileURLWithPath: path)) }
    }
}
