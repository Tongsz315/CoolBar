import AppKit

/// 菜单栏控制器 — 使用可靠的浮窗方案
final class StatusBarController {
    private var barWindow: NSWindow?
    private var menu: NSMenu?
    private var monitors: [any MonitorProtocol] = []
    private var refreshTimer: Timer?
    private var barLabel: NSTextField?
    private var detailPanel: DetailPanelController?

    func start(with monitors: [any MonitorProtocol]) {
        self.monitors = monitors
        setupBarWindow()
        setupMenu()
        startMonitors()
        startRefreshing()
        detailPanel = DetailPanelController()
    }

    // MARK: - Floating Window (可靠方案)

    private func setupBarWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.frame
        let visible = screen.visibleFrame
        let menuBarHeight = frame.maxY - visible.maxY

        let w: CGFloat = 230, h = menuBarHeight - 5
        let x = frame.maxX - w - 12
        let y = frame.maxY - menuBarHeight + 2.5
        let rect = NSRect(x: x, y: y, width: w, height: h)

        let window = NSWindow(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered, defer: false)
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces]

        let content = BarView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        content.wantsLayer = true
        content.layer?.cornerRadius = h / 2
        content.layer?.masksToBounds = true
        content.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.85).cgColor

        content.onLeftClick = { [weak self] in self?.detailPanel?.toggle(monitors: self?.monitors ?? []) }
        content.onRightClick = { [weak self] in self?.showMenu() }

        let label = NSTextField(frame: NSRect(x: 10, y: 0, width: w - 20, height: h))
        label.stringValue = "CoolBar"
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        label.textColor = .labelColor
        content.addSubview(label)
        barLabel = label

        content.toolTip = "左键仪表板 · 右键菜单"
        window.contentView = content
        window.orderFront(nil)
        barWindow = window
    }

    private func setupMenu() {
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "CoolBar", action: nil, keyEquivalent: ""))
        menu?.addItem(.separator())
        let q = NSMenuItem(title: "退出 CoolBar", action: #selector(quitApp), keyEquivalent: "q")
        q.target = self; menu?.addItem(q)
    }

    private func showMenu() {
        guard let m = menu, let w = barWindow else { return }
        m.popUp(positioning: nil, at: .zero, in: w.contentView)
    }

    private func startMonitors() {
        for m in monitors where m.isEnabled { m.start() }
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        if let t = refreshTimer { RunLoop.main.add(t, forMode: .common) }
        updateDisplay()
    }

    private func updateDisplay() {
        let parts = monitors.filter(\.isEnabled).map(\.displayText).filter { !$0.isEmpty && $0 != "-" }
        barLabel?.stringValue = parts.isEmpty ? "CoolBar" : parts.joined(separator: "  ")
    }

    @objc private func quitApp() {
        detailPanel?.close()
        for m in monitors { m.stop() }; refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}

private final class BarView: NSView {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?
    override func mouseDown(with e: NSEvent) { onLeftClick?() }
    override func rightMouseDown(with e: NSEvent) { onRightClick?() }
}
