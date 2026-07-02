import SwiftUI

/// 设置窗口
struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
            MonitorsTab()
                .tabItem {
                    Label("监控", systemImage: "gauge.with.dots.needle.33percent")
                }
            BarManagerTab()
                .tabItem {
                    Label("菜单栏", systemImage: "menubar.rectangle")
                }
        }
        .frame(width: 450, height: 350)
    }
}

#Preview {
    PreferencesView()
}
