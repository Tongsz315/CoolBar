import Foundation
import IOBluetooth
import IOKit

/// 蓝牙设备电池监控
/// 默认禁用，启用后需用户在系统设置中授权蓝牙权限
final class BluetoothMonitor: MonitorProtocol {
    let id = "bluetooth"
    let refreshInterval: TimeInterval = 5.0
    var isEnabled = false

    private(set) var displayText = "BT --"
    private(set) var devices: [(name: String, battery: Int)] = []

    private let lock = NSLock()

    func start() {
        lock.withLock {
            displayText = "BT --"
            devices = []
        }
    }

    func stop() {}

    func update() {
        guard isEnabled else {
            lock.withLock { displayText = "BT --" }
            return
        }

        var result: [(String, Int)] = []
        if let pairedDevices = IOBluetoothDevice.pairedDevices() {
            for case let device as IOBluetoothDevice in pairedDevices {
                if device.isConnected() {
                    let name = device.nameOrAddress ?? "未知设备"
                    if let battery = deviceBatteryLevel(device), battery >= 0 {
                        result.append((name, battery))
                    }
                }
            }
        }

        lock.withLock {
            devices = result
            if result.isEmpty {
                displayText = "BT --"
            } else if let first = result.first {
                displayText = String(format: "BT %d%%", first.1)
            }
        }
    }

    func detailedInfo() -> [(String, String)] {
        lock.withLock {
            if devices.isEmpty {
                return [("状态", "无已连接设备")]
            }
            return devices.map { ($0.name, "\($0.battery)%") }
        }
    }

    private func deviceBatteryLevel(_ device: IOBluetoothDevice) -> Int? {
        guard device.addressString != nil else { return nil }

        var iterator: io_iterator_t = 0
        guard let match = IOServiceMatching("IOHIDDevice") else { return nil }
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator)
        guard result == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }

            if let batteryProps = IORegistryEntryCreateCFProperty(service, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                return batteryProps
            }

            let keys = ["Battery", "BatteryLevel", "BatteryStatus"]
            for key in keys {
                if let val = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int, val >= 0 {
                    return val
                }
            }
        }

        return nil
    }
}
