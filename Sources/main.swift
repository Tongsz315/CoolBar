import AppKit

/// CoolBar 入口 — 传统 AppKit 方式启动
///
/// 注意：NSApplication.delegate 是 unowned(unsafe)，不持有强引用。
/// Release 构建的 ARC 优化会在局部变量最后一次使用后立即释放它。
/// 必须用 withExtendedLifetime 确保 delegate 在整个事件循环期间存活，
/// 否则 applicationDidFinishLaunching 永远不会被调用。

let application = NSApplication.shared
application.setActivationPolicy(.accessory)

let delegate = AppDelegate()
application.delegate = delegate

// 关键：保持 delegate 存活直到事件循环结束
withExtendedLifetime(delegate) {
    application.run()
}
