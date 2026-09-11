# Lid Angle Blur for macOS 📐💧

[![macOS](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.5-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Hardware](https://img.shields.io/badge/Sensor-Apple%20Lid%20Angle-purple)](#hardware-lid-angle-sensor)

**Lid Angle Blur** is a native macOS application that tracks your MacBook screen's physical tilt/lean angle in real-time using Apple's internal `IOKit` Lid Angle Sensor. As you close or open your screen lid, it applies a smooth, hardware-accelerated top-to-bottom blur overlay across your screen to protect your privacy.

---

## ✨ Features

- 📐 **Real-Time Hardware Angle Tracking**: Interfaces directly with Apple's internal HID Lid Angle Sensor (`PID 0x8104` / `UsagePage 0x0020`).
- 💧 **Dynamic Top-to-Bottom Blur Overlay**: Hardware-accelerated `NSVisualEffectView` with gradient mask expansion. Closing the lid expands the blur downwards; opening the lid recedes it back.
- 🎨 **Customizable Glass Styles & Opacity**: Choose between HUD Dark Glass, Ultra Dark, Light Popover, and System FullScreen, with an adjustable opacity intensity slider (`20%` to `100%`).
- ⚡ **Zero Pass-Through Interruption**: `ignoresMouseEvents` lets your mouse and applications work normally under the blur layer.
- 🚀 **Background LaunchAgent Service**: Auto-starts on macOS boot and runs silently in the menu bar (`📐 LidBlur`).
- 🎛️ **Manual Test Mode**: Includes an interactive simulation slider to test the blur animation without shutting your screen lid.

---

## 📦 Direct Download & Installation

### ⬇️ Download Installer
Click to download the `.dmg` installer directly:

👉 **[Download LidAngleBlur.dmg (Direct Download)](https://github.com/surajsingh2/LidBlur/raw/master/LidAngleBlur.dmg)**

---

### 💻 Installation Steps
1. Open the downloaded `LidAngleBlur.dmg` file.
2. Drag **Lid Angle Blur.app** into your **Applications** folder.
3. Launch **Lid Angle Blur** from Applications or Spotlight.

---

### 🚀 Run as a Background Service (Auto-Start at Boot)
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

```bash
# Clone the repository
git clone https://github.com/surajsingh2/LidBlur.git
cd LidBlur

# Build native .app bundle and .dmg installer
./build_dmg.sh
```

The compiled binary and installer will be generated in:
- App Bundle: `build/LidAngleBlur.app`
- Disk Image: `LidAngleBlur.dmg`

---

## 🔍 Hardware Lid Angle Sensor

Lid Angle Blur uses Apple's internal `IOKit` Human Interface Device (HID) framework to read real-time angle feature reports from:
- **Vendor ID**: `0x05AC` (Apple)
- **Product ID**: `0x8104` (Lid Sensor)
- **Usage Page**: `0x0020` (Sensor) / **Usage**: `0x008A` (Orientation)

Supported on MacBook Pro models (16-inch 2019, M1/M2/M3/M4 MacBook Pros, and modern MacBook Airs). On non-laptop Macs, the app defaults to **Manual Simulation Mode**.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
