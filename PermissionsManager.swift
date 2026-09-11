import Cocoa
import ApplicationServices

public class PermissionsManager {
    public static func checkAndRequestPermissions(completion: ((Bool) -> Void)? = nil) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if !isTrusted {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "System Permissions Required"
                alert.informativeText = "MacBook Lid Angle Blur requires Accessibility / Input Monitoring permission to read hardware sensor angle data and manage background screen overlays.\n\nPlease grant permission in System Settings -> Privacy & Security."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Continue Anyway")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    openSystemSettings()
                }
                completion?(false)
            }
        } else {
            completion?(true)
        }
    }
    
    public static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
