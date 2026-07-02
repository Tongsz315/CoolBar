import Foundation

/// 监控数据提供者基类 — 处理定时器、数据缓存等通用逻辑
class DataProvider {
    private var timer: Timer?
    private var refreshBlock: (() -> Void)?

    /// 启动定时刷新
    func start(refreshInterval: TimeInterval, block: @escaping () -> Void) {
        refreshBlock = block
        // 立即执行一次
        block()
        // 使用 common mode，确保 Popover/Modal 弹出时也能继续刷新
        let timer = Timer(timeInterval: refreshInterval, repeats: true) { _ in
            block()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// 停止刷新
    func stop() {
        timer?.invalidate()
        timer = nil
        refreshBlock = nil
    }
}
