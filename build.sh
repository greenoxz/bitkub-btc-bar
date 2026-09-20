#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 กำลังคอมไพล์ BitkubBtcBar..."

# 1. คอมไพล์ Swift source code
swiftc "$DIR/main.swift" -O -o "$DIR/BitkubBtcBar" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Charts \
    -framework CryptoKit

# 2. สร้างโครงสร้าง .app bundle
mkdir -p "$DIR/BitkubBtcBar.app/Contents/MacOS"
mkdir -p "$DIR/BitkubBtcBar.app/Contents/Resources"
cp "$DIR/BitkubBtcBar" "$DIR/BitkubBtcBar.app/Contents/MacOS/"

cat << 'EOF' > "$DIR/BitkubBtcBar.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BitkubBtcBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.pisitz.bitkubbtcbar</string>
    <key>CFBundleName</key>
    <string>BitkubBtcBar</string>
    <key>CFBundleDisplayName</key>
    <string>Bitkub BTC Bar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

chmod +x "$DIR/BitkubBtcBar.app/Contents/MacOS/BitkubBtcBar"

echo "✅ คอมไพล์เสร็จสมบูรณ์: $DIR/BitkubBtcBar.app"
