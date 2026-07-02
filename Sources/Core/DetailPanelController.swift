import AppKit
import SwiftUI

final class DetailPanelController {
    private var panel: NSPanel?
    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(monitors: [any MonitorProtocol]) {
        if let p = panel, p.isVisible { p.close(); return }
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

        let vm = DashboardViewModel(cpu: c, mem: mm, gpu: g, disk: d, net: n, bat: b, bt: bb, clk: cc)
        let stats = StatsWindowView(vm: vm, allMonitors: monitors)
        let hosting = NSHostingView(rootView: stats)
        hosting.frame = NSRect(x: 0, y: 0, width: 540, height: 460)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 460),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
        p.level = .floating; p.collectionBehavior = [.canJoinAllSpaces]
        p.isReleasedWhenClosed = false

        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            p.setFrameOrigin(NSPoint(x: vf.maxX - 552, y: vf.maxY - 468))
        }
        p.orderFront(nil)
        self.panel = p
    }

    func close() { panel?.close(); panel = nil }
}
