import SwiftUI

// MARK: - Dashboard View (Stats-style)

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            Divider().padding(.horizontal, 12)

            // Monitor cards
            ScrollView {
                VStack(spacing: 10) {
                    cpuCard
                    memoryCard
                    networkCard
                    batteryCard
                }
                .padding(12)
            }
        }
        .frame(width: 300)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

// MARK: - Header

private extension DashboardView {
    var headerSection: some View {
        HStack {
            Image(nsImage: AppIcon.menuBarIcon())
                .resizable()
                .frame(width: 20, height: 20)
            Text("CoolBar")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(viewModel.timeString)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - CPU Card

private extension DashboardView {
    var cpuCard: some View {
        MonitorCard(title: "CPU", icon: "cpu", accent: .blue) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.cpuPercent)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text("使用率")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // CPU 迷你条形图
                MiniBarChart(data: viewModel.cpuHistory, color: .blue)
                    .frame(width: 120, height: 44)
            }
            // 详情行
            HStack(spacing: 16) {
                detailRow("系统", viewModel.cpuSystem)
                detailRow("用户", viewModel.cpuUser)
                detailRow("空闲", viewModel.cpuIdle)
                detailRow("核心", viewModel.cpuCores)
            }
        }
    }
}

// MARK: - Memory Card

private extension DashboardView {
    var memoryCard: some View {
        MonitorCard(title: "内存", icon: "memorychip", accent: .green) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.memPercent)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text("已用内存")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                MiniBarChart(data: viewModel.memHistory, color: .green)
                    .frame(width: 120, height: 44)
            }
            HStack(spacing: 16) {
                detailRow("已用", viewModel.memUsed)
                detailRow("总量", viewModel.memTotal)
                detailRow("压力", viewModel.memPressure)
            }
        }
    }
}

// MARK: - Network Card

private extension DashboardView {
    var networkCard: some View {
        MonitorCard(title: "网络", icon: "network", accent: .orange) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.netDownload)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    Label("下载", systemImage: "arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.netUpload)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    Label("上传", systemImage: "arrow.up")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // 网络速率迷你图
                MiniBarChart(data: viewModel.netHistory, color: .orange)
                    .frame(width: 100, height: 36)
            }
            detailRow("接口", "en0 (Wi-Fi)")
        }
    }
}

// MARK: - Battery Card

private extension DashboardView {
    var batteryCard: some View {
        MonitorCard(title: "电池", icon: "battery.100", accent: .yellow) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.batteryPercent)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                        Image(systemName: viewModel.batteryIcon)
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.batteryColor)
                    }
                    Text(viewModel.batteryState)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // 电量进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(viewModel.batteryColor)
                            .frame(width: geo.size.width * viewModel.batteryFraction, height: 6)
                            .animation(.easeInOut(duration: 1), value: viewModel.batteryFraction)
                    }
                }
                .frame(width: 120, height: 6)
                .offset(y: -8)
            }
            HStack(spacing: 16) {
                detailRow("剩余", viewModel.batteryTime)
                detailRow("健康度", viewModel.batteryHealth)
                detailRow("循环", viewModel.batteryCycles)
            }
        }
    }
}

// MARK: - Helper Views

/// 监控卡片容器
private struct MonitorCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.06))
        )
    }
}

/// 详情行
private func detailRow(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 1) {
        Text(value)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
        Text(label)
            .font(.system(size: 9))
            .foregroundColor(.secondary)
    }
}

// MARK: - Mini Bar Chart

struct MiniBarChart: View {
    let data: [Double]
    let color: Color
    let maxBars: Int = 20

    var body: some View {
        let points = data.suffix(maxBars)
        let maxVal = max(points.max() ?? 1, 1)

        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 1.5) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, value in
                    let h = max(CGFloat(value / maxVal) * geo.size.height, 2)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color.opacity(0.7))
                        .frame(width: (geo.size.width - CGFloat(points.count - 1) * 1.5) / CGFloat(points.count), height: h)
                }
            }
        }
    }
}

// MARK: - Blurred Background (for HUD look)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
