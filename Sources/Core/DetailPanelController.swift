import AppKit
import SwiftUI

/// 桌面窗口控制器 — 持久化窗口，可拖动、最小化、关闭
final class DetailPanelController {
    private var window: NSWindow?
    private var viewModel: DashboardViewModel?
    var isVisible: Bool { window?.isVisible ?? false }

    func toggle(monitors: [any MonitorProtocol]) {
        if let w = window {
            if w.isVisible {
                w.orderOut(nil)        // 已可见 → 隐藏
            } else {
                w.makeKeyAndOrderFront(nil)  // 已关闭 → 重新显示
            }
            return
        }
        show(monitors: monitors)
    }

    private func show(monitors: [any MonitorProtocol]) {
        var cpu: CPUMonitor?; var mem: MemoryMonitor?; var gpu: GPUMonitor?; var disk: DiskMonitor?
        var net: NetworkMonitor?; var bat: BatteryMonitor?; var bt: BluetoothMonitor?; var clk: ClockMonitor?
        for m in monitors {
            if let c = m as? CPUMonitor { cpu = c }
            else if let mm = m as? MemoryMonitor { mem = mm }
            else if let g = m as? GPUMonitor { gpu = g }
            else if let d = m as? DiskMonitor { disk = d }
            else if let n = m as? NetworkMonitor { net = n }
            else if let b = m as? BatteryMonitor { bat = b }
            else if let bb = m as? BluetoothMonitor { bt = bb }
            else if let cc = m as? ClockMonitor { clk = cc }
        }
        guard let c = cpu, let mm = mem, let g = gpu, let d = disk,
              let n = net, let b = bat, let bb = bt, let cc = clk else { return }

        viewModel = DashboardViewModel(cpu: c, mem: mm, gpu: g, disk: d, net: n, bat: b, bt: bb, clk: cc)

        let stats = StatsWindowView(vm: viewModel!, allMonitors: monitors)
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
        w.isMovableByWindowBackground = true   // 可在内容区拖动
        w.contentView = hosting
        w.backgroundColor = .clear
        w.hasShadow = true
        w.isReleasedWhenClosed = false
        w.delegate = WindowDelegate.shared
        w.center()

        w.makeKeyAndOrderFront(nil)
        self.window = w
    }

    func close() {
        window?.close()
        window = nil
    }
}

/// 处理窗口关闭按钮 → 不销毁，只隐藏
private final class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()

    func windowWillClose(_ notification: Notification) {
        // 不设置 window = nil，下次点击菜单栏重新显示
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false  // 不真正关闭
    }
}
