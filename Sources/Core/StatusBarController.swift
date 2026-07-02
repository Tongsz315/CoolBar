import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem?

    func start() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        let log = "/tmp/coolbar-debug.log"
        "setupStatusItem start\n".data(using: .utf8)?.appendToFile(log)

        // squareLength: 最小固定宽度(~24pt)，最大化在刘海屏 MBP 上的存活率
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            "button nil\n".data(using: .utf8)?.appendToFile(log)
            return
        }

        // 纯图标，不占文字宽度
        let icon = AppIcon.menuBarIcon()
        icon.isTemplate = true
        button.image = icon
        button.imagePosition = .imageOnly
        button.toolTip = "CoolBar - 系统监控 | 右键菜单"

        // 菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "CoolBar", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 CoolBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu

        "icon created (squareLength, imageOnly)\n".data(using: .utf8)?.appendToFile(log)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
