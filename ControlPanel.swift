import Cocoa
import SwiftUI

public class ControlPanelState: ObservableObject {
    // Telemetry & Hardware
    @Published public var currentAngle: Double = 112.0
    @Published public var blurProgress: Double = 0.0
    @Published public var sensorStatus: String = "Connecting..."
    @Published public var isHardwareConnected: Bool = true
    @Published public var isHardwareEnabled: Bool = true
    @Published public var manualAngle: Double = 112.0
    
    // Initial Default Angle Thresholds (80° start, 20° full)
    @Published public var blurStartAngle: Double = 80.0
    @Published public var blurFullAngle: Double = 20.0
    
    // Blur Options
    @Published public var blurMaterialStyle: Int = 0
    @Published public var blurDirection: Int = 0
    @Published public var blurIntensity: Double = 1.0
    
    // Callbacks
    public var onHardwareToggleChanged: ((Bool) -> Void)?
    public var onManualAngleChanged: ((Double) -> Void)?
    public var onThresholdsChanged: ((Double, Double) -> Void)?
    public var onAnimationStylesChanged: (() -> Void)?
    
    public func notifyChanges() {
        onAnimationStylesChanged?()
    }
}

struct ControlPanelView: View {
    @ObservedObject var state: ControlPanelState
    
    var body: some View {
        VStack(spacing: 18) {
            // Header with top clearance below macOS Traffic Light close/minimize buttons
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lid Angle Blur")
                        .font(.system(size: 17, weight: .bold))
                    Text("Screen Lean Privacy Blur")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.isHardwareConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(state.isHardwareConnected ? "Hardware Active" : "Mock Mode")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
            }
            .padding(.top, 38) // Clears window traffic light buttons completely
            
            // Live Telemetry Banner
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LIVE HARDWARE ANGLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f°", state.currentAngle))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("BLUR COVERAGE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f%%", state.blurProgress * 100))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.12)).frame(height: 8)
                        Capsule().fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geo.size.width * CGFloat(state.blurProgress)), height: 8)
                            .animation(.easeOut(duration: 0.1), value: state.blurProgress)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.7)))
            
            // Blur Customization Options Card
            VStack(alignment: .leading, spacing: 14) {
                Text("BLUR CUSTOMIZATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Glass Material Style:")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { state.blurMaterialStyle },
                        set: { val in state.blurMaterialStyle = val; state.notifyChanges() }
                    )) {
                        Text("HUD Dark Glass").tag(0)
                        Text("Ultra Dark").tag(1)
                        Text("Light Popover").tag(2)
                        Text("System FullScreen").tag(3)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                
                HStack {
                    Text("Expansion Direction:")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { state.blurDirection },
                        set: { val in state.blurDirection = val; state.notifyChanges() }
                    )) {
                        Text("Top ↓ Down").tag(0)
                        Text("Bottom ↑ Up").tag(1)
                        Text("Center Outward").tag(2)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Blur Opacity / Intensity:")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(String(format: "%.0f%%", state.blurIntensity * 100))
                            .font(.system(size: 13, weight: .bold))
                    }
                    
                    Slider(value: Binding(
                        get: { state.blurIntensity },
                        set: { val in state.blurIntensity = val; state.notifyChanges() }
                    ), in: 0.2...1.0, step: 0.05)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
            
            // Hardware & Threshold Controls Card
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: Binding(
                    get: { state.isHardwareEnabled },
                    set: { val in
                        state.isHardwareEnabled = val
                        state.onHardwareToggleChanged?(val)
                    }
                )) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.blue)
                        Text("Use Hardware Lid Sensor")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if !state.isHardwareEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Manual Test Angle:")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text(String(format: "%.0f°", state.manualAngle))
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        Slider(value: Binding(
                            get: { state.manualAngle },
                            set: { val in
                                state.manualAngle = val
                                state.onManualAngleChanged?(val)
                            }
                        ), in: 0...135)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("HARDWARE LEAN THRESHOLDS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Blur Starts Below:")
                                .font(.system(size: 13))
                            Spacer()
                            Text(String(format: "%.0f°", state.blurStartAngle))
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        Slider(value: Binding(
                            get: { state.blurStartAngle },
                            set: { val in
                                state.blurStartAngle = val
                                state.onThresholdsChanged?(val, state.blurFullAngle)
                            }
                        ), in: 30...130, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Blur 100% At:")
                                .font(.system(size: 13))
                            Spacer()
                            Text(String(format: "%.0f°", state.blurFullAngle))
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        Slider(value: Binding(
                            get: { state.blurFullAngle },
                            set: { val in
                                state.blurFullAngle = val
                                state.onThresholdsChanged?(state.blurStartAngle, val)
                            }
                        ), in: 0...60, step: 1)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
            
            Spacer(minLength: 8)
            
            // Bottom Action Bar
            HStack {
                Button(action: {
                    PermissionsManager.openSystemSettings()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                        Text("System Settings")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)

                Spacer()
                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("Quit App")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(20)
        .frame(width: 460, height: 600)
    }
}

public class ControlPanelWindow: NSWindow {
    public let state = ControlPanelState()
    
    public var onManualAngleChanged: ((Double) -> Void)? {
        get { state.onManualAngleChanged }
        set { state.onManualAngleChanged = newValue }
    }
    
    public var onHardwareToggleChanged: ((Bool) -> Void)? {
        get { state.onHardwareToggleChanged }
        set { state.onHardwareToggleChanged = newValue }
    }
    
    public var onThresholdsChanged: ((Double, Double) -> Void)? {
        get { state.onThresholdsChanged }
        set { state.onThresholdsChanged = newValue }
    }
    
    public var onAnimationStylesChanged: (() -> Void)? {
        get { state.onAnimationStylesChanged }
        set { state.onAnimationStylesChanged = newValue }
    }
    
    public init() {
        let panelRect = NSRect(x: 0, y: 0, width: 460, height: 600)
        super.init(
            contentRect: panelRect,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.title = "Lid Angle Blur"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.level = .floating
        self.isReleasedWhenClosed = false
        self.isMovableByWindowBackground = true
        
        let hostingView = NSHostingView(rootView: ControlPanelView(state: state))
        
        let visualEffectView = NSVisualEffectView(frame: panelRect)
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        
        hostingView.frame = visualEffectView.bounds
        hostingView.autoresizingMask = [.width, .height]
        visualEffectView.addSubview(hostingView)
        
        self.contentView = visualEffectView
    }
    
    public func updateSensorStatus(connected: Bool, message: String) {
        state.isHardwareConnected = connected
        state.sensorStatus = message
        if !connected {
            state.isHardwareEnabled = false
        }
    }
    
    public func updateTelemetry(angle: Double, progress: Double) {
        state.currentAngle = angle
        state.blurProgress = progress
        if !state.isHardwareEnabled {
            state.manualAngle = angle
        }
    }
    
    public var blurStartAngle: Double { return state.blurStartAngle }
    public var blurFullAngle: Double { return state.blurFullAngle }
    public var blurIntensity: Double { return state.blurIntensity }
    public var blurMaterialStyle: Int { return state.blurMaterialStyle }
    public var blurDirection: Int { return state.blurDirection }
}
