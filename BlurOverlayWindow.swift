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
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
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
        
        // Setup top-to-bottom mask
        maskLayer.frame = visualEffectView.bounds
        // Black opacity = keep blur, Clear opacity = reveal screen content underneath
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
    
    /// Updates top-to-bottom blur based on progress (0.0 = clear, 1.0 = fully blurred)
    public func setBlurProgress(_ progress: CGFloat) {
        let p = max(0.0, min(1.0, progress))
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if p <= 0.001 {
            maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
        } else if p >= 0.999 {
            maskLayer.locations = [0.0, 1.0, 1.0, 1.0]
        } else {
            // Soft gradient transition at the leading edge of the blur
            let edge = p
            let softStart = max(0.0, edge - 0.08)
            let softEnd = min(1.0, edge + 0.02)
            maskLayer.locations = [
                0.0 as NSNumber,
                softStart as NSNumber,
                softEnd as NSNumber,
                1.0 as NSNumber
            ]
        }
        
        CATransaction.commit()
    }
    
    public func setMousePassThrough(_ passThrough: Bool) {
        self.ignoresMouseEvents = passThrough
    }
}
