import Cocoa
import QuartzCore

public class BlurOverlayWindow: NSWindow {
    private let containerView = NSView()
    private let visualEffectView = NSVisualEffectView()
    private let maskLayer = CAGradientLayer()
    
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
        
        // Full screen visual effect view
        visualEffectView.frame = frame
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        
        containerView.addSubview(visualEffectView)
        
        // Lock layer anchor point and position to top center of screen
        if let layer = visualEffectView.layer {
            layer.bounds = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            layer.position = CGPoint(x: screenWidth / 2.0, y: screenHeight)
        }
        
        // Setup top-to-bottom gradient mask
        maskLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        maskLayer.colors = [
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor
        ]
        
        // In macOS CALayer, y = 1.0 is TOP, y = 0.0 is BOTTOM
        maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Top of screen
        maskLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Bottom of screen
        maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
        
        visualEffectView.layer?.mask = maskLayer
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
        
        // 1. Update Material Style & Alpha
        switch blurMaterialStyle {
        case 1: visualEffectView.material = .underWindowBackground
        case 2: visualEffectView.material = .popover
        case 3: visualEffectView.material = .fullScreenUI
        default: visualEffectView.material = .hudWindow
        }
        
        visualEffectView.alphaValue = blurIntensity
        
        // 2. Update Blur Expansion Direction via Gradient Mask
        switch blurDirection {
        case 1: // Bottom-to-Top
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        case 2: // Center Outward
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        default: // Top-to-Bottom
            maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        }
        
        if p <= 0.001 {
            maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
            visualEffectView.isHidden = true
        } else if p >= 0.999 {
            maskLayer.locations = [0.0, 1.0, 1.0, 1.0]
            visualEffectView.isHidden = false
        } else {
            visualEffectView.isHidden = false
            let softStart = max(0.0, p - 0.08)
            let softEnd = min(1.0, p + 0.02)
            maskLayer.locations = [
                0.0 as NSNumber,
                softStart as NSNumber,
                softEnd as NSNumber,
                1.0 as NSNumber
            ]
        }
        
        // 3. Update Anchor Point, Position, and 3D Skew Transform
        if let layer = visualEffectView.layer {
            switch skewPivotPoint {
            case 1: // Center Pivot
                layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                layer.position = CGPoint(x: screenWidth / 2.0, y: screenHeight / 2.0)
            case 2: // Bottom Edge Pivot
                layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                layer.position = CGPoint(x: screenWidth / 2.0, y: 0)
            default: // Top Hinge Pivot (Default)
                layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                layer.position = CGPoint(x: screenWidth / 2.0, y: screenHeight)
            }
            
            if !isSkewEnabled || p <= 0.001 {
                layer.transform = CATransform3DIdentity
            } else {
                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 650.0 // True 3D perspective projection depth
                
                let rotationRadians = (p * skewAngleMax * skewIntensity) * .pi / 180.0
                
                switch skewTransformMode {
                case 1: // Trapezoid Pinch
                    transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                    let scaleX = 1.0 - (p * 0.1 * skewIntensity)
                    let scaleY = 1.0 - (p * 0.05 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
                    
                case 2: // Depth Recede
                    transform = CATransform3DRotate(transform, rotationRadians * 0.8, 1.0, 0.0, 0.0)
                    let translateZ = -p * 150.0 * skewIntensity
                    transform = CATransform3DTranslate(transform, 0, 0, translateZ)
                    let scaleFactor = 1.0 - (p * 0.08 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleFactor, scaleFactor, 1.0)
                    
                default: // 3D Hinge Pitch Tilt (Default)
                    transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                    let scaleY = 1.0 - (p * 0.04 * skewIntensity)
                    let scaleX = 1.0 - (p * 0.01 * skewIntensity)
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
