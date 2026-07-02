import AppKit

/// 菜单栏溢出折叠控制器
final class OverflowController {
    private var overflowItem: NSStatusItem?

    init() {
        setupOverflowButton()
    }

    private func setupOverflowButton() {
        overflowItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = overflowItem?.button {
            button.image = createOverflowIcon()
            button.toolTip = "CoolBar"
            button.target = self
            button.action = #selector(overflowClicked(_:))
        }

        // 右键菜单
        let menu = NSMenu()
        menu.autoenablesItems = false

        let header = NSMenuItem()
        header.title = "CoolBar"
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let detailItem = NSMenuItem(
            title: "系统状态总览",
            action: #selector(openDetail),
            keyEquivalent: ""
        )
        detailItem.target = self
        menu.addItem(detailItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "偏好设置...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        let quitItem = NSMenuItem(
            title: "退出 CoolBar",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        overflowItem?.menu = menu
    }

    @objc private func overflowClicked(_ sender: NSStatusBarButton) {
        // 设置 menu 后，左键会自动弹出菜单，无需手动处理
    }

    @objc private func openDetail() {
        // TODO: 打开系统状态总览 Popover
    }

    @objc private func openPreferences() {
        // TODO: 打开偏好设置窗口
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func createOverflowIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let dotSize: CGFloat = 3
        let spacing: CGFloat = 5
        let y = (size.height - dotSize) / 2

        for i in 0..<3 {
            let x = (size.width - (dotSize * 3 + spacing * 2)) / 2 + CGFloat(i) * (dotSize + spacing)
            let path = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dotSize, height: dotSize))
            NSColor.secondaryLabelColor.setFill()
            path.fill()
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
