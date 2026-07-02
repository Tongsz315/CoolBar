import SwiftUI
import ServiceManagement

/// 通用设置
struct GeneralTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("refreshInterval") private var refreshInterval = 1.0

    var body: some View {
        Form {
            Section {
                Toggle("登录时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        do {
                            if launchAtLogin {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("开机启动设置失败: \(error)")
                        }
                    }
            } header: {
                Text("启动")
            }

            Section {
                Picker("刷新间隔", selection: $refreshInterval) {
                    Text("0.5 秒").tag(0.5)
                    Text("1 秒").tag(1.0)
                    Text("2 秒").tag(2.0)
                    Text("5 秒").tag(5.0)
                }
                .pickerStyle(.radioGroup)

                Text("更短的刷新间隔会增加 CPU 占用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("性能")
            }

            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("平台")
                    Spacer()
                    Text("Apple Silicon (ARM64)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralTab()
}
