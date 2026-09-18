# แผนการพัฒนาให้ระบบรองรับการแสดงผลหลาย Site (Multi-Site Support)

ปรับปรุงระบบติดตามความเย็น (Cold Chain Monitoring) ให้สามารถแยกแยะ จัดกลุ่ม และแสดงผลตู้แช่ตามไซต์ (Site) ต่างๆ ได้อย่างถูกต้อง โดยดึงข้อมูล Site ID จากโครงสร้าง MQTT Topic หรือ Payload

## Proposed Changes

### 1. Data Model Configuration

#### [MODIFY] [fridge_telemetry.dart](file:///Users/taipower/flutter_project/lib/models/fridge_telemetry.dart)
- เพิ่มฟิลด์ `siteId` ในคลาส `FridgeTelemetry`
- อัปเดต `fromJson` และ `copyWith` ให้รองรับ `siteId`

### 2. MQTT Service Configuration

#### [MODIFY] [mqtt_service.dart](file:///Users/taipower/flutter_project/lib/services/mqtt_service.dart)
- ปรับฟังก์ชัน `_listenMessages` ให้สกัดข้อมูล `siteId` จาก MQTT Topic (`coldchain1/{siteId}/{deviceId}/...`) ในกรณีที่ไม่มี `site_id` ใน Payload
- อัปเดตและสร้างฟังก์ชัน `muteBuzzer` และ `unmuteBuzzer` เพื่อส่งคำสั่งควบคุมไปยังไซต์และอุปกรณ์ที่ถูกต้องผ่าน `_publishCommand`

### 3. State Management Configuration

#### [MODIFY] [coldchain_provider.dart](file:///Users/taipower/flutter_project/lib/providers/coldchain_provider.dart)
- อัปเดตฟังก์ชัน `muteBuzzer` และ `unmuteBuzzer` ให้ส่งทั้ง `siteId` และ `deviceId` ไปยัง `MqttService`
- เพิ่ม Getter หรือฟังก์ชันสำหรับจัดกลุ่มตู้แช่ตาม Site หรือแยกการดึงข้อมูลตามกลุ่มไซต์เพื่อให้ง่ายต่อการนำไปแสดงผลบน UI

### 4. User Interface Changes

#### [MODIFY] [fridge_card.dart](file:///Users/taipower/flutter_project/lib/widgets/fridge_card.dart)
- เพิ่มการแสดงผลข้อความหรือ Chip ระบุ `Site ID` ภายใน Card อุปกรณ์

#### [MODIFY] [dashboard_screen.dart](file:///Users/taipower/flutter_project/lib/screens/dashboard_screen.dart)
- ปรับโครงสร้างหน้า Dashboard ให้แสดงผลแยกตามกลุ่มไซต์ (เช่น ใช้ `ExpansionTile` หรือ Section Header สำหรับแต่ละ Site)
- ปรับส่วนสรุปผล (SummaryBar) ให้แสดงยอดรวมทั้งหมด หรือแยกแยะตามการเลือก (หากต้องการ)

## Verification Plan

### Manual Verification
- ทดสอบรับข้อมูลจำลองจาก MQTT Broker โดยใช้หัวข้อที่มีความแตกต่างกันของ Site เช่น:
  - `coldchain1/Site-A/Device-01/telemetry`
  - `coldchain1/Site-B/Device-02/telemetry`
- ตรวจสอบว่าหน้าจอ Dashboard แสดงกลุ่มแยกกันระหว่าง `Site-A` และ `Site-B` อย่างถูกต้อง
- ตรวจสอบว่าปุ่ม Mute ของตู้แช่ในแต่ละไซต์สามารถส่งคำสั่งระบุไซต์ที่ถูกต้องกลับไปยัง Broker ได้
