import AppKit

/// 浮窗版菜单栏控制器。
///
/// 在某些机型 / macOS 版本上，NSStatusItem 会被系统控制中心吞掉或无法显示。
/// 浮窗方案将一个小窗口置于 statusBar 层级，作为可靠的可视化入口。
final class FloatingBarController {
    private var window: NSWindow?
    private var effectView: NSVisualEffectView?
    private var label: NSTextField?
    private var monitors: [any MonitorProtocol] = []
    private var detailPanel: DetailPanelController?
    private var refreshTimer: Timer?
    private var lastDisplay = ""
    private var menu: NSMenu?

    func start(with monitors: [any MonitorProtocol], detailPanel: DetailPanelController?) {
        self.monitors = monitors
        self.detailPanel = detailPanel
        DispatchQueue.main.async { [weak self] in
            self?.setupWindow()
            self?.setupMenu()
            self?.startMonitors()
            self?.startRefreshing()
        }
    }

    // MARK: - Window

    private func setupWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let barHeight: CGFloat = 24
        let rightGap: CGFloat = 280   // 右侧留给系统图标 + 时间的空间
        let initialWidth: CGFloat = 120
        let size = NSSize(width: initialWidth, height: barHeight)
        // 默认放在菜单栏右侧、系统图标左侧
        let origin = NSPoint(
            x: screen.frame.maxX - rightGap - size.width,
            y: screen.frame.maxY - barHeight - 2
        )

        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none

        // 胶囊背景
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effectView.material = .menu
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = barHeight / 2
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 0.5
        effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        window.contentView = effectView
        self.effectView = effectView

        // 文本标签
        let label = NSTextField(labelWithString: "CoolBar")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        label.textColor = NSColor.labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: effectView.centerYAnchor),
        ])
        self.label = label

        // 鼠标事件
        let clickView = ClickableView(frame: effectView.bounds)
        clickView.autoresizingMask = [.width, .height]
        clickView.onLeftClick = { [weak self] in self?.didClick() }
        clickView.onRightClick = { [weak self] in self?.showMenu() }
        effectView.addSubview(clickView)

        window.makeKeyAndOrderFront(nil)
        self.window = window

        // 屏幕配置变化时重新定位
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange() {
        guard let window = window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let barHeight: CGFloat = 24
        let rightGap: CGFloat = 280
        let size = NSSize(width: window.frame.width, height: barHeight)
        let origin = NSPoint(
            x: screen.frame.maxX - rightGap - size.width,
            y: screen.frame.maxY - barHeight - 2
        )
        window.setFrame(NSRect(origin: origin, size: size), display: true)
        effectView?.frame = NSRect(origin: .zero, size: size)
    }

    // MARK: - Interaction

    private func didClick() {
        detailPanel?.toggle(monitors: monitors)
    }

    private func setupMenu() {
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "CoolBar", action: nil, keyEquivalent: ""))
        menu?.addItem(.separator())
        let q = NSMenuItem(title: "退出 CoolBar", action: #selector(quitApp), keyEquivalent: "q")
        q.target = self
        menu?.addItem(q)
    }

    private func showMenu() {
        guard let menu = menu, let window = window else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: window.contentView!)
    }

    // MARK: - Refresh

    private func startMonitors() {
        for m in monitors where m.isEnabled { m.start() }
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        if let t = refreshTimer { RunLoop.main.add(t, forMode: .common) }
        updateDisplay()
    }

    private func updateDisplay() {
        let cpuText = monitors.first { $0.id == "cpu" && $0.isEnabled }?.displayText ?? ""
        let memText = monitors.first { $0.id == "memory" && $0.isEnabled }?.displayText ?? ""
        let parts = [cpuText, memText].filter { !$0.isEmpty && $0 != "-" }
        let text = parts.isEmpty ? "CoolBar" : parts.joined(separator: "  ")
        guard text != lastDisplay else { return }
        lastDisplay = text
        label?.stringValue = text

        // 根据文本宽度自适应窗口大小，保持右边缘对齐
        guard let window = window, let label = label else { return }
        let size = label.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: 22))
        let newWidth = max(min(size.width + 24, 220), 80)
        let barHeight: CGFloat = 24
        var frame = window.frame
        let rightX = frame.maxX
        frame.origin.x = rightX - newWidth
        frame.size.width = newWidth
        frame.size.height = barHeight
        window.setFrame(frame, display: true)
    }

    @objc private func quitApp() {
        detailPanel?.close()
        for m in monitors { m.stop() }
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Clickable View

private final class ClickableView: NSView {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onLeftClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}
