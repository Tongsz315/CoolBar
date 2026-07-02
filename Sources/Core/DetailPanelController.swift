import AppKit
import SwiftUI

final class DetailPanelController {
    private var panel: NSPanel?
    private var viewModel: DashboardViewModel?
    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(relativeTo window: NSWindow?, monitors: [any MonitorProtocol]) {
        if let p = panel, p.isVisible { p.close() }
        else { show(relativeTo: window, monitors: monitors) }
    }

    private func show(relativeTo barWindow: NSWindow?, monitors: [any MonitorProtocol]) {
        var cpu: CPUMonitor?; var mem: MemoryMonitor?; var net: NetworkMonitor?; var bat: BatteryMonitor?
        for m in monitors {
            if let c = m as? CPUMonitor { cpu = c }
            else if let mm = m as? MemoryMonitor { mem = mm }
            else if let n = m as? NetworkMonitor { net = n }
            else if let b = m as? BatteryMonitor { bat = b }
        }
        guard let c = cpu, let m = mem, let n = net, let b = bat else { return }

        viewModel = DashboardViewModel(cpu: c, mem: m, net: n, bat: b)
        let statsView = StatsWindowView(vm: viewModel!)
        let hosting = NSHostingView(rootView: statsView)
        hosting.frame = NSRect(x: 0, y: 0, width: 540, height: 440)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces]
        p.isReleasedWhenClosed = false

        // Position below CoolBar capsule
        if let barWin = barWindow {
            let bf = barWin.frame
            p.setFrameOrigin(NSPoint(x: bf.maxX - 552, y: bf.minY - 448))
        }

        p.orderFront(nil)
        self.panel = p
    }

    func close() { panel?.close(); panel = nil }
}
