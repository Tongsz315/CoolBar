import AppKit

/// 浮窗式菜单栏控制器
/// 用 NSWindow 替代 NSStatusItem（因 NSStatusItem 在当前系统上不可见）
final class StatusBarController {
    private var barWindow: NSWindow?
    private var menu: NSMenu?
    private var monitors: [any MonitorProtocol] = []
    private var refreshTimer: Timer?
    private var displayText: String = "CoolBar"

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
        let screenFrame = screen.frame
        let menuBarHeight: CGFloat = screen.frame.maxY - screen.visibleFrame.maxY
        let winHeight = max(22, menuBarHeight - 4)

        // 窗口位置：菜单栏右侧
        let winWidth: CGFloat = 120
        let winX = screenFrame.maxX - winWidth - 8
        let winY = screenFrame.maxY - menuBarHeight + 2

        let rect = NSRect(x: winX, y: winY, width: winWidth, height: winHeight)

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.ignoresMouseEvents = false

        // 内容视图
        let contentView = createBarContentView(width: winWidth, height: winHeight)
        window.contentView = contentView
        window.orderFront(nil)

        barWindow = window
    }

    private func createBarContentView(width: CGFloat, height: CGFloat) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        // 半透明背景
        container.wantsLayer = true
        container.layer?.cornerRadius = 6
        container.layer?.masksToBounds = true
        updateAppearance(container)

        // 文字标签
        let label = NSTextField(frame: NSRect(x: 2, y: 1, width: width - 4, height: height - 2))
        label.stringValue = "CoolBar"
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .labelColor
        label.identifier = NSUserInterfaceItemIdentifier("barLabel")
        container.addSubview(label)

        // 点击事件
        let clickGesture = NSClickGestureRecognizer(
            target: self,
            action: #selector(handleBarClick(_:))
        )
        container.addGestureRecognizer(clickGesture)

        // 提示
        container.toolTip = "CoolBar - 系统监控 | 右键菜单"

        return container
    }

    /// 更新外观以匹配系统主题
    private func updateAppearance(_ view: NSView) {
        let isDark = NSApp.effectiveAppearance.name == .darkAqua ||
                     NSApp.effectiveAppearance.name == .vibrantDark
        if isDark {
            view.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        } else {
            view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.08).cgColor
        }
    }

    // MARK: - Menu

    private func setupMenu() {
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "CoolBar", action: nil, keyEquivalent: ""))
        menu?.addItem(.separator())
        menu?.addItem(NSMenuItem(title: "退出 CoolBar", action: #selector(quitApp), keyEquivalent: "q"))
    }

    @objc private func handleBarClick(_ gesture: NSClickGestureRecognizer) {
        guard let menu = menu, let window = barWindow else { return }

        // 在浮窗下方弹出菜单
        let point = NSPoint(x: 0, y: 0)
        let event = NSEvent.mouseEvent(
            with: .rightMouseDown,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )
        NSMenu.popUpContextMenu(menu, with: event!, for: window.contentView!)
    }

    // MARK: - Monitors

    private func startMonitors() {
        for monitor in monitors where monitor.isEnabled {
            monitor.start()
        }
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        // 在 common 模式下运行，避免弹窗时暂停
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        updateDisplay()
    }

    private func updateDisplay() {
        guard let container = barWindow?.contentView else { return }
        guard let label = container.viewWithTag(
            container.subviews.first(where: { $0 is NSTextField })?.tag ?? -1
        ) as? NSTextField else {
            // Fallback: 通过 identifier 查找
            if let lbl = container.subviews.first(where: {
                ($0 as? NSTextField)?.identifier?.rawValue == "barLabel"
            }) as? NSTextField {
                displayText = formatDisplay()
                lbl.stringValue = displayText
            }
            return
        }

        displayText = formatDisplay()
        label.stringValue = displayText
        label.toolTip = formatTooltip()
    }

    private func formatDisplay() -> String {
        // 简洁一行：CPU% Mem%
        var parts: [String] = []
        for m in monitors where m.isEnabled {
            let text = m.displayText
            if !text.isEmpty, text != "-" {
                parts.append(text)
            }
        }
        return parts.isEmpty ? "CoolBar" : parts.joined(separator: " ")
    }

    private func formatTooltip() -> String {
        var lines: [String] = ["CoolBar - 系统监控"]
        for m in monitors {
            let details = m.detailedInfo()
            let values = details.map { "\($0.0): \($0.1)" }.joined(separator: ", ")
            lines.append("[\(m.title)] \(values)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Appearance

    /// 系统主题变化时重新渲染
    func updateForAppearanceChange() {
        if let view = barWindow?.contentView {
            updateAppearance(view)
        }
    }

    // MARK: - Quit

    @objc private func quitApp() {
        for m in monitors { m.stop() }
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
