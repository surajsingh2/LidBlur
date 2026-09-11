import Cocoa
import QuartzCore

public class BlurOverlayWindow: NSWindow {
    private let containerView = NSView()
    private let visualEffectView = NSVisualEffectView()
    private var screenWidth: CGFloat = 1440
    private var screenHeight: CGFloat = 900
    
    public init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        self.screenWidth = screenFrame.width
        self.screenHeight = screenFrame.height
        
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = false
        
        setupViews(frame: screenFrame)
    }
    
    private func setupViews(frame: NSRect) {
        containerView.frame = frame
        containerView.wantsLayer = true
        self.contentView = containerView
        
        visualEffectView.frame = .zero
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        
        containerView.addSubview(visualEffectView)
    }
    
    public func setBlurAndSkewProgress(
        _ progress: CGFloat,
        skewIntensity: CGFloat = 1.0,
        skewAngleMax: CGFloat = 24.0,
        blurIntensity: CGFloat = 1.0,
        isSkewEnabled: Bool = true,
        blurMaterialStyle: Int = 0,
        blurDirection: Int = 0,
        skewTransformMode: Int = 0,
        skewPivotPoint: Int = 0
    ) {
        let p = max(0.0, min(1.0, progress))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 1. Update Material Style
        switch blurMaterialStyle {
        case 1: visualEffectView.material = .underWindowBackground
        case 2: visualEffectView.material = .popover
        case 3: visualEffectView.material = .fullScreenUI
        default: visualEffectView.material = .hudWindow
        }
        
        visualEffectView.alphaValue = blurIntensity
        
        // 2. Top-to-Bottom Frame Height Clipping (Guarantees hardware backdrop blur works on all MacBooks!)
        if p <= 0.001 {
            visualEffectView.frame = .zero
            visualEffectView.isHidden = true
        } else {
            visualEffectView.isHidden = false
            switch blurDirection {
            case 1: // Bottom-to-Top
                let h = screenHeight * p
                visualEffectView.frame = NSRect(x: 0, y: 0, width: screenWidth, height: h)
            case 2: // Center Outward
                let h = screenHeight * p
                let w = screenWidth * p
                visualEffectView.frame = NSRect(x: (screenWidth - w) / 2, y: (screenHeight - h) / 2, width: w, height: h)
            default: // Top-to-Bottom (Default)
                let h = screenHeight * p
                visualEffectView.frame = NSRect(x: 0, y: screenHeight - h, width: screenWidth, height: h)
            }
        }
        
        // 3. 3D Perspective Skew Transform
        if let layer = visualEffectView.layer {
            switch skewPivotPoint {
            case 1: layer.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center
            case 2: layer.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Bottom
            default: layer.anchorPoint = CGPoint(x: 0.5, y: 1.0) // Top Hinge
            }
            
            if !isSkewEnabled || p <= 0.001 {
                layer.transform = CATransform3DIdentity
            } else {
                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 650.0 // True 3D depth perspective projection
                
                let rotationRadians = (p * skewAngleMax * skewIntensity) * .pi / 180.0
                
                switch skewTransformMode {
                case 1: // Trapezoid Pinch
                    transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                    let scaleX = 1.0 - (p * 0.12 * skewIntensity)
                    let scaleY = 1.0 - (p * 0.06 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
                    
                case 2: // Depth Recede
                    transform = CATransform3DRotate(transform, rotationRadians * 0.8, 1.0, 0.0, 0.0)
                    let translateZ = -p * 180.0 * skewIntensity
                    transform = CATransform3DTranslate(transform, 0, 0, translateZ)
                    let scaleFactor = 1.0 - (p * 0.08 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleFactor, scaleFactor, 1.0)
                    
                default: // 3D Hinge Pitch Tilt (Default)
                    transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                    let scaleY = 1.0 - (p * 0.05 * skewIntensity)
                    let scaleX = 1.0 - (p * 0.02 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
                }
                
                layer.transform = transform
            }
        }
        
        CATransaction.commit()
    }
    
    public func setMousePassThrough(_ passThrough: Bool) {
        self.ignoresMouseEvents = passThrough
    }
}
