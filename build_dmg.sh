#!/bin/bash
set -e

APP_NAME="LidAngleBlur"
BUILD_DIR="/Users/surajsingh/customapps/LidAngleBlurApp/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
DMG_PATH="/Users/surajsingh/customapps/LidAngleBlurApp/${DMG_NAME}"
STAGING_DIR="${BUILD_DIR}/dmg_staging"

echo "🛠️  Step 1: Compiling Swift Source Files..."
mkdir -p "${BUILD_DIR}"
swiftc -O /Users/surajsingh/customapps/LidAngleBlurApp/*.swift \
    -framework Cocoa \
    -framework IOKit \
    -framework QuartzCore \
    -framework ApplicationServices \
    -framework SwiftUI \
    -o "${BUILD_DIR}/LidAngleBlurApp"

echo "📦 Step 2: Assembling ${APP_NAME}.app Bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/LidAngleBlurApp" "${APP_BUNDLE}/Contents/MacOS/LidAngleBlurApp"
cp "/Users/surajsingh/customapps/LidAngleBlurApp/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "/Users/surajsingh/customapps/LidAngleBlurApp/com.lidangleblur.app.plist" "${APP_BUNDLE}/Contents/Resources/"
cp "/Users/surajsingh/customapps/LidAngleBlurApp/install_service.sh" "${APP_BUNDLE}/Contents/Resources/"
cp "/Users/surajsingh/customapps/LidAngleBlurApp/uninstall_service.sh" "${APP_BUNDLE}/Contents/Resources/"

echo "🔏 Step 3: Performing Ad-Hoc Code Signing on App Bundle..."
codesign -s - --deep --force "${APP_BUNDLE}"

echo "💿 Step 4: Preparing Disk Image Staging Directory..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"

# Add Applications symlink for drag-and-drop installation
ln -s /Applications "${STAGING_DIR}/Applications"

echo "💽 Step 5: Creating ${DMG_NAME} using hdiutil..."
rm -f "${DMG_PATH}"

hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${DMG_PATH}"

echo "🎉 Build Complete!"
echo "📍 App Bundle: ${APP_BUNDLE}"
echo "📍 DMG File: ${DMG_PATH}"
