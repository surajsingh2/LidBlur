import Cocoa
import QuartzCore

public class BlurOverlayWindow: NSWindow {
    private let visualEffectView = NSVisualEffectView()
    private let maskLayer = CAGradientLayer()
    
    public init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = false
        
        setupBlurView(frame: NSRect(origin: .zero, size: screenFrame.size))
    }
    
    private func setupBlurView(frame: NSRect) {
        let containerView = NSView(frame: frame)
        containerView.wantsLayer = true
        self.contentView = containerView
        
        visualEffectView.frame = frame
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        
        containerView.addSubview(visualEffectView)
        
        if let layer = visualEffectView.layer {
            layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            layer.frame = frame
        }
        
        maskLayer.frame = visualEffectView.bounds
        maskLayer.colors = [
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor
        ]
        
        maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Top
        maskLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Bottom
        maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
        
        visualEffectView.layer?.mask = maskLayer
    }
    
    /// Apply configurable blur material, direction, transform mode, and pivot
    public func setBlurAndSkewProgress(
        _ progress: CGFloat,
        skewIntensity: CGFloat = 1.0,
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
        
        // 2. Update Blur Gradient Mask Direction
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
        } else if p >= 0.999 {
            maskLayer.locations = [0.0, 1.0, 1.0, 1.0]
        } else {
            let softStart = max(0.0, p - 0.08)
            let softEnd = min(1.0, p + 0.02)
            maskLayer.locations = [
                0.0 as NSNumber,
                softStart as NSNumber,
                softEnd as NSNumber,
                1.0 as NSNumber
            ]
        }
        
        // 3. Update Pivot Point
        if let layer = visualEffectView.layer {
            switch skewPivotPoint {
            case 1: layer.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center
            case 2: layer.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Bottom Edge
            default: layer.anchorPoint = CGPoint(x: 0.5, y: 1.0) // Top Hinge
            }
            
            if !isSkewEnabled || p <= 0.001 {
                layer.transform = CATransform3DIdentity
            } else {
                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 750.0
                
                let maxRotationDegrees: CGFloat = 24.0 * skewIntensity
                let rotationRadians = (p * maxRotationDegrees) * .pi / 180.0
                
                switch skewTransformMode {
                case 1: // Trapezoid Pinch & Scale
                    transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                    let scaleX = 1.0 - (p * 0.12 * skewIntensity)
                    let scaleY = 1.0 - (p * 0.08 * skewIntensity)
                    transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
                    
                case 2: // Depth Zoom & Recede
                    transform = CATransform3DRotate(transform, rotationRadians * 0.8, 1.0, 0.0, 0.0)
                    let translateZ = -p * 150.0 * skewIntensity
                    transform = CATransform3DTranslate(transform, 0, 0, translateZ)
                    let scaleFactor = 1.0 - (p * 0.1 * skewIntensity)
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
