#!/bin/bash
# Bundle the Swift binary into a macOS .app
set -e

APP_NAME="Timeular Macropad"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

# Build release
echo "Building release..."
swift build -c release 2>&1

BINARY=".build/release/TimeularMacropad"
if [ ! -f "$BINARY" ]; then
    echo "Build failed — binary not found"
    exit 1
fi

# Create bundle structure
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp "$BINARY" "${MACOS}/TimeularMacropad"

# Copy resource bundle if it exists
RESOURCE_BUNDLE=$(find .build/release -name "TimeularMacropad_TimeularMacropad.bundle" -type d 2>/dev/null | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "${RESOURCES}/"
fi

# Create Info.plist
cat > "${CONTENTS}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Timeular Macropad</string>
    <key>CFBundleDisplayName</key>
    <string>Timeular Macropad</string>
    <key>CFBundleIdentifier</key>
    <string>com.timeular.macropad</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>TimeularMacropad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Timeular Macropad needs Bluetooth to connect to your Timeular Tracker and detect side changes.</string>
</dict>
</plist>
PLIST

echo ""
echo "✓ Built: ${BUNDLE_DIR}"
echo ""
echo "To install:"
echo "  cp -R \"${BUNDLE_DIR}\" /Applications/"
echo ""
echo "To run:"
echo "  open \"${BUNDLE_DIR}\""
