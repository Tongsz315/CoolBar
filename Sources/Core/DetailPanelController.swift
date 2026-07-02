import AppKit
import SwiftUI

/// 详情面板控制器 — 管理 Stats 风格弹出面板的显示/隐藏
final class DetailPanelController {
    private var panel: NSPanel?
    private var viewModel: DashboardViewModel?
    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(relativeTo window: NSWindow?, monitors: [any MonitorProtocol]) {
        if let panel = panel, panel.isVisible {
            panel.close()
        } else {
            show(relativeTo: window, monitors: monitors)
        }
    }

    private func show(relativeTo barWindow: NSWindow?, monitors: [any MonitorProtocol]) {
        // 找到对应的 monitor 实例
        var cpu: CPUMonitor?
        var mem: MemoryMonitor?
        var net: NetworkMonitor?
        var bat: BatteryMonitor?
        for m in monitors {
            if let c = m as? CPUMonitor { cpu = c }
            else if let mm = m as? MemoryMonitor { mem = mm }
            else if let n = m as? NetworkMonitor { net = n }
            else if let b = m as? BatteryMonitor { bat = b }
        }

        guard let cpu = cpu, let mem = mem, let net = net, let bat = bat else { return }

        viewModel = DashboardViewModel(cpu: cpu, mem: mem, net: net, bat: bat)

        let dashboard = DashboardView(viewModel: viewModel!)
        let hosting = NSHostingView(rootView: dashboard)
        hosting.frame = NSRect(x: 0, y: 0, width: 300, height: 420)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow

        // 定位：在 CoolBar 浮窗正下方
        if let barWin = barWindow {
            let barFrame = barWin.frame
            let origin = NSPoint(
                x: barFrame.maxX - 300,
                y: barFrame.minY - 420 - 4
            )
            panel.setFrameOrigin(origin)
        }

        panel.orderFront(nil)
        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }
}
