import Foundation

/// 监控模块协议 — 所有系统监控模块必须遵循
protocol MonitorProtocol: AnyObject {
    /// 模块唯一标识
    var id: String { get }
    /// 菜单栏显示名称（如 "CPU"、"MEM"）
    var title: String { get }
    /// 当前显示的文本
    var displayText: String { get }
    /// 刷新间隔（秒）
    var refreshInterval: TimeInterval { get }
    /// 模块是否启用
    var isEnabled: Bool { get set }

    /// 启动监控
    func start()
    /// 停止监控
    func stop()
    /// 触发一次数据刷新（更新 displayText）
    func refresh()
    /// 获取详细数据（供 Popover 展示）
    func detailedInfo() -> [(String, String)]
}
