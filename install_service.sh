#!/bin/bash
set -e

PLIST_NAME="com.lidangleblur.app.plist"
SOURCE_PLIST="/Users/surajsingh/customapps/LidAngleBlurApp/${PLIST_NAME}"
TARGET_DIR="${HOME}/Library/LaunchAgents"
TARGET_PLIST="${TARGET_DIR}/${PLIST_NAME}"

echo "🚀 Installing Lid Angle Blur as a macOS LaunchAgent Background Service..."

# Ensure LaunchAgents directory exists
mkdir -p "${TARGET_DIR}"

# Copy plist file
cp "${SOURCE_PLIST}" "${TARGET_PLIST}"

# Unload if already loaded
launchctl unload "${TARGET_PLIST}" 2>/dev/null || true

# Load and start service
launchctl load -w "${TARGET_PLIST}"

echo "✅ Service successfully installed and started!"
echo "📌 Status bar icon '📐 LidBlur' will now stay active in background on boot."
echo "ℹ️  To check status anytime: launchctl list | grep lidangleblur"
