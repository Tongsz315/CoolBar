import AppKit

/// 浮窗式菜单栏控制器
/// 用 NSWindow 替代 NSStatusItem（因 NSStatusItem 在当前系统上不可见）
final class StatusBarController {
    private var barWindow: NSWindow?
    private var menu: NSMenu?
    private var monitors: [any MonitorProtocol] = []
    private var refreshTimer: Timer?
    private var barLabel: NSTextField?

    // MARK: - Start

    func start(with monitors: [any MonitorProtocol]) {
        self.monitors = monitors
        setupBarWindow()
        setupMenu()
        startMonitors()
        startRefreshing()
    }

    // MARK: - Window Setup

    private func setupBarWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.frame
        let visible = screen.visibleFrame
        let menuBarHeight = frame.maxY - visible.maxY

        // 胶囊按钮尺寸
        let winWidth: CGFloat = 230
        let winHeight = menuBarHeight - 5          // 上下各留 2.5pt
        let winX = frame.maxX - winWidth - 12      // 右侧留边距
        let winY = frame.maxY - menuBarHeight + 2.5 // 在菜单栏内居中

        let rect = NSRect(x: winX, y: winY, width: winWidth, height: winHeight)

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces]
        window.ignoresMouseEvents = false

        let content = NSView(frame: NSRect(x: 0, y: 0, width: winWidth, height: winHeight))
        content.wantsLayer = true
        content.layer?.cornerRadius = winHeight / 2        // 胶囊形
        content.layer?.masksToBounds = true
        // 深色半透明胶囊背景
        content.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor

        // 白色文字标签
        let label = NSTextField(frame: NSRect(x: 10, y: 0, width: winWidth - 20, height: winHeight))
        label.stringValue = "CoolBar"
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        label.textColor = .white
        label.cell?.usesSingleLineMode = true
        label.cell?.lineBreakMode = .byClipping
        content.addSubview(label)
        barLabel = label

        // 点击
        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        content.addGestureRecognizer(click)

        content.toolTip = "CoolBar · 右键菜单"
        window.contentView = content
        window.orderFront(nil)
        barWindow = window
    }

    // MARK: - Menu

    private func setupMenu() {
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "CoolBar", action: nil, keyEquivalent: ""))
        menu?.addItem(.separator())
        let quit = NSMenuItem(title: "退出 CoolBar", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu?.addItem(quit)
    }

    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let menu = menu, let win = barWindow else { return }
        let event = NSEvent.mouseEvent(
            with: .rightMouseDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: win.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )
        NSMenu.popUpContextMenu(menu, with: event!, for: win.contentView!)
    }

    // MARK: - Monitors

    private func startMonitors() {
        for m in monitors where m.isEnabled { m.start() }
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        if let t = refreshTimer {
            RunLoop.main.add(t, forMode: .common)
        }
        updateDisplay()
    }

    private func updateDisplay() {
        let text = formatDisplay()
        barLabel?.stringValue = text
        barLabel?.toolTip = formatTooltip()
    }

    private func formatDisplay() -> String {
        let parts = monitors
            .filter { $0.isEnabled }
            .map { $0.displayText }
            .filter { !$0.isEmpty && $0 != "-" }
        return parts.isEmpty ? "CoolBar" : parts.joined(separator: "  ")
    }

    private func formatTooltip() -> String {
        var lines = ["CoolBar — 系统监控"]
        for m in monitors {
            let d = m.detailedInfo().map { "\($0.0): \($0.1)" }.joined(separator: "  ")
            lines.append("▸ \(m.title)  \(d)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Appearance

    func updateForAppearanceChange() {
        // 深色胶囊 + 白字，深浅模式下都保持一致
    }

    // MARK: - Quit

    @objc private func quitApp() {
        for m in monitors { m.stop() }
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
