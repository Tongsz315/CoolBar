import Foundation
import IOBluetooth

/// 蓝牙设备电池监控
/// 读取已连接蓝牙设备的电池电量
final class BluetoothMonitor: MonitorProtocol {
    let id = "bluetooth"
    let title = "BT"
    let refreshInterval: TimeInterval = 5.0
    var isEnabled = false   // 默认禁用，需用户授权蓝牙后启用

    private(set) var displayText = "BT --"
    private var devices: [(name: String, battery: Int)] = []

    func start() {
        displayText = "BT --"
        devices = []
    }

    func stop() {}

    func refresh() { _ = update() }

    func update() -> [(name: String, battery: Int)] {
        var result: [(String, Int)] = []
        if let pairedDevices = IOBluetoothDevice.pairedDevices() {
            for case let device as IOBluetoothDevice in pairedDevices {
                if device.isConnected() {
                    let name = device.nameOrAddress ?? "未知设备"
                    // 尝试获取电池信息
                    let battery = deviceBatteryLevel(device) ?? -1
                    if battery >= 0 {
                        result.append((name, battery))
                    }
                }
            }
        }

        devices = result

        if result.isEmpty {
            displayText = "BT --"
        } else if let first = result.first {
            displayText = String(format: "BT %d%%", first.1)
        }

        return result
    }

    func detailedInfo() -> [(String, String)] {
        let _ = update()
        if devices.isEmpty {
            return [("状态", "无已连接设备")]
        }
        return devices.map { ($0.name, "\($0.battery)%") }
    }

    /// 尝试通过 IOKit 获取蓝牙设备电池电量
    private func deviceBatteryLevel(_ device: IOBluetoothDevice) -> Int? {
        // 尝试从设备描述符中读取电池信息
        // IOBluetoothDevice 不直接暴露电池 API
        // 通过 IORegistry 读取
        guard device.addressString != nil else { return nil }

        // 遍历 IORegistry 查找 AppleBluetoothHIDKeyboard / Headphones
        var iterator: io_iterator_t = 0
        guard let match = IOServiceMatching("IOHIDDevice") else { return nil }
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator)
        guard result == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }

            if let batteryProps = IORegistryEntryCreateCFProperty(
                service, "BatteryPercent" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? Int {
                return batteryProps
            }

            // 尝试其他电池属性键
            let keys = ["Battery", "BatteryLevel", "BatteryStatus"]
            for key in keys {
                if let val = IORegistryEntryCreateCFProperty(
                    service, key as CFString, kCFAllocatorDefault, 0
                )?.takeRetainedValue() as? Int, val >= 0 {
                    return val
                }
            }
        }

        return nil
    }
}
