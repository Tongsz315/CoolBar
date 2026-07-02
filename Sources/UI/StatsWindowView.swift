import SwiftUI

// MARK: - Sidebar Items

enum DashboardTab: String, CaseIterable {
    case overview = "仪表盘"
    case cpu = "CPU"
    case gpu = "GPU"
    case memory = "内存"
    case disk = "磁盘"
    case network = "网络"
    case battery = "电池"
    case bluetooth = "蓝牙"
    case clock = "时钟"

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .cpu: return "cpu.fill"
        case .gpu: return "display"
        case .memory: return "memorychip.fill"
        case .disk: return "externaldrive.fill"
        case .network: return "network"
        case .battery: return "battery.100"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .clock: return "clock.fill"
        }
    }
}

// MARK: - Main Stats-Style Window

struct StatsWindowView: View {
    @ObservedObject var vm: DashboardViewModel
    let allMonitors: [any MonitorProtocol]
    @State private var selectedTab: DashboardTab = .overview

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            sidebar
                .frame(width: 170)

            Divider().ignoresSafeArea()

            // Right Content
            contentArea
        }
        .frame(width: 540, height: 440)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 5)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation items
            VStack(alignment: .leading, spacing: 1) {
                ForEach(DashboardTab.allCases, id: \.rawValue) { tab in
                    sidebarRow(tab)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Spacer()

            // Bottom toolbar icons
            HStack(spacing: 14) {
                Image(systemName: "gearshape")
                Image(systemName: "heart")
                Image(systemName: "ladybug")
                Image(systemName: "pause.rectangle")
                Image(systemName: "power")
            }
            .font(.system(size: 15))
            .foregroundColor(.secondary)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: NSColor.controlBackgroundColor))
        )
        .padding(6)
    }

    private func sidebarRow(_ tab: DashboardTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab } }) {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                    .frame(width: 16)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6).fill(Color.blue)
                    } else if NSEvent.modifierFlags.contains(.command) {
                        // hover hint
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(selectedTab.rawValue)
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: {}) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
                    .tint(.blue)
                    .toggleStyle(.switch)
                    .scaleEffect(0.85)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 10) {
                switch selectedTab {
                case .overview: OverviewPage(vm: vm)
                case .cpu: CPUPage(vm: vm)
                case .gpu: GPUPage(vm: vm)
                case .memory: MemoryPage(vm: vm)
                case .disk: DiskPage(vm: vm)
                case .network: NetworkPage(vm: vm)
                case .battery: BatteryPage(vm: vm)
                case .bluetooth: BluetoothPage(vm: vm)
                case .clock: ClockPage(vm: vm)
                }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 370)
    }
}

// MARK: - Ring Chart (circular progress)

struct RingChart: View {
    let fraction: CGFloat
    let text: String
    var colors: [Color] = [.blue]
    let lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(colors: colors + [colors[0]], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: fraction)

            Text(text)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Segmented Bar (stacked horizontal bar like Stats memory view)

struct SegmentedBar: View {
    struct Segment {
        let color: Color
        let label: String
        let value: CGFloat
    }
    let segments: [Segment]

    var total: CGFloat {
        segments.map(\.value).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(seg.color.opacity(0.75))
                            .frame(width: total > 0 ? seg.value / total * geo.size.width : 0)
                    }
                }
                .frame(height: 14)
            }
            .frame(height: 14)

            // Legend
            FlowLayout(spacing: 6) {
                ForEach(segments.indices, id: \.self) { i in
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(segments[i].color.opacity(0.75))
                            .frame(width: 8, height: 8)
                            .cornerRadius(2)
                        Text("\(segments[i].label): \(formatBytes(segments[i].value))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func formatBytes(_ val: CGFloat) -> String {
        let v = Int64(val)
        if v < 1024 { return "\(v) B" }
        if v < 1_048_576 { return String(format: "%.1f KB", Double(v)/1024) }
        if v < 1_073_741_824 { return String(format: "%.1f MB", Double(v)/1_048_576) }
        return String(format: "%.2f GB", Double(v)/1_073_741_824)
    }
}

// MARK: - Line Chart (history area chart)

struct AreaChart: View {
    let data: [Double]
    var color: Color = .blue
    let maxBars: Int = 30

    var body: some View {
        let points = data.suffix(maxBars)
        let maxVal = max(points.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 3) {
            // Y axis labels
            HStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach([100, 75, 50, 25, 0], id: \.self) { pct in
                        Text("\(pct)%")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.6))
                            .frame(width: 28, alignment: .trailing)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: 28)

                // Chart
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        // Horizontal grid lines
                        ForEach(1..<5, id: \.self) { i in
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: geo.size.height * CGFloat(i) / 5))
                                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * CGFloat(i) / 5))
                            }
                            .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                        }

                        // Area fill & line
                        if !points.isEmpty {
                            let stepX = geo.size.width / CGFloat(max(points.count - 1, 1))

                            Path { p in
                                p.move(to: CGPoint(x: 0, y: geo.size.height * (1 - CGFloat(points[0]) / maxVal)))
                                for i in 1..<points.count {
                                    p.addLine(to: CGPoint(x: stepX * CGFloat(i),
                                                        y: geo.size.height * (1 - CGFloat(points[i]) / maxVal)))
                                }
                                p.addLine(to: CGPoint(x: stepX * CGFloat(points.count - 1), y: geo.size.height))
                                p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                p.closeSubpath()
                            }
                            .fill(color.opacity(0.12))

                            Path { p in
                                p.move(to: CGPoint(x: 0, y: geo.size.height * (1 - CGFloat(points[0]) / maxVal)))
                                for i in 1..<points.count {
                                    p.addLine(to: CGPoint(x: stepX * CGFloat(i),
                                                        y: geo.size.height * (1 - CGFloat(points[i]) / maxVal)))
                                }
                            }
                            .stroke(color.opacity(0.65), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        }
                    }
                }

                // Time label on right
                Text(vmTime())
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private func vmTime() -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm:ss"; return fmt.string(from: Date())
    }
}

// MARK: - Gauge (semi-circular gauge for pressure)

struct SemiGauge: View {
    let fraction: CGFloat  // 0...1
    let labelText: String
    let subText: String?

    var body: some View {
        ZStack {
            ArcShape(startAngle: .degrees(-210), endAngle: .degrees(30), clockwise: true)
                .stroke(Color.primary.opacity(0.06), style: StrokeStyle(lineWidth: 8, lineCap: .butt))

            ArcShape(startAngle: .degrees(-210), endAngle: .degrees(-210 + 240 * fraction), clockwise: true)
                .stroke(gaugeColor(fraction), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            VStack(spacing: 1) {
                Text(labelText)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                if let s = subText {
                    Text(s)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 110, height: 60)
    }

    private func gaugeColor(_ f: CGFloat) -> Color {
        f < 0.33 ? .green : f < 0.67 ? .orange : .red
    }
}

/// Helper shape for semi-circular arc
struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY + 5),
                    radius: min(rect.width, rect.height) / 2 - 4,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: clockwise)
        return path
    }
}

// MARK: - Card Container

struct StatCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.45))
            )
    }
}

// MARK: - Flow Layout (for legend items)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, item) in result.items.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + y),
                                 proposal: ProposedViewSize(item.size))
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, items: [(x: CGFloat, y: CGFloat, size: CGSize)]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        var items: [(CGFloat, CGFloat, CGSize)] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            items.append((x, y, size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), items)
    }

    private var y: CGFloat { 0 }
}
