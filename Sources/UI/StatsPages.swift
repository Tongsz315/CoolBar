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
        Formatters.shortTimeFormatter.string(from: Date())
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

                    // Ring
                    RingChart(fraction: 0.5,
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
        Formatters.timeFormatter.string(from: Date())
    }
}

// MARK: - GPU Page

struct GPUPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            StatCard {
                HStack(alignment: .center, spacing: 20) {
                    RingChart(fraction: vm.gpuFraction, text: vm.gpuPercent, colors: [.purple])
                    VStack(alignment: .leading, spacing: 6) {
                        statRow("使用率", value: vm.gpuPercent)
                        statRow("架构", value: vm.gpuName)
                    }
                    Spacer()
                }
            }
            StatCard {
                VStack(alignment: .leading) {
                    HStack {
                        Text("GPU 历史").font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(vm.gpuPercent).font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    AreaChart(data: vm.gpuHistory, color: .purple).frame(height: 120)
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

// MARK: - Disk Page

struct DiskPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            StatCard {
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc.fill").font(.system(size: 24)).foregroundColor(.blue)
                        Text(vm.diskRead).font(.system(size: 22, weight: .bold, design: .monospaced))
                        Text("读取").font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.doc.fill").font(.system(size: 24)).foregroundColor(.orange)
                        Text(vm.diskWrite).font(.system(size: 22, weight: .bold, design: .monospaced))
                        Text("写入").font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            StatCard {
                VStack(alignment: .leading) {
                    Text("读取历史").font(.system(size: 13, weight: .semibold))
                    AreaChart(data: vm.diskHistory, color: .blue).frame(height: 70)
                }
            }
            StatCard {
                VStack(alignment: .leading) {
                    Text("写入历史").font(.system(size: 13, weight: .semibold))
                    AreaChart(data: vm.diskWriteHistory, color: .orange).frame(height: 70)
                }
            }
        }
    }
}

// MARK: - Bluetooth Page

struct BluetoothPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            StatCard {
                if vm.btDevices.isEmpty {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 20)).foregroundColor(.secondary)
                        Text("无已连接的蓝牙设备").font(.system(size: 13)).foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 6) {
                        ForEach(vm.btDevices.indices, id: \.self) { i in
                            let d = vm.btDevices[i]
                            HStack {
                                Image(systemName: "headphones").foregroundColor(.blue)
                                Text(d.name).font(.system(size: 13))
                                Spacer()
                                Text("\(d.battery)%")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(d.battery > 20 ? .green : .red)
                                // Battery bar
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.secondary.opacity(0.2)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(d.battery > 20 ? Color.green : Color.red)
                                        .frame(width: geo.size.width * CGFloat(d.battery) / 100, height: 6)
                                }
                                .frame(width: 60, height: 6)
                            }
                        }
                    }
                }
            }
            Text("需要设备主动上报电池信息\n（AirPods、Magic Mouse 等）")
                .font(.system(size: 10)).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}

// MARK: - Clock Page

struct ClockPage: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 10) {
            StatCard {
                VStack(spacing: 8) {
                    Text(vm.clockTime)
                        .font(.system(size: 48, weight: .thin, design: .default))
                    Text(vm.clockFull)
                        .font(.system(size: 13)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            StatCard {
                VStack(spacing: 6) {
                    HStack { Text("时区"); Spacer(); Text(vm.clockTz) }.font(.system(size: 12))
                }
            }
        }
    }
}
