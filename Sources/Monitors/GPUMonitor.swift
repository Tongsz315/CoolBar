import Foundation
import Metal

/// GPU 使用率监控 (Apple Silicon)
/// 当前默认禁用，真实 IOReport 实现待接入
final class GPUMonitor: MonitorProtocol {
    let id = "gpu"
    let refreshInterval: TimeInterval = 1.0
    var isEnabled = false

    private(set) var displayText = "GPU --"
    private(set) var currentUsage: Double = 0
    private(set) var history: [Double] = []
    private(set) var gpuName: String = "Apple GPU"

    private let lock = NSLock()
    private var device: MTLDevice?

    func start() {
        lock.withLock {
            displayText = "GPU --"
            history = []
            device = MTLCreateSystemDefaultDevice()
            if let name = device?.name { gpuName = name }
        }
    }

    func stop() {}

    func update() {
        // 默认禁用：不读取数据，避免模拟值
        guard isEnabled else {
            lock.withLock { displayText = "GPU --" }
            return
        }

        // TODO: 接入真实 IOReport 或 MTLCommandBuffer 完成回调统计
        // 当前保留占位实现，返回 0
        lock.withLock {
            currentUsage = 0
            history.append(0)
            if history.count > 30 { history.removeFirst() }
            displayText = "GPU 0%"
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            [
                ("使用率", String(format: "%.1f%%", currentUsage)),
                ("架构", gpuName),
                ("说明", "真实 GPU 监控待接入")
            ]
        }
    }

    func getHistory() -> [Double] {
        lock.withLock { Array(history) }
    }
}
