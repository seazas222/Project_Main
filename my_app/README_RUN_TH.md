# Restaurant app: เริ่มรันในเครื่อง

## 1) Backend (Node.js 22+)

เปิด PowerShell:

```powershell
cd D:\Project_Main\my_app
Copy-Item .env.example .env
notepad .env
npm install
npm run start
```

แก้ `.env` ให้ตรงกับ MariaDB ในเครื่องก่อนรัน: `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `AUTH_TOKEN_SECRET` (สุ่มอย่างน้อย 32 ตัวอักษร) และ `PROMPTPAY_ID` (เบอร์ PromptPay หรือเลขประจำตัวผู้เสียภาษี/บัตรประชาชนของร้าน) ห้ามเผยแพร่ `.env` หรือไฟล์ Firebase service account

## 2) Database

หลังนำเข้า schema ฐานข้อมูลปัจจุบันแล้ว ให้สำรองฐานข้อมูล และตรวจสอบก่อนว่า migration ใดเคยรันสำเร็จไปแล้ว **อย่ารันไฟล์ 20261009 ซ้ำ** เพราะไฟล์แรกเพิ่มคอลัมน์โดยไม่มี `IF NOT EXISTS` หากรันซ้ำจะหยุดที่คอลัมน์ซ้ำ ให้รันเฉพาะไฟล์ที่ยังไม่ได้ใช้ ตามลำดับนี้จาก HeidiSQL:

1. `db/migrations/20261009_restaurant_features.sql` (รันครั้งเดียวกับฐานเดิม)
2. `db/migrations/20261010_notification_preference.sql`
3. `db/migrations/20261011_walk_in_table_sessions.sql`
4. `db/migrations/20261012_menu_description.sql`
5. `db/migrations/20261013_customer_admin.sql`
6. `db/migrations/20261014_menu_choice_groups.sql`
7. `db/migrations/20261015_notification_event_preference.sql`
8. `db/migrations/20261016_menu_category_image.sql`
9. `db/migrations/20261017_drink_category.sql`

ไฟล์เหล่านี้ใช้ `USE restaurant_db` ดังนั้นให้แน่ใจว่า `.env` ชี้ไปฐานข้อมูลเดียวกัน (`DB_NAME=restaurant_db`) หรือแก้คำสั่ง `USE` ให้ตรงฐานที่ตั้งใจ ก่อนรัน SQL ใด ๆ ไฟล์ 20261011 สร้างรอบใช้งานโต๊ะหน้าร้านด้วย จากนั้นเพิ่มบัญชี ADMIN หนึ่งบัญชีใน `.env`:

```dotenv
ADMIN_USERNAME=owner
ADMIN_PASSWORD=ตั้งรหัสผ่านอย่างน้อย8ตัว
ADMIN_FULLNAME=ผู้ดูแลร้าน
```

ปิด server ชั่วคราว แล้วรัน:

```powershell
npm run create-admin
npm run start
```

คำสั่งนี้สร้างบัญชี ADMIN หรือยกระดับบัญชี username ที่มีอยู่ หากมี ADMIN แล้วจะปฏิเสธการสร้างคนที่สอง

### เพิ่มเมนูอาหารตามสั่งทั่วไป

หลังรัน migration จนถึง `20261016_menu_category_image.sql` และเปิด MariaDB แล้ว ให้เรียกจาก PowerShell ใน `D:\Project_Main\my_app`:

```powershell
npm run seed-common-menus
```

คำสั่งนี้ปรับแค็ตตาล็อกอาหารตามสั่งให้เป็นชื่อจานกลาง เช่น ข้าวผัดกะเพรา และให้เลือกเนื้อผสมได้สูงสุด 5 ชนิด โดยคิดราคาเนื้อแยกจากราคาจานพื้นฐาน เมนูข้าวทั้งหมดขึ้นต้นด้วยคำว่า “ข้าว” เมนูน้ำที่ร้านไม่ขายและผัดไทยจะถูกเอาออกจากรายการขาย ยกเว้นก๋วยเตี๋ยวน้ำกับเกาเหลา ก่อนปรับระบบจะสำรองข้อมูลเมนูไว้ใน `storage/menu_catalog_backups` เมนูที่มีประวัติออร์เดอร์จะไม่ถูกลบ คำสั่งทำงานครั้งเดียวและรันซ้ำจะไม่เขียนทับการแก้ไขของแอดมิน หลังนำเข้าให้รีเฟรชหน้าจัดการร้านหรือเปิดหน้ารายการอาหารใหม่ แล้วติดตั้งภาพตัวอย่างตามหัวข้อถัดไป

### ติดตั้งภาพตัวอย่างที่ตรงกับรายการอาหาร

จาก `D:\Project_Main\my_app` และเปิด MariaDB แล้วเรียก:

```powershell
npm run install-menu-photos
```

คำสั่งนี้นำภาพอาหารและเครื่องดื่ม 17 เมนูจาก `flutter_application_1/assets/menu` ไปเก็บที่ `storage/menu_images` แล้วผูกไฟล์กับเมนูที่เปิดขาย โดยเก็บสำเนาความสัมพันธ์ภาพเดิมไว้ใน `storage/menu_catalog_backups` หากแอดมินตั้งภาพใหม่เองในภายหลัง การรันซ้ำจะไม่ทับภาพนั้น ภาพชุดนี้เป็นภาพประกอบลักษณะอาหาร ไม่ใช่ภาพถ่ายจานจริงของร้าน; แอดมินสามารถเปลี่ยนเป็นภาพจริงได้ในหน้าจัดการเมนู

## 3) Flutter

```powershell
cd D:\Project_Main\flutter_application_1
flutter pub get
```

ตั้งค่า Firebase Cloud Messaging สำหรับ Android/iOS แล้วสร้าง `lib/firebase_options.dart` ด้วย FlutterFire CLI (`flutterfire configure`) ทับไฟล์ตัวอย่าง จากนั้นตั้งค่า Firebase Admin service account ใน `my_app/firebase-service-account.json` และ `GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json` ใน `my_app/.env` เพื่อส่ง push notification การสมัครสมาชิกใช้ username/password และไม่ส่ง SMS ยืนยันเบอร์

เปิด backend ทิ้งไว้ใน PowerShell หน้าต่างหนึ่ง แล้วรัน Flutter ในอีกหน้าต่างหนึ่ง เลือก URL ตามอุปกรณ์:

Chrome/เว็บ:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

รันบนมือถือจริงให้เปลี่ยน `10.0.2.2` เป็น IP ของเครื่องคอมพิวเตอร์ที่รัน backend (และอนุญาตพอร์ต 3000 ใน firewall)

## หมายเหตุ

- QR พร้อมเพย์จะสร้างหลังออร์เดอร์ถูกทำเสร็จและสถานะเปลี่ยนเป็นรอชำระเงิน ผู้ดูแลตรวจสลิปและยืนยันการชำระ
- การสั่งอาหารหน้าร้านให้ลูกค้าเลือกโต๊ะที่นั่งอยู่ในแอป ออร์เดอร์จะผูกกับโต๊ะโดยไม่ต้องมีรายการจอง เมื่อเก็บโต๊ะแล้ว ADMIN กดปิดรอบโต๊ะในหน้า จัดการร้าน > โต๊ะ เพื่อเปิดให้สั่งรอบถัดไป
- Migration เพิ่มคอลัมน์/ตารางที่จำเป็น แต่ไม่แก้ไขข้อมูลรายการอาหารและโต๊ะเดิม
- Push notification ต้องตั้งค่า Firebase ก่อน ส่วน API/หน้าจอใช้ได้เมื่อ migration และ backend พร้อม
