import SwiftUI

/// 监控模块开关设置
struct MonitorsTab: View {
    @AppStorage("monitorCPU") private var monitorCPU = true
    @AppStorage("monitorMemory") private var monitorMemory = true
    @AppStorage("monitorNetwork") private var monitorNetwork = true
    @AppStorage("monitorBattery") private var monitorBattery = true

    var body: some View {
        Form {
            Section {
                Toggle("CPU 使用率", isOn: $monitorCPU)
                Toggle("内存使用率", isOn: $monitorMemory)
                Toggle("网络速率", isOn: $monitorNetwork)
                Toggle("电池状态", isOn: $monitorBattery)
            } header: {
                Text("菜单栏显示")
            } footer: {
                Text("关闭某个模块后，其图标将从菜单栏移除")
            }

            Spacer()
        }
        .formStyle(.grouped)
        .padding()
    }
}

/// 菜单栏管理设置
struct BarManagerTab: View {
    @AppStorage("overflowEnabled") private var overflowEnabled = true
    @AppStorage("autoHideAfter") private var autoHideAfter = 0

    var body: some View {
        Form {
            Section {
                Toggle("启用溢出折叠", isOn: $overflowEnabled)
            } header: {
                Text("溢出管理")
            } footer: {
                Text("开启后，CoolBar 会在菜单栏显示 ... 图标，点击可查看隐藏的图标")
            }

            Section {
                Picker("自动隐藏", selection: $autoHideAfter) {
                    Text("关闭").tag(0)
                    Text("10 秒后").tag(10)
                    Text("30 秒后").tag(30)
                    Text("1 分钟后").tag(60)
                }
                .disabled(!overflowEnabled)
            } header: {
                Text("自动隐藏")
            } footer: {
                Text("隐藏的图标将在鼠标移开后自动收起")
            }

            Spacer()
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    MonitorsTab()
}
