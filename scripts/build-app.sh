#!/usr/bin/env bash
# Build a distributable WhatCable.app bundle from the SwiftPM target.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="WhatCable"
BUNDLE_ID="com.bitmoor.whatcable"
VERSION="0.1.0"
BUILD_NUMBER="1"
MIN_OS="14.0"

DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Cleaning previous build"
rm -rf "${DIST_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

echo "==> Building release binary"
# Use whichever architecture host is on; for a universal binary, swap in:
#   --arch arm64 --arch x86_64
swift build -c release --product "${APP_NAME}"

BIN_PATH=$(swift build -c release --product "${APP_NAME}" --show-bin-path)
cp "${BIN_PATH}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

echo "==> Writing Info.plist"
cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_OS}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© $(date +%Y) Bitmoor Ltd</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Writing PkgInfo"
printf "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Verifying"
codesign --verify --deep --strict --verbose=2 "${APP_DIR}" 2>&1 | sed 's/^/    /'

echo "==> Creating zip"
( cd "${DIST_DIR}" && zip -qry "${APP_NAME}.zip" "${APP_NAME}.app" )

echo
echo "Done."
echo "  App:  ${APP_DIR}"
echo "  Zip:  ${DIST_DIR}/${APP_NAME}.zip"
echo
echo "First-run note: macOS Gatekeeper may block ad-hoc signed apps."
echo "Right-click the app → Open, then confirm in the dialog. Or run:"
echo "  xattr -dr com.apple.quarantine '${APP_DIR}'"
