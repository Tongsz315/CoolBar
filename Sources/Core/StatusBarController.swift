import AppKit

/// v9: 套用 Stats 源码的 NSStatusItem 创建方式
/// Stats 直接用 button.addSubview(自定义NSView)，不设 title/image
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var barView: NSView?
    private var menu: NSMenu?
    private var monitors: [any MonitorProtocol] = []
    private var refreshTimer: Timer?
    private var barLabel: NSTextField?
    private var detailPanel: DetailPanelController?
    private let barWidth: CGFloat = 230

    // MARK: - Start

    func start(with monitors: [any MonitorProtocol]) {
        self.monitors = monitors
        setupMenu()
        startMonitors()
        detailPanel = DetailPanelController()

        // 先试 NSStatusItem（Stats 方式）
        if !setupNativeStatusBar() {
            // Fallback: 浮窗
            setupFloatingWindow()
        }
        startRefreshing()
    }

    // MARK: - Stats-style NSStatusItem

    private func setupNativeStatusBar() -> Bool {
        let log = "/tmp/coolbar-debug.log"

        statusItem = NSStatusBar.system.statusItem(withLength: barWidth)
        guard let button = statusItem?.button else {
            "v9: NSStatusItem button nil\n".data(using: .utf8)?.appendToFile(log)
            return false
        }

        // Stats 的关键做法：清空默认 image，直接用 addSubview
        button.image = NSImage(size: NSSize(width: 0, height: 0))
        button.imagePosition = .imageOnly

        // 自定义视图（Stats 用 widget view 作为子视图）
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: barWidth, height: 22))
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 11
        contentView.layer?.masksToBounds = true
        contentView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.85).cgColor

        let label = NSTextField(frame: NSRect(x: 10, y: 0, width: barWidth - 20, height: 22))
        label.stringValue = "CoolBar"
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        label.textColor = .labelColor
        contentView.addSubview(label)
        barLabel = label

        // Stats 方式：直接 addSubview 到 button
        button.addSubview(contentView)
        barView = contentView

        // 点击：左键=详情面板，右键=菜单
        button.target = self
        button.action = #selector(handleStatusClick)
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])

        "v9: Stats-style NSStatusItem created\n".data(using: .utf8)?.appendToFile(log)
        return true
    }

    @objc private func handleStatusClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseDown {
            showMenu()
        } else {
            detailPanel?.toggle(monitors: monitors)
        }
    }

    // MARK: - Floating Window Fallback

    private func setupFloatingWindow() {
        // 如果 fallback 被触发，说明 NSStatusItem 又失败了
        // 暂不实现，先看 NSStatusItem 能不能工作
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

    private func showMenu() {
        guard let menu = menu, let item = statusItem, let button = item.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button)
    }

    // MARK: - Monitors

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
        let parts = monitors
            .filter { $0.isEnabled }
            .map { $0.displayText }
            .filter { !$0.isEmpty && $0 != "-" }
        barLabel?.stringValue = parts.isEmpty ? "CoolBar" : parts.joined(separator: "  ")
    }

    // MARK: - Quit

    @objc private func quitApp() {
        detailPanel?.close()
        for m in monitors { m.stop() }
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
