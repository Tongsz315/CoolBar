import Foundation
import ServiceManagement

/// 开机启动辅助工具（使用 macOS 13+ SMAppService API）
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("启动项设置失败: \(error.localizedDescription)")
            }
        }
    }
}
