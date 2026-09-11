import Foundation
import IOKit
import IOKit.hid

public class LidAngleSensor {
    public static let shared = LidAngleSensor()
    
    public var onAngleUpdate: ((Double) -> Void)?
    public var onSensorStatusChanged: ((Bool, String) -> Void)?
    
    private var manager: IOHIDManager?
    private var targetDevice: IOHIDDevice?
    private var timer: Timer?
    private var inputBuffer = [UInt8](repeating: 0, count: 64)
    
    public private(set) var isConnected: Bool = false
    public private(set) var currentAngle: Double = 112.0 // Default open angle
    
    private init() {}
    
    public func startMonitoring() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else {
            onSensorStatusChanged?(false, "Failed to create IOHIDManager")
            return
        }
        
        // Exact hardware matching for Apple Lid Angle Sensor (VID 0x05AC, PID 0x8104, Usage 0x008A)
        let matchingCriteria: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDPrimaryUsagePageKey: 0x0020,
            kIOHIDPrimaryUsageKey: 0x008A
        ]
        
        IOHIDManagerSetDeviceMatching(manager, matchingCriteria as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, let device = devices.first else {
            searchFallbackDevices(manager: manager)
            return
        }
        
        setupDevice(device)
    }
    
    private func searchFallbackDevices(manager: IOHIDManager) {
        let appleMatching: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104
        ]
        IOHIDManagerSetDeviceMatching(manager, appleMatching as CFDictionary)
        
        if let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
            for dev in devices {
                let page = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int) ?? 0
                let usage = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? Int) ?? 0
                if page == 0x0020 && usage == 0x008A {
                    setupDevice(dev)
                    return
                }
            }
        }
        
        onSensorStatusChanged?(false, "Hardware Sensor Not Found (Mock Mode)")
    }
    
    private func setupDevice(_ device: IOHIDDevice) {
        self.targetDevice = device
        self.isConnected = true
        onSensorStatusChanged?(true, "Hardware Lid Sensor Active (PID 0x8104)")
        
        // Schedule with RunLoop
        if let manager = manager {
            IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        }
        
        // Register Input Report Callback for Report ID 1
        IOHIDDeviceRegisterInputReportCallback(
            device,
            &inputBuffer,
            inputBuffer.count,
            { (context, result, sender, type, reportID, report, reportLength) in
                guard let context = context, result == kIOReturnSuccess, reportLength >= 3 else { return }
                let sensor = Unmanaged<LidAngleSensor>.fromOpaque(context).takeUnretainedValue()
                sensor.parseReport(report, length: reportLength)
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        // High frequency poll timer (50ms) for ultra-smooth angle telemetry
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.pollReport()
        }
    }
    
    private func parseReport(_ reportPtr: UnsafeMutablePointer<UInt8>, length: Int) {
        guard length >= 3 else { return }
        let rawAngle = UInt16(reportPtr[1]) | (UInt16(reportPtr[2]) << 8)
        let angle = Double(rawAngle)
        if angle >= 0.0 && angle <= 180.0 {
            updateAngle(angle)
        }
    }
    
    private func pollReport() {
        guard let device = targetDevice else { return }
        var report = [UInt8](repeating: 0, count: 16)
        var reportLength = report.count
        
        // Query Feature Report ID 1 from Apple Lid Angle Sensor
        let result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            1,
            &report,
            &reportLength
        )
        
        if result == kIOReturnSuccess && reportLength >= 3 {
            let rawAngle = UInt16(report[1]) | (UInt16(report[2]) << 8)
            let angle = Double(rawAngle)
            if angle >= 0.0 && angle <= 180.0 {
                updateAngle(angle)
            }
        }
    }
    
    public func updateAngle(_ newAngle: Double) {
        let clamped = max(0.0, min(180.0, newAngle))
        // Only trigger update if angle changed or initial call
        if abs(clamped - self.currentAngle) >= 0.1 || self.currentAngle < 0 {
            self.currentAngle = clamped
            DispatchQueue.main.async {
                self.onAngleUpdate?(clamped)
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let manager = manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        isConnected = false
    }
}
