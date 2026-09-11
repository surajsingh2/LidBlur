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
        
        // Use maximum window level (2,147,483,631) so overlay renders over Lock Screen & Screen Saver
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = false
        
        setupViews(frame: screenFrame)
        setupLockObservers()
    }
    
    private func setupViews(frame: NSRect) {
        containerView.frame = frame
        containerView.wantsLayer = true
        self.contentView = containerView
        
        visualEffectView.frame = frame
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        
        containerView.addSubview(visualEffectView)
        
        // Setup top-to-bottom gradient mask
        maskLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        maskLayer.colors = [
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor
        ]
        
        maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Top of screen
        maskLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Bottom of screen
        maskLayer.locations = [0.0, 0.0, 0.0, 1.0]
        
        visualEffectView.layer?.mask = maskLayer
    }
    
    private func setupLockObservers() {
        // Observe macOS Screen Lock events to ensure overlay stays on top
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            self?.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
            self?.orderFrontRegardless()
        }
        
        center.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.orderFrontRegardless()
        }
    }
    
    /// Updates screen blur based on lid angle progress (0.0 = clear, 1.0 = fully blurred)
    public func setBlurProgress(
        _ progress: CGFloat,
        blurIntensity: CGFloat = 1.0,
        blurMaterialStyle: Int = 0,
        blurDirection: Int = 0
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
        
        // 2. Update Expansion Direction via Gradient Mask
        switch blurDirection {
        case 1: // Bottom-to-Top
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        case 2: // Center Outward
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        default: // Top-to-Bottom (Default)
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
        
        CATransaction.commit()
    }
    
    public func setMousePassThrough(_ passThrough: Bool) {
        self.ignoresMouseEvents = passThrough
    }
}
