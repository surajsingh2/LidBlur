# Lid Angle Blur for macOS 📐🔒

[![macOS](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.5-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Hardware](https://img.shields.io/badge/Sensor-Apple%20Lid%20Angle-purple)](#hardware-sensor-support)

**Lid Angle Blur** is a native macOS application that tracks your MacBook Pro screen's physical tilt/lean angle in real-time using Apple's IOKit HID Lid Angle Sensor. As you tilt or close your screen lid, it applies a dynamic top-to-bottom blur overlay across your entire display to protect your screen privacy and provide a smooth, futuristic visual effect.

---

## ✨ Features

- 📐 **Real-Time Hardware Angle Tracking**: Interfaces directly with Apple's Lid Angle Sensor (`PID 0x8104` / `UsagePage 0x0020`).
- 💧 **Top-to-Bottom Blur Overlay**: Hardware-accelerated `NSVisualEffectView` with a `CAGradientLayer` dynamic mask. Closing the screen expands the blur downwards; opening the screen recedes it back.
- 🎨 **Apple Native Design**: Built with SwiftUI & AppKit, supporting dark mode, glassmorphism, and live telemetry.
- ⚡ **Zero Pass-Through Block**: `ignoresMouseEvents` allows your mouse and applications to work normally under the blur.
- ⚙️ **Customizable Sensitivity**: Adjust the starting blur angle (e.g. `90°`) and full blur angle (e.g. `20°`).
- 🚀 **Background LaunchAgent Service**: Auto-starts on macOS boot without needing Terminal open.
- 🎛️ **Manual Simulation Mode**: Test the top-to-bottom blur animation using an interactive slider without closing your laptop screen.

---

## 📦 Direct Download & Installation

### Option 1: Download `.dmg` Installer
1. Download the latest direct installer: **[`LidAngleBlur.dmg`](LidAngleBlur.dmg)**.
2. Open `LidAngleBlur.dmg` and drag **Lid Angle Blur.app** to your **Applications** folder.
3. Launch **Lid Angle Blur** from Applications or Spotlight.

### Option 2: Run as a Background Service (Auto-Start at Boot)
To run Lid Angle Blur silently in the background whenever you log into your Mac:

```bash
# Register & start background LaunchAgent service
/Applications/LidAngleBlur.app/Contents/Resources/install_service.sh
```

To stop or uninstall the background service anytime:
```bash
/Applications/LidAngleBlur.app/Contents/Resources/uninstall_service.sh
```

---

## 🔐 System Permissions Setup

On first launch, macOS requires standard Accessibility permission to allow the background overlay and HID sensor interaction:

1. Launch **Lid Angle Blur**.
2. Click **"Open System Settings"** on the prompt (or go to `System Settings` -> `Privacy & Security` -> `Accessibility`).
3. Toggle **ON** the switch for **Lid Angle Blur**.

---

## 🛠️ Building from Source

### Prerequisites
- macOS 11.0 (Big Sur) or newer
- Xcode Command Line Tools (`xcode-select --install`)

### Build Steps & Create DMG
```bash
# Clone the repository
git clone https://github.com/your-username/LidAngleBlurApp.git
cd LidAngleBlurApp

# Build native .app bundle and .dmg installer
./build_dmg.sh
```

The compiled binary and installer will be generated in:
- App Bundle: `build/LidAngleBlur.app`
- Disk Image: `LidAngleBlur.dmg`

---

## 🔍 Hardware Sensor Compatibility

Lid Angle Blur uses Apple's internal `IOKit` Human Interface Device (HID) framework to read real-time angle feature reports from:
- **Vendor ID**: `0x05AC` (Apple)
- **Product ID**: `0x8104` (Lid Sensor)
- **Usage Page**: `0x0020` (Sensor) / **Usage**: `0x008A` (Orientation)

This sensor is present in MacBook Pro models (16-inch 2019, M1/M2/M3/M4 MacBook Pros, and modern MacBook Airs). If launched on a device without a lid sensor (e.g. Mac mini / Mac Studio), the app automatically defaults to **Manual Simulation Mode**.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
