import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let log = "/tmp/coolbar-debug.log"
        "didFinishLaunching\n".data(using: .utf8)?.appendToFile(log)

        statusBarController = StatusBarController()
        statusBarController?.start()

        "start completed\n".data(using: .utf8)?.appendToFile(log)
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
