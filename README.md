# ₿ Bitkub BTC Bar

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

แอปพลิเคชัน Menu Bar บน macOS สำหรับติดตามพอร์ต **Bitcoin DCA บน Bitkub** และดูราคา BTC แบบเรียลไทม์ ออกแบบด้วยสไตล์ **Liquid Glass (Apple Frosted Glass & Pill Shapes)** ที่หรูหรา โปร่งแสง สบายตา และกลมกลืนกับ macOS

---

## ✨ คุณสมบัติเด่น (Features)

- ⚡️ **ติดตามพอร์ต DCA อัตโนมัติ:** เชื่อมต่อ Bitkub API ดึงประวัติการซื้อ DCA คำนวณต้นทุนเฉลี่ย กำไร/ขาดทุนทั้งบาทและ % แบบเรียลไทม์
- ⚡️ **นับจำนวน Satoshis (Sats ⚡️):** แสดงทั้งหน่วย BTC และจำนวน Sats ที่สะสมได้ในพอร์ต
- 📜 **ประวัติไม้ DCA รายวัน:** แท็บแสดงรายการไม้ที่ซื้อในแต่ละวันอย่างละเอียด (วันที่, ราคาที่ซื้อได้ @ rate, และจำนวน Sats ที่ได้รับ) เลื่อนดูย้อนหลังได้อย่างลื่นไหล
- 📊 **กราฟเปรียบเทียบและการเติบโต (SwiftUI Charts):**
  - กราฟเปรียบเทียบระหว่าง DCA Bitcoin vs ไม่ลงทุนแต่เก็บเงินสดวันละเท่ากัน
  - กราฟแนวโน้มราคา 90 วัน พร้อมเส้นบอกราคาต้นทุนเฉลี่ยของคุณ
  - กราฟราคา BTC 24 ชั่วโมง
- ⚠️ **ระบบเตือนเงินบาทใกล้หมด (Low Balance Alert):** แจ้งเตือนเมื่อเงินบาทในบัญชี Bitkub เหลือพอสำหรับ DCA ต่ำกว่ากำหนด (ค่าเริ่มต้น 2 วัน) ป้องกันไม่ให้ DCA สะดุด
- ⚙️ **สลับการแสดงผลบน Menu Bar:** เลือกได้ว่าจะให้แถบเมนูด้านบนแสดง **"💰 เงินในพอร์ต"** หรือ **"📈 ราคาตลาดวันนี้"**
- 🎨 **ดีไซน์ Apple Liquid Glass:** ขอบมน Pill Shapes กระจกฝ้าขุ่นโปร่งแสง มีมิติและอ่านง่าย

---

## 🔒 ความปลอดภัยและความเป็นส่วนตัว (Security & Privacy)

> [!IMPORTANT]
> **ข้อมูล API Key และ Secret ของคุณจะถูกเก็บไว้เฉพาะในเครื่องของคุณเท่านั้น (Local Storage)**  
> แอปนี้ไม่มีเซิร์ฟเวอร์คนกลาง ไม่มีการเก็บข้อมูลหรือส่งข้อมูลไปที่อื่นใดทั้งสิ้น การเชื่อมต่อทั้งหมดเป็นการเรียกตรงจาก Mac ของคุณไปยัง Bitkub API (`api.bitkub.com`) โดยตรง

### สิทธิ์ของ API Key ที่ต้องเปิด:
- ✅ **Read** (อ่านข้อมูลราคาและคำสั่งซื้อ)
- ✅ **Wallet** (ดูยอดคงเหลือ BTC และ THB)
- ❌ **Trade** (ไม่ต้องเปิด)
- ❌ **Withdraw / ถอนเงิน** (**ห้ามเปิดเด็ดขาด** เพื่อความปลอดภัยสูงสุด)

---

## 🚀 วิธีการติดตั้ง (Installation)

### วิธีที่ 1: ติดตั้งผ่านคำสั่งเดียว (แนะนำ)
เปิด **Terminal** บน Mac แล้วรันคำสั่งนี้ได้ทันที:

```bash
curl -fsSL https://raw.githubusercontent.com/greenoxz/bitkub-btc-bar/main/install.sh | bash
```

คำสั่งนี้จะคอมไพล์และติดตั้ง `BitkubBtcBar.app` ไปยังโฟลเดอร์ `/Applications` ให้พร้อมใช้งานทันที

---

### วิธีที่ 2: ติดตั้งผ่าน Homebrew

```bash
brew install --cask https://raw.githubusercontent.com/greenoxz/bitkub-btc-bar/main/Casks/bitkub-btc-bar.rb
```

---

### วิธีที่ 3: คอมไพล์เองจาก Source Code (Manual Build)

```bash
git clone https://github.com/greenoxz/bitkub-btc-bar.git
cd bitkub-btc-bar
./build.sh
open BitkubBtcBar.app
```

---

## 🛠️ วิธีตั้งค่า Bitkub API (Getting Started)

1. เข้าสู่ระบบเว็บไซต์ [Bitkub.com](https://www.bitkub.com)
2. ไปที่ **การตั้งค่าบัญชี (Settings)** > **API**
3. กดสร้าง API Key ใหม่:
   - ติ๊กถูกเฉพาะสิทธิ์ **Read** และ **Wallet**
   - **ไม่ต้องติ๊ก** สิทธิ์ Trade หรือ Withdraw
4. คัดลอก **API Key** และ **API Secret**
5. คลิกที่ไอคอน ₿ บน Menu Bar ด้านบนของ Mac
6. กดปุ่มรูปฟันเฟือง **⚙️** ที่มุมบนขวา
7. วาง API Key และ API Secret ลงในช่อง แล้วกด **"บันทึกข้อมูล"**
8. พอร์ต DCA ของคุณจะเริ่มคำนวณและแสดงผลทันที!

---

## 🖥️ ความต้องการของระบบ (System Requirements)

- macOS 13.0 (Ventura) ขึ้นไป
- สิทธิ์การเชื่อมต่ออินเทอร์เน็ตเพื่อดึงข้อมูลราคาจาก Bitkub API

---

## 📄 ใบอนุญาต (License)

โปรเจกต์นี้เผยแพร่ภายใต้สัญญาอนุญาต [MIT License](LICENSE) สามารถนำไปใช้งาน ปรับปรุง และพัฒนาต่อได้อย่างอิสระ
