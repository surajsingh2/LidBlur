import Cocoa
import SwiftUI

public class ControlPanelState: ObservableObject {
    @Published public var currentAngle: Double = 112.0
    @Published public var blurProgress: Double = 0.0
    @Published public var sensorStatus: String = "Connecting..."
    @Published public var isHardwareConnected: Bool = true
    @Published public var isHardwareEnabled: Bool = true
    @Published public var isSkewEnabled: Bool = true
    @Published public var skewIntensity: Double = 1.0
    @Published public var manualAngle: Double = 112.0
    @Published public var blurStartAngle: Double = 90.0
    @Published public var blurFullAngle: Double = 20.0
    @Published public var isPermissionGranted: Bool = true
    
    // New Animation Customizations
    @Published public var blurMaterialStyle: Int = 0
    @Published public var blurDirection: Int = 0
    @Published public var skewTransformMode: Int = 0
    @Published public var skewPivotPoint: Int = 0
    
    public var onHardwareToggleChanged: ((Bool) -> Void)?
    public var onManualAngleChanged: ((Double) -> Void)?
    public var onThresholdsChanged: ((Double, Double) -> Void)?
    public var onSkewSettingsChanged: ((Bool, Double) -> Void)?
    public var onAnimationStylesChanged: ((Int, Int, Int, Int) -> Void)?
    
    public func notifyAnimationStylesChanged() {
        onAnimationStylesChanged?(blurMaterialStyle, blurDirection, skewTransformMode, skewPivotPoint)
    }
}

struct ControlPanelView: View {
    @ObservedObject var state: ControlPanelState
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 14) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lid Angle Blur")
                            .font(.system(size: 16, weight: .bold))
                        Text("Screen Lean Privacy & 3D Skew")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(state.isHardwareConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(state.isHardwareConnected ? "Sensor Active" : "Mock Mode")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
                
                Divider()
                
                // Real-Time Telemetry Card
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LIVE HARDWARE ANGLE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.1f", state.currentAngle))
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                Text("°")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("BLUR & 3D SKEW")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.0f%%", state.blurProgress * 100))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Animated Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 7)
                            
                            Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(state.blurProgress), height: 7)
                                .animation(.easeOut(duration: 0.15), value: state.blurProgress)
                        }
                    }
                    .frame(height: 7)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.7)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Blur Style Customizations
                VStack(alignment: .leading, spacing: 10) {
                    Text("BLUR ANIMATION CUSTOMIZATION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blur Material Glass Style:")
                            .font(.system(size: 11, weight: .medium))
                        
                        Picker("", selection: Binding(
                            get: { state.blurMaterialStyle },
                            set: { val in
                                state.blurMaterialStyle = val
                                state.notifyAnimationStylesChanged()
                            }
                        )) {
                            Text("HUD Dark Glass").tag(0)
                            Text("Ultra Dark").tag(1)
                            Text("Light Popover").tag(2)
                            Text("System FullScreen").tag(3)
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Blur Expansion Direction:")
                            .font(.system(size: 11, weight: .medium))
                        
                        Picker("", selection: Binding(
                            get: { state.blurDirection },
                            set: { val in
                                state.blurDirection = val
                                state.notifyAnimationStylesChanged()
                            }
                        )) {
                            Text("Top ↓ Down").tag(0)
                            Text("Bottom ↑ Up").tag(1)
                            Text("Center Outward").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                
                // 3D Skew Customizations
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: Binding(
                        get: { state.isSkewEnabled },
                        set: { val in
                            state.isSkewEnabled = val
                            state.onSkewSettingsChanged?(val, state.skewIntensity)
                        }
                    )) {
                        HStack {
                            Image(systemName: "perspective")
                                .foregroundColor(.purple)
                            Text("3D Perspective Skew Transform")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    
                    if state.isSkewEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3D Skew Transform Mode:")
                                .font(.system(size: 11, weight: .medium))
                            
                            Picker("", selection: Binding(
                                get: { state.skewTransformMode },
                                set: { val in
                                    state.skewTransformMode = val
                                    state.notifyAnimationStylesChanged()
                                }
                            )) {
                                Text("3D Hinge Pitch").tag(0)
                                Text("Trapezoid Pinch").tag(1)
                                Text("Depth Recede").tag(2)
                            }
                            .pickerStyle(.segmented)
                            
                            Text("3D Skew Pivot Point:")
                                .font(.system(size: 11, weight: .medium))
                            
                            Picker("", selection: Binding(
                                get: { state.skewPivotPoint },
                                set: { val in
                                    state.skewPivotPoint = val
                                    state.notifyAnimationStylesChanged()
                                }
                            )) {
                                Text("Top Hinge").tag(0)
                                Text("Center").tag(1)
                                Text("Bottom").tag(2)
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                Text("3D Tilt Intensity:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1fx", state.skewIntensity))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            
                            Slider(value: Binding(
                                get: { state.skewIntensity },
                                set: { val in
                                    state.skewIntensity = val
                                    state.onSkewSettingsChanged?(state.isSkewEnabled, val)
                                }
                            ), in: 0.3...2.0, step: 0.1)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                
                // Sensor & Manual Controls
                VStack(spacing: 10) {
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
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if !state.isHardwareEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Manual Test Angle:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.0f°", state.manualAngle))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            
                            HStack {
                                Image(systemName: "macwindow.on.rectangle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: Binding(
                                    get: { state.manualAngle },
                                    set: { val in
                                        state.manualAngle = val
                                        state.onManualAngleChanged?(val)
                                    }
                                ), in: 0...135)
                                
                                Image(systemName: "laptopcomputer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                
                // Sensitivity Settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("SENSITIVITY THRESHOLDS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 6) {
                        HStack {
                            Text("Blur & Skew Starts Below:")
                                .font(.system(size: 12))
                            Spacer()
                            Text(String(format: "%.0f°", state.blurStartAngle))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        
                        Slider(value: Binding(
                            get: { state.blurStartAngle },
                            set: { val in
                                state.blurStartAngle = val
                                state.onThresholdsChanged?(val, state.blurFullAngle)
                            }
                        ), in: 40...120, step: 1)
                        
                        HStack {
                            Text("Blur & Skew 100% At:")
                                .font(.system(size: 12))
                            Spacer()
                            Text(String(format: "%.0f°", state.blurFullAngle))
                                .font(.system(size: 12, weight: .semibold))
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
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                
                // Bottom Action Bar
                HStack {
                    Button(action: {
                        PermissionsManager.openSystemSettings()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape")
                            Text("System Settings")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderless)

                    Spacer()
                    
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Text("Quit App")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.top, 2)
            }
            .padding(16)
        }
        .frame(width: 380, height: 560)
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
    
    public var onSkewSettingsChanged: ((Bool, Double) -> Void)? {
        get { state.onSkewSettingsChanged }
        set { state.onSkewSettingsChanged = newValue }
    }
    
    public var onAnimationStylesChanged: ((Int, Int, Int, Int) -> Void)? {
        get { state.onAnimationStylesChanged }
        set { state.onAnimationStylesChanged = newValue }
    }
    
    public init() {
        let panelRect = NSRect(x: 0, y: 0, width: 380, height: 560)
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
    
    public var blurStartAngle: Double {
        return state.blurStartAngle
    }
    
    public var blurFullAngle: Double {
        return state.blurFullAngle
    }
    
    public var isSkewEnabled: Bool {
        return state.isSkewEnabled
    }
    
    public var skewIntensity: Double {
        return state.skewIntensity
    }
    
    public var blurMaterialStyle: Int { return state.blurMaterialStyle }
    public var blurDirection: Int { return state.blurDirection }
    public var skewTransformMode: Int { return state.skewTransformMode }
    public var skewPivotPoint: Int { return state.skewPivotPoint }
}
