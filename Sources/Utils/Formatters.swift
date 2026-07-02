import Foundation

enum Formatters {
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    /// 通用字节速率格式化
    static func speed(_ bytesPerSec: Double, unitSuffix: String = "/s") -> String {
        let a = abs(bytesPerSec)
        if a < 1024 {
            return "0 KB\(unitSuffix)"
        } else if a < 1_048_576 {
            return String(format: "%.0f KB\(unitSuffix)", a / 1024)
        } else {
            return String(format: "%.1f MB\(unitSuffix)", a / 1_048_576)
        }
    }

    /// 磁盘简洁格式（无 /s 后缀）
    static func diskSpeed(_ bytesPerSec: Double) -> String {
        let a = abs(bytesPerSec)
        if a < 1024 { return "0" }
        if a < 1_048_576 { return String(format: "%.0fK", a / 1024) }
        return String(format: "%.1fM", a / 1_048_576)
    }
}
