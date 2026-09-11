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
        
        // Pivot 3D transformation from top hinge center
        if let layer = visualEffectView.layer {
            layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            layer.frame = frame
        }
        
        // Setup top-to-bottom gradient mask
        maskLayer.frame = visualEffectView.bounds
        maskLayer.colors = [
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor
        ]
        
        // In macOS CALayer, y = 1.0 is TOP, y = 0.0 is BOTTOM
        maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Top
        maskLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Bottom
        
        // Default clear screen (progress = 0.0)
        maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
        
        visualEffectView.layer?.mask = maskLayer
    }
    
    /// Updates top-to-bottom blur and 3D perspective skew based on progress (0.0 = clear, 1.0 = fully blurred/skewed)
    public func setBlurAndSkewProgress(_ progress: CGFloat, skewIntensity: CGFloat = 1.0, isSkewEnabled: Bool = true) {
        let p = max(0.0, min(1.0, progress))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 1. Update Top-to-Bottom Blur Mask
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
        
        // 2. Update 3D Perspective Skew Transform (Pivoting from top hinge)
        if let layer = visualEffectView.layer {
            if !isSkewEnabled || p <= 0.001 {
                layer.transform = CATransform3DIdentity
            } else {
                var transform = CATransform3DIdentity
                // Perspective projection depth (m34)
                transform.m34 = -1.0 / 750.0
                
                // Rotation angle around X-axis (tilting bottom back/down into perspective)
                let maxRotationDegrees: CGFloat = 24.0 * skewIntensity
                let rotationRadians = (p * maxRotationDegrees) * .pi / 180.0
                
                // Apply 3D perspective rotation around X-axis
                transform = CATransform3DRotate(transform, rotationRadians, 1.0, 0.0, 0.0)
                
                // Subtle 3D scale foreshortening compression
                let scaleY = 1.0 - (p * 0.05 * skewIntensity)
                let scaleX = 1.0 - (p * 0.02 * skewIntensity)
                transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
                
                layer.transform = transform
            }
        }
        
        CATransaction.commit()
    }
    
    public func setMousePassThrough(_ passThrough: Bool) {
        self.ignoresMouseEvents = passThrough
    }
}
