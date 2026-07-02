import Foundation

// MARK: - Double Extensions

extension Double {
    /// 格式化为易读的字节速度
    var bytesPerSecondFormatted: String {
        switch self {
        case 0..<1024:
            return "0 B/s"
        case 1024..<1_048_576:
            return String(format: "%.0f KB/s", self / 1024)
        case 1_048_576..<1_073_741_824:
            return String(format: "%.1f MB/s", self / 1_048_576)
        default:
            return String(format: "%.2f GB/s", self / 1_073_741_824)
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == Double {
    /// 计算数组的平均值
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    /// 获取最大值，空数组返回 0
    var safeMax: Double {
        self.max() ?? 0
    }
}

// MARK: - String Extensions

extension String {
    /// 截断到指定长度，超出部分用 ... 代替
    func truncated(to length: Int) -> String {
        count > length ? String(prefix(length)) + "..." : self
    }
}
