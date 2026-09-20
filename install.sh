#!/bin/bash
# ==============================================================================
# Bitkub BTC Bar - Installer Script
# macOS Menu Bar App for Bitkub Bitcoin DCA Tracking
# https://github.com/greenoxz/bitkub-btc-bar
# ==============================================================================
set -e

REPO="greenoxz/bitkub-btc-bar"
APP_NAME="BitkubBtcBar.app"
DEST_DIR="/Applications"
DEST_APP="$DEST_DIR/$APP_NAME"

echo "======================================================"
echo "⚡️  Bitkub BTC Bar - ติดตั้งแอปติดตาม Bitcoin DCA"
echo "======================================================"

# 1. ตรวจสอบระบบปฏิบัติการ macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ขออภัย: แอปนี้รองรับเฉพาะระบบปฏิบัติการ macOS เท่านั้น"
    exit 1
fi

# 2. ตรวจสอบเวอร์ชัน macOS (ต้องการอย่างน้อย macOS 13 Ventura สำหรับ SwiftUI Charts)
OS_VER=$(sw_vers -productVersion | cut -d. -f1)
if [ "$OS_VER" -lt 13 ]; then
    echo "⚠️  ต้องการ macOS 13.0 (Ventura) ขึ้นไป (เครื่องของคุณคือ macOS $OS_VER)"
    exit 1
fi

# 3. เตรียมไฟล์สำหรับการติดตั้ง
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

if [ -f "$DIR/main.swift" ] && [ -f "$DIR/build.sh" ]; then
    echo "🔨 กำลังคอมไพล์จาก Source Code..."
    bash "$DIR/build.sh"
    BUILT_APP="$DIR/$APP_NAME"
else
    # กรณีรันผ่าน curl | bash
    TMP_DIR=$(mktemp -d)
    echo "📦 กำลังดาวน์โหลด Source Code ล่าสุด..."
    git clone --depth 1 "https://github.com/$REPO.git" "$TMP_DIR"
    echo "🔨 กำลังคอมไพล์ BitkubBtcBar..."
    bash "$TMP_DIR/build.sh"
    BUILT_APP="$TMP_DIR/$APP_NAME"
fi

# 4. ปิดแอปเดิมที่กำลังทำงานอยู่ (ถ้ามี)
echo "🔄 ปิดแอปเดิมที่กำลังทำงานอยู่..."
killall BitkubBtcBar 2>/dev/null || true
sleep 1

# 5. ติดตั้งไปยัง /Applications
echo "🚀 กำลังติดตั้งไปยัง $DEST_APP..."
rm -rf "$DEST_APP"
cp -R "$BUILT_APP" "$DEST_DIR/"

# ปลดล็อก Gatekeeper Quarantine attribute เพื่อให้เปิดแอปได้ทันที
xattr -cr "$DEST_APP" 2>/dev/null || true

# ทำความสะอาด tmp (ถ้ามี)
if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
fi

echo ""
echo "✅ ติดตั้ง Bitkub BTC Bar สำเร็จเรียบร้อยแล้ว!"
echo "📍 ติดตั้งไว้ที่: $DEST_APP"
echo ""

# 6. เปิดแอปทันที
read -p "ต้องการเปิดแอปทันทีเลยหรือไม่? (Y/n): " -n 1 -r || true
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open "$DEST_APP"
    echo "🎉 เปิดแอปเรียบร้อยแล้ว ดูไอคอน ₿ ที่แถบ Menu Bar ด้านบนได้เลยครับ"
fi
