import AppKit
import SwiftUI

/// 桌面窗口控制器 — 持久化窗口，可拖动、最小化、关闭
final class DetailPanelController {
    private var window: NSWindow?
    private let viewModel: DashboardViewModel
    private let allMonitors: [any MonitorProtocol]
    var isVisible: Bool { window?.isVisible ?? false }

    init(viewModel: DashboardViewModel, allMonitors: [any MonitorProtocol]) {
        self.viewModel = viewModel
        self.allMonitors = allMonitors
    }

    func toggle(monitors: [any MonitorProtocol]) {
        if let w = window {
            if w.isVisible {
                w.orderOut(nil)
                viewModel.pauseUpdating()
            } else {
                viewModel.startUpdating()
                w.makeKeyAndOrderFront(nil)
            }
            return
        }
        show()
    }

    private func show() {
        let stats = StatsWindowView(vm: viewModel, allMonitors: allMonitors)
        let hosting = NSHostingView(rootView: stats)
        hosting.frame = NSRect(x: 0, y: 0, width: 540, height: 460)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "CoolBar"
        w.titlebarAppearsTransparent = true
        w.isMovableByWindowBackground = true
        w.contentView = hosting
        w.backgroundColor = .clear
        w.hasShadow = true
        w.isReleasedWhenClosed = false
        w.delegate = WindowDelegate.shared
        w.center()

        let delegate = WindowDelegate.shared
        delegate.onOrderOut = { [weak self] in self?.viewModel.pauseUpdating() }
        delegate.onMakeKey = { [weak self] in self?.viewModel.startUpdating() }

        w.makeKeyAndOrderFront(nil)
        viewModel.startUpdating()
        self.window = w
    }

    func close() {
        window?.close()
        window = nil
        viewModel.pauseUpdating()
    }
}

private final class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    var onOrderOut: (() -> Void)?
    var onMakeKey: (() -> Void)?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        onOrderOut?()
        return false
    }

    func windowDidBecomeKey(_ notification: Notification) {
        onMakeKey?()
    }
}
