import AppKit

/// CoolBar 应用图标生成器
/// 所有图标均为模板图（isTemplate=true），自动适配深浅色模式
enum AppIcon {

    /// 菜单栏图标（18x18, 单色模板）
    /// 设计：圆角方块内含 3 条不等高竖线，暗示系统活动监控
    static func menuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        // 圆角外框
        let frameRect = NSRect(x: 1.5, y: 1.5, width: 15, height: 15)
        let framePath = NSBezierPath(roundedRect: frameRect, xRadius: 3.5, yRadius: 3.5)
        framePath.lineWidth = 1.4
        NSColor.labelColor.setStroke()
        framePath.stroke()

        // 内部活动指示线（3 条竖线，中间高两边低）
        let barWidth: CGFloat = 2.2
        let spacing: CGFloat = 2.0
        let totalBarsWidth = barWidth * 3 + spacing * 2
        let startX = (size.width - totalBarsWidth) / 2
        let heights: [CGFloat] = [4, 8, 5]

        for (i, h) in heights.enumerated() {
            let x = startX + CGFloat(i) * (barWidth + spacing)
            let y = (size.height - h) / 2
            let barRect = NSRect(x: x, y: y, width: barWidth, height: h)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
            NSColor.labelColor.setFill()
            barPath.fill()
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    /// App 图标（用于 Dock / 关于窗口，1024x1024）
    /// 简约风格：深色圆角方块 + 白色活动线条
    static func appIcon() -> NSImage {
        let size = NSSize(width: 1024, height: 1024)
        let image = NSImage(size: size)
        image.lockFocus()

        // 背景：圆角方块，深蓝灰渐变
        let bgRect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 224, yRadius: 224)

        // 渐变背景
        let gradient = NSGradient(
            colors: [
                NSColor(srgbRed: 0.20, green: 0.24, blue: 0.32, alpha: 1.0),
                NSColor(srgbRed: 0.10, green: 0.13, blue: 0.18, alpha: 1.0)
            ]
        )
        gradient?.draw(in: bgPath, angle: -90)

        // 内部白色活动线条（放大版菜单栏图标）
        let barWidth: CGFloat = 120
        let spacing: CGFloat = 100
        let heights: [CGFloat] = [240, 440, 280]
        let totalWidth = barWidth * 3 + spacing * 2
        let startX = (1024 - totalWidth) / 2

        for (i, h) in heights.enumerated() {
            let x = startX + CGFloat(i) * (barWidth + spacing)
            let y = (1024 - h) / 2
            let barRect = NSRect(x: x, y: y, width: barWidth, height: h)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 30, yRadius: 30)
            NSColor.white.setFill()
            barPath.fill()
        }

        image.unlockFocus()
        return image
    }
}
