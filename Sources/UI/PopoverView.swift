import SwiftUI

/// 点击菜单栏图标时的弹出详情面板
struct PopoverView: View {
    let title: String
    let displayText: String
    let details: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(displayText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // 详情列表
            VStack(spacing: 0) {
                ForEach(details.indices, id: \.self) { index in
                    let (label, value) = details[index]
                    HStack {
                        Text(label)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if index < details.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }

            Spacer()

            // 底部操作
            Divider()
            HStack {
                Spacer()
                if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.batterypower") {
                    Button("系统设置...") {
                        NSWorkspace.shared.open(settingsURL)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 280, height: 200)
    }
}

#Preview {
    PopoverView(
        title: "CPU",
        displayText: "CPU 23%",
        details: [
            ("使用率", "23.5%"),
            ("核心数", "8 核"),
            ("架构", "Apple Silicon")
        ]
    )
}
