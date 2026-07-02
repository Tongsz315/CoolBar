import SwiftUI

// MARK: - Overview Page

struct OverviewPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Summary cards row
            HStack(spacing: 8) {
                summaryCard(title: "CPU", value: vm.cpuPercent, color: .blue, icon: "cpu.fill")
                summaryCard(title: "内存", value: vm.memPercent, color: .green, icon: "memorychip.fill")
                summaryCard(title: "电池", value: vm.batteryPercent, color: .yellow, icon: "battery.100")
                summaryCard(title: "网络", value: vm.netDownload, color: .orange, icon: "network")
            }

            // CPU mini chart
            StatCard {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "cpu.fill").foregroundColor(.blue)
                        Text("CPU 使用率").font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(vm.cpuPercent).font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    AreaChart(data: vm.cpuHistory, color: .blue)
                        .frame(height: 80)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func summaryCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - CPU Page

struct CPUPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Main ring + stats
            StatCard {
                HStack(alignment: .center, spacing: 20) {
                    RingChart(fraction: vm.cpuFraction, text: vm.cpuPercent,
                              colors: [.blue])
                    VStack(alignment: .leading, spacing: 6) {
                        statRow("系统", value: vm.cpuSystem)
                        statRow("用户", value: vm.cpuUser)
                        statRow("空闲", value: vm.cpuIdle)
                        statRow("核心", value: vm.cpuCores)
                    }
                    Spacer(minLength: 0)
                }
            }

            // History chart
            StatCard {
                VStack(alignment: .leading) {
                    HStack {
                        Text("使用率历史")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(vm.cpuPercent)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    AreaChart(data: vm.cpuHistory, color: .blue)
                        .frame(height: 110)
                }
            }
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium, design: .monospaced))
        }
    }
}

// MARK: - Memory Page (Stats-style with ring + segmented bar)

struct MemoryPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Main ring + segmented bar
            StatCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 18) {
                        RingChart(fraction: vm.memFraction, text: vm.memPercent,
                                  colors: [.blue, .orange, .red])

                        VStack(alignment: .leading) {
                            HStack {
                                Text("已用:")
                                Spacer()
                                Text(vm.memUsed)
                                    .fontWeight(.medium)
                                Text(vm.memTotal)
                                    .foregroundColor(.secondary)
                            }
                            .font(.system(size: 12))

                            SegmentedBar(segments: [
                                .init(color: .blue, label: "App 内存", value: CGFloat(vm.memAppGB)),
                                .init(color: .orange, label: "联动内存", value: CGFloat(vm.memWiredGB)),
                                .init(color: .red, label: "被压缩", value: CGFloat(vm.memCompressedGB)),
                                .init(color: .gray.opacity(0.5), label: "可用", value: CGFloat(vm.memFreeGB)),
                            ])
                        }
                    }

                    // History
                    AreaChart(data: vm.memHistory, color: .green)
                        .frame(height: 90)
                }
            }

            // Bottom: Pressure gauge + Swap
            HStack(spacing: 10) {
                StatCard {
                    VStack {
                        Text("内存压力")
                            .font(.system(size: 12, weight: .semibold))
                        SemiGauge(fraction: vm.memPressureFraction,
                                  labelText: vm.memPressureLabel,
                                  subText: nil)
                            .padding(.vertical, 2)
                        Text(vmTime())
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                StatCard {
                    VStack {
                        Text("交换区")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer(minLength: 4)
                        Text("未使用")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        Spacer(minLength: 4)
                        Text(vmTime())
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
    }

    private func vmTime() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: Date())
    }
}

// MARK: - Network Page

struct NetworkPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Speed display
            StatCard {
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        Text(vm.netDownload)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                        Text("下载速度")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        Text(vm.netUpload)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                        Text("上传速度")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    // Total ring
                    RingChart(fraction: min(CGFloat(Double(vm.netSpeedValue()) / 1_000_000), 1),
                              text: vm.netDownload,
                              colors: [.orange])
                }
            }

            // Network history
            StatCard {
                VStack(alignment: .leading) {
                    Text("网络速率")
                        .font(.system(size: 13, weight: .semibold))
                    AreaChart(data: vm.netHistory, color: .orange)
                        .frame(height: 110)
                }
            }
        }
    }
}

// MARK: - Battery Page

struct BatteryPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Main battery info
            StatCard {
                HStack(alignment: .center, spacing: 18) {
                    // Big ring
                    RingChart(fraction: vm.batteryFraction,
                              text: "\(Int(vm.batteryFraction * 100))%",
                              colors: [vm.batteryColor])

                    VStack(alignment: .leading, spacing: 7) {
                        HStack { Text("状态"); Spacer(); Text(vm.batteryState) }
                            .font(.system(size: 12))
                        HStack { Text("剩余时间"); Spacer(); Text(vm.batteryTime) }
                            .font(.system(size: 12))
                        HStack { Text("健康度"); Spacer(); Text(vm.batteryHealth) }
                            .font(.system(size: 12))
                        HStack { Text("循环次数"); Spacer(); Text(vm.batteryCycles) }
                            .font(.system(size: 12))
                    }
                    Spacer()
                }
            }

            // Bottom stats
            HStack(spacing: 10) {
                StatCard {
                    VStack(spacing: 3) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.yellow)
                        Text(vm.batteryState == "充电中" ? "充电" : "放电")
                            .font(.system(size: 12))
                        Text(vmTime())
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                StatCard {
                    VStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                        Text(vm.batteryTime)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        Text(vmTime())
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                StatCard {
                    VStack(spacing: 3) {
                        Text("\(vm.batteryHealth)")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                        Text("健康度")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(vmTime())
                            .font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
    }

    private func vmTime() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
    }
}
