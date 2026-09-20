#!/bin/bash
# ==============================================================================
# Bitkub BTC Bar - Release Packager
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 กำลังคอมไพล์เวอร์ชัน Release..."
bash "$DIR/build.sh"

echo "📦 กำลังบีบอัดเป็น BitkubBtcBar.zip..."
cd "$DIR"
rm -f BitkubBtcBar.zip
zip -r -y -9 BitkubBtcBar.zip BitkubBtcBar.app

SHA=$(shasum -a 256 BitkubBtcBar.zip | awk '{print $1}')
echo ""
echo "✅ สร้างไฟล์ Release สำเร็จ: $DIR/BitkubBtcBar.zip"
echo "🔑 SHA256 Checksum: $SHA"
echo ""
echo "คุณสามารถอัปโหลดไฟล์ BitkubBtcBar.zip ไปที่ GitHub Releases ได้ทันที"
