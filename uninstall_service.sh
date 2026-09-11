#!/bin/bash
PLIST_NAME="com.lidangleblur.app.plist"
TARGET_PLIST="${HOME}/Library/LaunchAgents/${PLIST_NAME}"

echo "🛑 Stopping and uninstalling Lid Angle Blur service..."

if [ -f "${TARGET_PLIST}" ]; then
    launchctl unload -w "${TARGET_PLIST}" 2>/dev/null || true
    rm -f "${TARGET_PLIST}"
    echo "✅ Service uninstalled successfully."
else
    echo "ℹ️  Service plist file not found in LaunchAgents."
fi

killall LidAngleBlurApp 2>/dev/null || true
