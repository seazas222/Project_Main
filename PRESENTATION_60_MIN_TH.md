# บทซ้อมนำเสนอ Restaurant App ภายใน 1 ชั่วโมง

> ใช้พูดประกอบการเปิดแอปและโค้ดจริง ณ 15 ตุลาคม 2026 เวลาที่กำหนดรวมช่วงตอบคำถาม 10 นาที ตัวเลขบรรทัดในลิงก์อาจขยับเมื่อแก้โค้ด ให้ค้นชื่อฟังก์ชันในไฟล์หากไม่ตรง บทนี้เป็นตัวอย่างภาษาพูด ควรซ้อมด้วยคำของตัวเองและสาธิตกับข้อมูลที่มีจริง

เอกสารประกอบ: [แผนที่ทุกหน้าจอ](/D:/Project_Main/APP_SCREEN_WALKTHROUGH_TH.md) · [แผนที่ UI กับบรรทัดโค้ด](/D:/Project_Main/UI_CODE_MAP_TH.md) · [คู่มือสถาปัตยกรรมและโค้ด](/D:/Project_Main/PROJECT_INTERVIEW_GUIDE_TH.md)

## เตรียมก่อนเข้าห้อง

1. เปิด MariaDB, backend และ Flutter ตาม [README วิธีรัน](/D:/Project_Main/my_app/README_RUN_TH.md) และลองเข้าบัญชีลูกค้า/แอดมินที่เตรียมไว้ก่อนเริ่มจับเวลา อย่าเปิด `.env` หรือรหัสผ่านบนโปรเจกเตอร์
2. เตรียมข้อมูลสาธิต: ลูกค้า 1 คน โต๊ะว่างในวันเปิดร้าน เมนูที่ขายได้ ออร์เดอร์ที่ครัวรับแล้ว และสลิปตัวอย่าง ถ้าไม่มีข้อมูลจริงให้เล่า flow จากโค้ดแทน อย่าอ้างว่ากดสำเร็จทั้งที่ไม่ได้ทำ
3. เปิด IDE ไว้ที่ `main.dart`, `api_service.dart`, `server.js`, `reservation_page.dart`, `food_detail_page.dart`, `admin_dashboard_page.dart` และไฟล์นี้
4. ซ้อมเปลี่ยนระหว่างแอปกับ IDE ภายใน 5 วินาที ใช้การค้นหาชื่อฟังก์ชัน ไม่เลื่อนหาโค้ดทีละบรรทัดต่อหน้าอาจารย์
5. วางแผนสาธิตแบบปลอดภัย: ดูข้อมูลก่อน กดสร้างข้อมูลใหม่เฉพาะเมื่อจำเป็น และไม่อนุมัติสลิปว่าโอนจริงหากเป็นข้อมูลจำลอง

## ตารางเวลา 60 นาที

| เวลา | เนื้อหา | หน้าจอ/โค้ดที่เปิด | หลักฐานที่ต้องชี้ |
|---|---|---|---|
| 0–3 | ปัญหา เป้าหมาย ผู้ใช้ 2 บทบาท | Splash, Home, Admin | ลูกค้าและผู้ดูแลมีหน้าต่างกัน |
| 3–8 | สถาปัตยกรรม 3 ชั้น | `main.dart`, `api_service.dart`, `server.js`, `db_pool.js` | UI → HTTP/JSON → SQL |
| 8–13 | สมัคร/ล็อกอิน/สิทธิ์ | Login, Sign up, Profile | bcrypt, token, role, ตรวจสิทธิ์ที่ backend |
| 13–21 | จองโต๊ะ/ปฏิทิน/ประวัติ | Reservation, Booking | วัน 3 สี, เวลา, จำนวนคน, transaction |
| 21–29 | เมนู/ตัวเลือก/ตะกร้า | Menu, Food Detail, Cart | เลือกเนื้อสูงสุด 5, ราคาบน server |
| 29–35 | ออร์เดอร์/ครัว/แอดมิน | Admin Booking, Kitchen | สถานะและการจัดกลุ่มตามวัน |
| 35–41 | QR/สลิป/ยอดขาย | Payment QR, Admin Payment, Dashboard | ยอดจาก DB, ยืนยันสลิปโดยคน |
| 41–46 | การแจ้งเตือน | Profile, Notification Inbox | สีตามค่า ณ เวลาเกิดข้อความ, เตือนก่อน 60/10 นาที |
| 46–50 | จัดการร้านและข้อจำกัด | Admin Management | แบนเนอร์, เมนู, โต๊ะ, วันหยุด, PromptPay |
| 50–60 | คำถามอาจารย์ | เปิดไฟล์ตามคำถาม | ตอบโดยชี้ UI → callback → API → SQL → เงื่อนไข |

ถ้าอาจารย์ถามระหว่างสาธิต ให้ลดช่วงจัดการร้าน 2 นาที และใช้ช่วงถามตอบท้ายเป็นเวลาสำรอง อย่าเร่งตอบโดยเดา

---

## 0–3 นาที: เปิดเรื่องและขอบเขต

**เปิดแอปที่หน้า Home และพูด:**

> “ปัญหาที่โปรเจกต์นี้แก้คือร้านอาหารต้องรับการจองโต๊ะ รับรายการอาหาร จัดคิวครัว และตรวจการชำระเงิน ซึ่งถ้าแยกกันหลายช่องทางจะติดตามสถานะยาก ผมทำแอปให้ลูกค้าจองโต๊ะหรือเลือกโต๊ะที่นั่งอยู่ ดูเมนู สั่งอาหาร ตรวจประวัติและชำระด้วย QR ส่วนแอดมินดูรายการจอง ครัว การชำระ และข้อมูลร้านจากหน้าจัดการ”

**ชี้แถบล่าง:** ลูกค้าใช้ Home, Menu, Booking, Profile ใน [HomeShell](/D:/Project_Main/flutter_application_1/lib/pages/home_shell.dart) และ [AppBottomNav](/D:/Project_Main/flutter_application_1/lib/widgets/app_bottom_nav.dart) ส่วนแอดมินใช้ 5 แท็บใน [AdminDashboardPage](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:524) หน้าต่างกันตาม role ที่ได้หลัง login

**ประโยคกันคำถาม:** “ระบบนี้เป็นโปรเจกต์ที่รันด้วย backend และ MariaDB ของเรา การสแกน PromptPay ใช้ payload มาตรฐาน แต่การยืนยันโอนยังเป็นหน้าที่แอดมิน ไม่ได้ต่อธนาคารอัตโนมัติ”

## 3–8 นาที: อธิบายโครงสร้างโปรแกรม

**วาด/เปิดแผนนี้:**

```text
Flutter widgets/pages → ApiService ส่ง HTTP + JSON → Express routes/server.js
        ↑                                             ↓
  models รับ JSON                         libs ตรวจเงื่อนไข/สิทธิ์
                                                      ↓
                                         models เขียน/อ่าน MariaDB
```

**พูด:**

> “ผมแยกเป็น 3 ชั้น เพราะหน้าจอต้องแสดงผลและรับการกด ส่วนกฎสำคัญ เช่น ใครมีสิทธิ์เปลี่ยนสถานะหรือยอดชำระเท่าไร ต้องอยู่ฝั่งเซิร์ฟเวอร์ การปิดปุ่มใน Flutter อย่างเดียวไม่พอ ผู้ใช้สามารถเรียก API เองได้”

**ชี้ไฟล์ตามลำดับ:** [main.dart](/D:/Project_Main/flutter_application_1/lib/main.dart) เรียก `runApp` และกำหนดหน้าเริ่ม; [api_service.dart](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:11) รวม URL, header และ HTTP; [server.js](/D:/Project_Main/my_app/server.js) รับ route `/api/...`; [db_pool.js](/D:/Project_Main/my_app/libs/db_pool.js) เปิด connection pool; `my_app/models/` รวม SQL ของแต่ละเรื่อง

**ยกตัวอย่าง 1 request:** “กดจองใน Flutter → `ApiService.createReservation` ส่ง POST `/api/reservations` → route ตรวจ token/วัน/เวลา → `models/reservation.js` ตรวจโต๊ะและ INSERT ใน transaction → ส่ง JSON reservation ID กลับ → Flutter เปิดขั้นสั่งอาหาร” ดู [ApiService.createReservation](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:199), [route จอง](/D:/Project_Main/my_app/server.js:1217), [reservation model](/D:/Project_Main/my_app/models/reservation.js)

**เหตุผลของโค้ดพื้นฐานที่ควรพูดได้:** `StatefulWidget` + `setState` ทำให้หน้าจอสร้างใหม่เมื่อ state เปลี่ยน; `async/await` รอ HTTP; `mounted` กันเรียก context หลังปิดหน้า; `dispose()` ปล่อย controller; `Navigator.push` เปิดหน้าถัดไป; `pushAndRemoveUntil` ล้างทางย้อนหลังจาก login/ยืนยันออร์เดอร์

## 8–13 นาที: บัญชีและสิทธิ์

**สาธิต:** หน้า Welcome → Sign up หรือ Login → Profile/Personal information แสดงจุดแก้ชื่อผู้ใช้และรูปโปรไฟล์

**พูด:**

> “หน้าสมัครตรวจข้อมูลเบื้องต้นเพื่อบอกผู้ใช้เร็ว เช่น username, รหัสผ่าน และเบอร์โทร แล้ว backend ตรวจซ้ำก่อน INSERT รหัสผ่านถูก hash ด้วย bcrypt ไม่เก็บ plaintext เมื่อ login สำเร็จ backend ส่ง token; ทุก API ที่ต้องล็อกอินตรวจ token และอ่านสถานะบัญชีจากฐานข้อมูล ส่วน route `/api/admin/...` ตรวจ role เพิ่ม จึงเปลี่ยน role ใน UI แล้วไม่ได้สิทธิ์แอดมิน”

**ชี้:** [login_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart), [signup_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart), [server login](/D:/Project_Main/my_app/server.js:158), [server register](/D:/Project_Main/my_app/server.js:254), [auth_token.js](/D:/Project_Main/my_app/libs/auth_token.js), [personal_information_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart)

**ย้ำ:** รูปโปรไฟล์เปลี่ยนจากหน้า Personal information; หน้า Profile เป็นทางเข้าและแสดงข้อมูล ไม่ใช่ปุ่มแก้รูปโดยตรง

## 13–21 นาที: จองโต๊ะ ปฏิทิน และประวัติ

**สาธิต:** เปิด “จองโต๊ะ” → ปฏิทิน → จำนวนคน → เวลา → โต๊ะ → ยืนยัน; จากนั้นเปิดแท็บ Booking และประวัติ

**พูด:**

> “สีแดงหมายถึงวันร้านปิด เช่น วันอาทิตย์หรือวันหยุดที่แอดมินบันทึก สีเขียวคือวันที่เปิดให้เลือกตามช่วงจอง สีเทาคือวันนอกช่วงหรือยังไม่เปิดให้จอง สีเขียวยังไม่ได้แปลว่าทุกโต๊ะว่าง เพราะจำนวนคนและเวลามีผล เมื่อเปลี่ยนวัน เวลา หรือจำนวนคน หน้าโหลดโต๊ะใหม่”

> “ตอนกดยืนยัน backend ตรวจซ้ำ เพราะระหว่างดูปฏิทินอาจมีคนอื่นจองโต๊ะเดียวกัน การตรวจและสร้างการจองใน transaction ลดปัญหา race condition วันที่จองกับวันที่มาใช้บริการแยกกันในข้อมูล ประวัติใช้การขอข้อมูลอีกแบบเพื่อรวมรายการสำเร็จและยกเลิก”

**ชี้:** [ReservationPage การเลือกวันและยืนยัน](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:126), [สถานะสีปฏิทิน](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1119), [กฎจอง](/D:/Project_Main/my_app/libs/booking_rules.js), [SQL การจอง](/D:/Project_Main/my_app/models/reservation.js), [BookingPage](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart), [ReservationHistoryPage](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart)

**คำตอบกรณีโต๊ะถูกแย่ง:** “หน้าจอเป็น snapshot ขณะโหลด เซิร์ฟเวอร์เป็นตัวตัดสินตอนยืนยัน หากชนกันให้โหลดโต๊ะใหม่และแจ้งลูกค้าเลือกโต๊ะอื่น”

## 21–29 นาที: เมนู ตัวเลือก และตะกร้า

**สาธิต:** เปิด Menu → หมวดข้าว → “ข้าวผัดกะเพรา” → ชี้ราคาเริ่มต้น → เลือกเนื้อ 2 ชนิด → ดูยอดรวม → เพิ่มตะกร้า

**พูด:**

> “เมนูในฐานข้อมูลตอนนี้ใช้ชื่อจานกลาง เช่น ข้าวผัดกะเพรา ไม่แยกชื่อเป็นหมู ไก่ กุ้ง ลูกค้าเลือกในหัวข้อ ‘เนื้อ’ ซึ่งต้องเลือกอย่างน้อย 1 ชนิด ผสมได้สูงสุด 5 ชนิด ราคาจานพื้นฐานไม่รวมเนื้อ และราคาแต่ละเนื้อบวกเพิ่มตามที่เลือก การ์ดแสดง ‘ราคาเริ่มต้น’ โดยรวมเนื้อที่ถูกที่สุดแล้ว เพื่อไม่ให้ลูกค้าเข้าใจผิดว่าจ่ายได้แค่ราคาฐาน”

> “หน้าจอจำตัวเลือกด้วย ID, แสดง ChoiceChip, ปิดตัวเลือกที่หมด และคำนวณยอดชั่วคราวให้เห็นเร็ว แต่ยอดจริงตอนสร้างรายการอาหาร backend โหลดราคาเมนูและตัวเลือกจากฐานข้อมูลใหม่ จึงไม่เชื่อราคาที่ client ส่งมา”

**ชี้:** [FoodMenuPage](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart), [Food.fromJson/ราคาเริ่มต้น](/D:/Project_Main/flutter_application_1/lib/models/food.dart:31), [FoodDetailPage ตัวเลือก/ราคา](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:54), [CartService](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart), [menu_options.js](/D:/Project_Main/my_app/libs/menu_options.js:26), [route order-details](/D:/Project_Main/my_app/server.js:872), [สคริปต์ปรับเมนู](/D:/Project_Main/my_app/scripts/seed_common_menus.js)

**ตอบเรื่องเมนูที่ร้านไม่มี:** ไม่มีข้าวต้ม ผัดไทย และอาหารน้ำอื่นที่ระบุให้เอาออก; ก๋วยเตี๋ยวน้ำกับเกาเหลาเป็นข้อยกเว้น สคริปต์เมนูทำครั้งเดียว มี marker กันรันซ้ำทับการแก้ของแอดมิน และสำรองข้อมูลก่อนปรับ รายการเดิมที่มีออร์เดอร์อ้างถึงจะเก็บไว้แต่ปิดขายแทนการลบ

## 29–35 นาที: ออร์เดอร์กับครัว

**สาธิต:** หน้า Cart → ยืนยันออร์เดอร์; สลับแอดมินแท็บ “การจอง” และ “ครัว” ชี้หัวข้อวันที่ การ์ดโต๊ะ รายการอาหาร และปุ่มเปลี่ยนสถานะ

**พูด:**

> “หัวออร์เดอร์เก็บเจ้าของ โต๊ะ/การจอง และสถานะรวม ส่วน `order_detail` เก็บแต่ละจาน จำนวน ราคา ณ วันที่สั่ง ตัวเลือกที่เลือก และสถานะครัว จึงเป็นความสัมพันธ์หนึ่งออร์เดอร์ต่อหลายรายการ ครัวเปลี่ยนสถานะรายจาน เมื่อทุกจานเสร็จ ระบบจึงเปลี่ยนออร์เดอร์ไปขั้นรอชำระเงิน”

**ชี้:** [cart_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart), [payment_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart), [order.js](/D:/Project_Main/my_app/models/order.js), [order_detail.js](/D:/Project_Main/my_app/models/order_detail.js), [Admin reservations](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:557), [Admin kitchen](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:647)

**อธิบายชื่อที่ชวนสับสน:** `payment_page.dart` ใน flow นี้เป็นหน้ายืนยันรายการและแสดงผลสำเร็จ ชำระเงินจริงอยู่ `payment_qr_page.dart` หลังอาหารพร้อมจ่าย ชื่อไฟล์ควรปรับในอนาคต

## 35–41 นาที: QR ชำระเงินและรายงานยอดขาย

**สาธิต:** ประวัติออร์เดอร์ → QR → ชี้จำนวนเงิน/PromptPay ID/แนบสลิป; แอดมินแท็บชำระเงินและภาพรวม

**พูด:**

> “Backend รวมยอดจาก `order_detail` เป็นจำนวน×ราคาที่บันทึกจริง แล้วสร้าง payload PromptPay พร้อมยอด Flutter ใช้ `qr_flutter` วาดภาพ QR จาก payload ที่ได้รับ หน้าจอแสดงเบอร์หรือเลขบัญชี PromptPay ให้ลูกค้าตรวจได้ การแนบสลิปส่งหลักฐานเข้าระบบ แต่ยังไม่ใช่การยืนยันโอน แอดมินต้องตรวจแล้วกดอนุมัติหรือปฏิเสธ”

> “ยอดขายในภาพรวมใช้เฉพาะ payment ที่อนุมัติแล้ว ส่วนจำนวนจานต่อเมนูดู order detail ของออร์เดอร์ที่จ่ายแล้ว จึงไม่เอาออร์เดอร์ค้างจ่ายมาปน”

**ชี้:** [PaymentQrPage](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart), [route สร้าง QR](/D:/Project_Main/my_app/server.js:1677), [promptpay.js](/D:/Project_Main/my_app/libs/promptpay.js), [payment.js](/D:/Project_Main/my_app/models/payment.js), [route ภาพรวม](/D:/Project_Main/my_app/server.js:1752), [Admin payments](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:673)

## 41–46 นาที: การแจ้งเตือน

**สาธิต:** หน้า Profile สวิตช์แจ้งเตือน → กล่องแจ้งเตือน → ชี้กระดิ่งส้ม/เทาและเวลาข้อความ

**พูด:**

> “เมื่อเกิดข้อความ ระบบบันทึกประวัติไว้เสมอ พร้อม snapshot ว่าตอนเกิดข้อความผู้ใช้เปิดหรือปิดการแจ้งเตือน ถ้าเปิด ไอคอนของรายการนั้นเป็นสีส้ม ถ้าปิดเป็นสีเทา เปลี่ยนสวิตช์ภายหลังไม่ย้อนเปลี่ยนสีเก่า กระดิ่งในรายการใช้แสดงสถานะเท่านั้น กดไม่ได้”

> “การเตือนจองโต๊ะทำที่ backend โดย worker ตรวจเป็นรอบ มีช่วงล่วงหน้า 1 ชั่วโมงและ 10 นาที และมี key กันส่งซ้ำ ส่วน push ไปโทรศัพท์ต้องตั้ง Firebase/FCM ให้สมบูรณ์ ถ้ายังไม่ตั้งค่า ประวัติในแอปยังบันทึกได้”

**ชี้:** [ProfilePage](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart), [NotificationInboxPage](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart), [notifications.js](/D:/Project_Main/my_app/libs/notifications.js), [reservation_reminders.js](/D:/Project_Main/my_app/libs/reservation_reminders.js), [notification_service.dart](/D:/Project_Main/flutter_application_1/lib/services/notification_service.dart)

## 46–50 นาที: จัดการร้านและข้อจำกัด

**สาธิต:** แอดมินแท็บจัดการ ชี้รูป/ข้อความแบนเนอร์ วันหยุด ลูกค้า เมนู โต๊ะ และ PromptPay

**พูด:**

> “แอดมินแก้รูปและข้อความแบนเนอร์ที่ Home ดึงผ่าน API ได้ กำหนดวันหยุดเพื่อให้การจองปิดตามจริง จัดการเมนูและตัวเลือกได้ รวมถึงเปลี่ยนรูปเมนู ปิดขาย และจัดการโต๊ะ สิทธิ์ทุก route ฝั่งแอดมินถูกตรวจที่ server ไม่พึ่งการซ่อนหน้า”

**ชี้:** [AdminDashboardPage](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:701), [AdminMenuOptionsDialog](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart), [route เมนูแอดมิน](/D:/Project_Main/my_app/server.js:2047), [route แบนเนอร์](/D:/Project_Main/my_app/server.js:603)

**ปิดก่อนคำถาม:** “สิ่งที่ควรปรับก่อนใช้งานจริงคือรวมการสร้างหัวออร์เดอร์และรายการอาหารไว้ใน transaction เดียว ตั้ง Firebase และ HTTPS สำหรับ deploy จริง เพิ่มการทดสอบ flow ข้ามระบบ และถ้าต้องการตรวจโอนอัตโนมัติต้องเชื่อมบริการธนาคารหรือผู้ให้บริการชำระเงิน”

---

## 50–60 นาที: วิธีตอบคำถามแบบชี้จอ

ใช้สูตร 5 ประโยคเสมอ: **นี่คืออะไร → UI อยู่ไฟล์ไหน → กดแล้วเรียกฟังก์ชันใด → API/ฐานข้อมูลใด → เงื่อนไขและเหตุผล**

ตัวอย่างเมื่อชี้ปุ่ม “ยืนยันการจอง”:

> “ปุ่มนี้อยู่ใน `reservation_page.dart` และเรียก `_confirmReservation` เมื่อวัน เวลา คน และโต๊ะครบ Flutter เรียก `ApiService.createReservation` ส่ง POST ไป `/api/reservations` ใน `server.js` route ตรวจสิทธิ์และวันเวลาซ้ำ แล้ว `models/reservation.js` ใช้ transaction ตรวจโต๊ะก่อน INSERT เพราะการเห็นโต๊ะว่างบนหน้าจอไม่รับประกันว่าไม่มีคนจองแทรกระหว่างนั้น”

ตัวอย่างเมื่อชี้ราคาเมนู:

> “ราคาบนการ์ดอ่านจาก `Food.startingPrice` ซึ่งรวมราคาตัวเลือกที่ต้องเลือกที่ถูกที่สุด ส่วนในหน้ารายละเอียด `FoodDetailPage` คิดราคาฐานบวกตัวเลือกที่กดสำหรับแสดงทันที แต่ตอนส่งออร์เดอร์ backend คำนวณใหม่จากราคาใน DB และ `menu_options.js` เพื่อกันการแก้ราคาจากฝั่งลูกค้า”

ตัวอย่างเมื่อชี้กระดิ่งสีเทา:

> “รายการนี้บันทึกตอนผู้ใช้ปิดแจ้งเตือน ค่า `notifications_enabled` ถูกเก็บไว้กับข้อความ จึงเป็นสีเทา ถึงเปิดสวิตช์วันนี้ก็ไม่เปลี่ยนสีของข้อความเก่า ไอคอนนี้ไม่มีการกดเพื่อเปลี่ยนสถานะ”

## ธนาคารคำถามและแนวตอบสั้น

### โครงสร้างและ Flutter

1. **เริ่มทำงานที่ไฟล์ไหน?** `main.dart` เรียก `runApp` และเริ่มที่ Splash; Splash ไป Welcome แล้ว Login/Sign up
2. **ทำไมใช้ Flutter?** ใช้ widget ชุดเดียวทำ UI สำหรับเว็บและ Android; API base URL ต้องต่างกันตามสภาพแวดล้อม โดย emulator ติดต่อ host ผ่าน `10.0.2.2`
3. **`StatefulWidget` ใช้ตอนไหน?** เมื่อหน้าเก็บข้อมูลที่เปลี่ยน เช่น วันจอง loading จำนวนคน; `setState` ทำให้ build ใหม่
4. **`IndexedStack` ใน HomeShell มีไว้ทำไม?** เปลี่ยนแท็บแต่รักษา state ของหน้าที่เปิดไว้ ข้อแลกเปลี่ยนคือเก็บ widget หลายหน้าใน tree
5. **ทำไม `mounted` หลัง `await`?** HTTP อาจตอบหลังออกจากหน้า ต้องกันการอัปเดต widget/context ที่ถูก dispose แล้ว
6. **`FutureBuilder` ต่างจาก `setState` อย่างไร?** `FutureBuilder` แสดง waiting/error/data จาก Future; `setState` เปลี่ยน state ที่หน้าเก็บเอง
7. **รูปหน้าแรกที่แอดมินเปลี่ยนอยู่ตรงไหน?** Home hero โหลด `/restaurant/banner`; Splash ยังใช้ asset คงที่ ถ้าโหลดไม่ได้ใช้รูปสำรอง

### บัญชีและความปลอดภัย

8. **ทำไม hash รหัสผ่าน?** หาก DB รั่วจะไม่เห็นรหัสจริงทันที; login ใช้ `bcrypt.compare`
9. **token คืออะไร?** หลักฐานการล็อกอินที่ server ลงลายเซ็น; server ตรวจลายเซ็น/วันหมดอายุและตรวจบัญชีจริงอีกครั้ง ไม่ใช่การเข้ารหัสข้อมูลลับ
10. **แก้ role ใน client เป็น admin ได้ไหม?** ไม่ได้ route `/api/admin` ตรวจสิทธิ์บน backend
11. **ป้องกัน SQL injection อย่างไร?** ใช้ placeholder `?` ของ mysql2 แทนต่อ SQL จาก input โดยตรง
12. **ปิดบัญชีแล้ว token เก่าทำงานไหม?** route ตรวจสถานะบัญชีจาก DB; บัญชีถูกปิด/ลบจะถูกปฏิเสธ
13. **รูปโปรไฟล์ทำไมไม่แก้บนหน้า Profile?** หน้า Profile เป็นทางนำทาง; การแก้ไฟล์อยู่ Personal information ทำให้การแสดงกับการแก้ข้อมูลแยกกันชัด

### จองและเวลา

14. **สีแดง/เขียว/เทาคืออะไร?** ปิดร้าน/เปิดให้เลือกตามช่วง/นอกช่วงหรือยังไม่เปิดให้จอง; สีเขียวไม่รับประกันว่ามีโต๊ะว่าง
15. **ทำไมต้องตรวจจองใน server ซ้ำ?** UI เก่าได้หรือถูกเรียก API ตรง จึงต้องตรวจสิทธิ์ วัน เวลา และโต๊ะในจุดที่บันทึกจริง
16. **ทำไมใช้ transaction และ `FOR UPDATE`?** กันสองคำขอจองโต๊ะเดียวกันพร้อมกัน โดยให้การอ่านและสร้างอยู่ในช่วงล็อกเดียว
17. **ประวัติจองทำไมมีรายการยกเลิก?** ประวัติต้องอธิบายว่าเคยจองเมื่อไรและผลเป็นอย่างไร; endpoint history ไม่กรองเฉพาะรายการ active
18. **ทำไมวันใน DB เป็น ค.ศ. แต่ UI แสดง พ.ศ.?** ISO date ค.ศ. เหมาะกับ SQL/คำนวณ; แปลงปีเฉพาะตอนแสดง
19. **ทำไมแอดมินกำหนดวันหยุดแล้วลูกค้าเลือกไม่ได้?** หน้าโหลดวันหยุดเพื่อแสดงสี ส่วน server ตรวจอีกครั้งก่อน INSERT จึงไม่พึ่งสีอย่างเดียว

### เมนูและออร์เดอร์

20. **เลือกเนื้อได้ 5 แบบจริงหรือ?** `option_groups_json` ของเมนูข้าวมี `required:true` และ `max_select:5`; Flutter จำกัดจำนวน chip, backend `resolveMenuSelections` ตรวจซ้ำ
21. **เลือก 5 ชนิดแล้วคิดเงินอย่างไร?** ราคาจานพื้นฐาน + ผลรวม `extra_price` ของทุกเนื้อ/ตัวเลือกที่เลือก จากนั้นคูณจำนวนจาน
22. **ทำไมชื่ออาหารไม่มีคำว่าหมู/ไก่?** ลดเมนูชื่อซ้ำ และให้เลือกผสมโปรตีนได้จากจานกลางเดียว; เมนูข้าวขึ้นต้น “ข้าว” เพื่อหาและจัดหมวดง่าย
23. **ตัวเลือกหมดแล้วยังสั่งได้ไหม?** Flutter ปิด chip; backend ตรวจ `available`/`sold_out` ซ้ำ ถ้าตัวเลือกจำเป็นทั้งหมดหมด จะสั่งไม่สำเร็จ
24. **ทำไมเก็บ `selected_options` ใน order detail?** เป็น snapshot ของตัวเลือกและราคาเพิ่ม ณ ตอนสั่ง เพื่อให้ครัว/ประวัติอ่านย้อนหลังแม้แอดมินแก้เมนูภายหลัง
25. **แก้ราคาจาก HTTP เพื่อสั่งถูกลงได้ไหม?** backend โหลดราคาเมนูและตัวเลือกจาก DB แล้วคำนวณ ไม่เชื่อราคาสุดท้ายจาก client
26. **`order` กับ `order_detail` ต่างกัน?** หัวออร์เดอร์เก็บเจ้าของ/โต๊ะ/สถานะรวม; detail เก็บแต่ละจาน/จำนวน/ราคา/ตัวเลือก/สถานะครัว
27. **แบบจองกับ walk-in เข้าตารางไหน?** ใช้ order เดียวกัน แต่แหล่งที่มาคนละชนิด (`reservation_id` กับโต๊ะ/รอบ walk-in) และตรวจสิทธิ์/โต๊ะตามกรณี
28. **ทำไม QR ยังไม่ขึ้นทันทีหลังสั่ง?** ต้องให้ครัวรับและทำรายการครบจนสถานะรอชำระ จึงใช้ยอดรวมสุดท้าย
29. **การเพิ่มเมนูชุดใหม่ทำซ้ำได้ไหม?** สคริปต์ seed มี marker `a_la_carte_v2` จึงไม่ทับการแก้ของแอดมินเมื่อรันซ้ำ และสำรองแค็ตตาล็อกก่อนเปลี่ยน

### จ่ายเงิน สถิติ และแจ้งเตือน

30. **QR สร้างจากภาพที่แอดมินอัปโหลดหรือไม่?** ไม่ใช่ แอปวาด QR จาก PromptPay payload ที่ server สร้างด้วย ID ผู้รับและยอดเงินจริง; แอดมินตั้ง ID ผู้รับได้
31. **แนบสลิปแปลว่าจ่ายสำเร็จหรือยัง?** ยัง ต้องรอแอดมินตรวจและอนุมัติ ไม่มีการเชื่อม bank API ตรวจยอดอัตโนมัติ
32. **ยอดขายรวมมาจากอะไร?** payment ที่อนุมัติแล้ว; ยอดรายเมนูอาศัยรายการอาหารของออร์เดอร์ที่ชำระแล้ว
33. **ทำไมกระดิ่งบางรายการสีเทา?** บันทึก preference ตอนข้อความเกิด ไม่ใช่สวิตช์ปัจจุบัน; กดกระดิ่งใน inbox ไม่ได้
34. **ถ้าปิด push จะยังเห็นข้อความไหม?** ยังเห็นใน inbox เพราะบันทึก DB; FCM เป็นช่องทางส่งออกไปอุปกรณ์เพิ่มเติม
35. **เตือนก่อน 1 ชั่วโมงและ 10 นาทีไม่ซ้ำได้อย่างไร?** worker ตรวจรอบ ๆ เวลา และบันทึก unique delivery key สำหรับแต่ละการจอง/ช่วงเตือน

### ข้อจำกัดและแนวคิดปรับปรุง

36. **ถ้าสร้างหัวออร์เดอร์แล้วรายการที่สามล้มเหลว?** ปัจจุบันเป็นหลาย HTTP request และมีการพยายามยกเลิก แต่ยังไม่ atomic ทั้งชุด; ควรมี endpoint เดียวและ transaction เดียว
37. **ส่งขึ้นใช้งานจริงได้เลยหรือ?** ต้องตั้ง server/DB/HTTPS, Firebase ถ้าใช้ push, signing Android, backup, logging และตรวจ flow บนอุปกรณ์จริง
38. **ระบบตรวจเงินโอนเองหรือ?** ไม่; QR สำหรับชำระและสลิปสำหรับให้แอดมินตรวจ หากต้องการ auto verification ต้องใช้ผู้ให้บริการชำระเงินที่รองรับ
39. **ถ้าแอปไม่มีเน็ตจะสั่งได้ไหม?** ระบบปัจจุบันพึ่ง API และ DB; ตะกร้าชั่วคราวอยู่ในหน่วยความจำ แต่การยืนยันสั่งต้องออนไลน์
40. **จุดที่ภูมิใจและจุดที่จะปรับก่อนคืออะไร?** เส้นทางจอง→สั่ง→ครัว→จ่ายเชื่อมกันครบและ server คุมราคา/สิทธิ์; ปรับอันดับแรกคือ atomic order+items, ทดสอบข้ามระบบ และ config สำหรับ deploy จริง

## ถ้าตอบไม่ได้ในทันที

พูดว่า “ขอเปิดฟังก์ชันที่รับปุ่มนี้ก่อนครับ” แล้วไล่ UI → callback → `ApiService` → route → model/SQL ใช้ `rg` หรือค้นชื่อฟังก์ชันใน IDE อย่าเดาว่าทดสอบแล้ว ปลอดภัย 100% หรือธนาคารยืนยันแล้ว หากโค้ดไม่ได้ทำ

## บทปิด 30 วินาที

> “สรุปโปรเจกต์นี้ทำให้การจองโต๊ะ สั่งอาหาร ครัว การชำระ และการจัดการร้านอยู่ใน flow เดียว ผมออกแบบให้ Flutter จัดการ UI, API ตรวจสิทธิ์และกฎธุรกิจ, MariaDB เก็บข้อมูลถาวร จุดสำคัญคือการตรวจซ้ำที่เซิร์ฟเวอร์ทั้งการจอง ราคาอาหาร และการจ่ายเงิน ผมทราบข้อจำกัดปัจจุบันและมีลำดับปรับปรุงก่อนนำไปใช้จริงครับ”
