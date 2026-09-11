import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: BlurOverlayWindow!
    private var controlPanel: ControlPanelWindow!
    private var statusItem: NSStatusItem!
    
    private var isHardwareEnabled = true
    private var isSkewEnabled = true
    private var skewIntensity = 1.0
    private var blurStartAngle = 90.0
    private var blurFullAngle = 20.0
    private var currentAngle = 112.0
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request macOS System Permissions if needed
        PermissionsManager.checkAndRequestPermissions()
        
        // Create full screen overlay window
        overlayWindow = BlurOverlayWindow()
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()
        
        // Create floating control panel
        controlPanel = ControlPanelWindow()
        controlPanel.center()
        controlPanel.makeKeyAndOrderFront(nil)
        
        // Setup Menu Bar Status Item
        setupStatusBar()
        
        // Control panel callbacks
        controlPanel.onHardwareToggleChanged = { [weak self] enabled in
            self?.isHardwareEnabled = enabled
            if !enabled {
                self?.recalculateProgress()
            }
        }
        
        controlPanel.onSkewSettingsChanged = { [weak self] enabled, intensity in
            self?.isSkewEnabled = enabled
            self?.skewIntensity = intensity
            self?.recalculateProgress()
        }
        
        controlPanel.onAnimationStylesChanged = { [weak self] in
            self?.recalculateProgress()
        }
        
        controlPanel.onManualAngleChanged = { [weak self] angle in
            guard let self = self, !self.isHardwareEnabled else { return }
            self.currentAngle = angle
            self.recalculateProgress()
        }
        
        controlPanel.onThresholdsChanged = { [weak self] start, full in
            guard let self = self else { return }
            self.blurStartAngle = start
            self.blurFullAngle = full
            self.recalculateProgress()
        }
        
        // Lid sensor callbacks
        LidAngleSensor.shared.onSensorStatusChanged = { [weak self] connected, message in
            self?.controlPanel.updateSensorStatus(connected: connected, message: message)
        }
        
        LidAngleSensor.shared.onAngleUpdate = { [weak self] angle in
            guard let self = self, self.isHardwareEnabled else { return }
            self.currentAngle = angle
            self.recalculateProgress()
        }
        
        // Start live sensor monitoring
        LidAngleSensor.shared.startMonitoring()
    }
    
    private func recalculateProgress() {
        let span = max(1.0, blurStartAngle - blurFullAngle)
        let progress = (blurStartAngle - currentAngle) / span
        let clampedProgress = CGFloat(max(0.0, min(1.0, progress)))
        
        overlayWindow.setBlurAndSkewProgress(
            clampedProgress,
            skewIntensity: CGFloat(controlPanel.skewIntensity),
            skewAngleMax: CGFloat(controlPanel.skewAngleMax),
            blurIntensity: CGFloat(controlPanel.blurIntensity),
            isSkewEnabled: controlPanel.isSkewEnabled,
            blurMaterialStyle: controlPanel.blurMaterialStyle,
            blurDirection: controlPanel.blurDirection,
            skewTransformMode: controlPanel.skewTransformMode,
            skewPivotPoint: controlPanel.skewPivotPoint
        )
        controlPanel.updateTelemetry(angle: currentAngle, progress: Double(clampedProgress))
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "📐 LidBlur"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Controller", action: #selector(showController), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Open System Settings", action: #selector(openSettings), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Lid Blur App", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func showController() {
        controlPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openSettings() {
        PermissionsManager.openSystemSettings()
    }
    
    @objc private func quitApp() {
        LidAngleSensor.shared.stopMonitoring()
        NSApp.terminate(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Application Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
