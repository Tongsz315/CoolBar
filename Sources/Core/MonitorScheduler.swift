import Foundation

/// 独立调度每个监控器在指定间隔、指定队列上刷新
final class MonitorScheduler {
    private let monitor: any MonitorProtocol
    private let queue: DispatchQueue
    private var timer: Timer?

    init(monitor: any MonitorProtocol, qos: DispatchQoS.QoSClass = .utility) {
        self.monitor = monitor
        self.queue = DispatchQueue(label: "com.coolbar.monitor.\(monitor.id)", qos: DispatchQoS(qosClass: qos, relativePriority: 0))
    }

    func start() {
        timer?.invalidate()
        monitor.start()
        // 立即在后台执行一次
        queue.async { [weak self] in
            guard let self, self.monitor.isEnabled else { return }
            self.monitor.update()
        }
        // 在主线程创建 Timer 并加入 .common mode，确保 UI 交互时也不暂停
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.monitor.refreshInterval, repeats: true) { [weak self] _ in
                guard let self, self.monitor.isEnabled else { return }
                self.queue.async { self.monitor.update() }
            }
            if let timer = self.timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        monitor.stop()
    }
}
