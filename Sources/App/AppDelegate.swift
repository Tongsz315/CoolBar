import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingBarController: FloatingBarController?
    private var detailPanel: DetailPanelController?
    private var schedulers: [MonitorScheduler] = []
    private var monitors: [any MonitorProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitors = [
            CPUMonitor(),
            GPUMonitor(),
            MemoryMonitor(),
            DiskMonitor(),
            NetworkMonitor(),
            BatteryMonitor(),
            BluetoothMonitor(),
            ClockMonitor(),
        ]

        guard let cpu = monitors.first(where: { $0 is CPUMonitor }) as? CPUMonitor,
              let mem = monitors.first(where: { $0 is MemoryMonitor }) as? MemoryMonitor,
              let gpu = monitors.first(where: { $0 is GPUMonitor }) as? GPUMonitor,
              let disk = monitors.first(where: { $0 is DiskMonitor }) as? DiskMonitor,
              let net = monitors.first(where: { $0 is NetworkMonitor }) as? NetworkMonitor,
              let bat = monitors.first(where: { $0 is BatteryMonitor }) as? BatteryMonitor,
              let bt = monitors.first(where: { $0 is BluetoothMonitor }) as? BluetoothMonitor,
              let clk = monitors.first(where: { $0 is ClockMonitor }) as? ClockMonitor else {
            return
        }

        let viewModel = DashboardViewModel(cpu: cpu, mem: mem, gpu: gpu, disk: disk,
                                           net: net, bat: bat, bt: bt, clk: clk)
        detailPanel = DetailPanelController(viewModel: viewModel, allMonitors: monitors)

        floatingBarController = FloatingBarController()
        floatingBarController?.start(with: monitors, detailPanel: detailPanel)

        schedulers = monitors.map { monitor in
            let qos: DispatchQoS.QoSClass
            switch monitor.id {
            case "disk", "battery", "bluetooth": qos = .background
            default: qos = .utility
            }
            let scheduler = MonitorScheduler(monitor: monitor, qos: qos)
            scheduler.start()
            return scheduler
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        schedulers.forEach { $0.stop() }
    }
}
