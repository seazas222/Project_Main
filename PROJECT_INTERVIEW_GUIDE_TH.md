# คู่มืออ่านโค้ดและเตรียมสัมภาษณ์โปรเจกต์ Restaurant App

> อ้างอิงโค้ดใน `D:\Project_Main` ณ วันที่ 14 ตุลาคม 2026 คู่มือนี้อธิบาย **สิ่งที่โค้ดทำจริง** แยกจากแนวคิดหรือสิ่งที่ยังไม่ได้ตั้งค่า ใช้เปิดไฟล์ตามลิงก์และฝึกเล่าเป็นภาษาของตนเอง ไม่จำเป็นต้องท่องชื่อฟังก์ชันทุกตัว แต่ต้องอธิบายเส้นทางข้อมูลและเหตุผลของเงื่อนไขสำคัญให้ได้

ถ้าอาจารย์ชี้องค์ประกอบบนหน้าจอ ให้เปิด [แผนที่ทุกหน้าจอแบบชี้ตรงไหนก็ตอบได้](/D:/Project_Main/APP_SCREEN_WALKTHROUGH_TH.md) คู่กัน; เอกสารนี้เน้นสถาปัตยกรรม API SQL เหตุผลของโค้ด และคำถามสอบ.

## สารบัญและวิธีอ่าน

1. อ่านภาพรวมและแผนผัง 10 นาที
2. เปิดตารางไฟล์และไล่ UI ทุกหน้า 20 นาที
3. อ่านเส้นทางสมัครสมาชิก → จอง → สั่ง → จ่าย → แอดมิน 25 นาที
4. ทบทวนฐานข้อมูล ความปลอดภัย ข้อจำกัด และคำถามอาจารย์ 20 นาที

สำหรับการนำเสนอ 1 ชั่วโมง ใช้หัวข้อ “ลำดับพูด” ตอนท้ายเป็นโครง แล้วเปิดโค้ดจริงประกอบ ตัวเลขหลังชื่อไฟล์ เช่น `:63` คือบรรทัดเริ่มต้นของส่วนที่กล่าวถึง บรรทัดอาจเลื่อนหากมีการแก้โค้ดภายหลัง

---

## 1. โปรเจกต์นี้คืออะไร และข้อมูลไหลอย่างไร

ระบบมี 3 ชั้นหลัก:

```text
ลูกค้า/แอดมินใน Flutter
  ├─ pages/       หน้าจอ รับการกด/กรอกข้อมูล และแสดงสถานะ
  ├─ models/      แปลง JSON ที่ API ส่งมาเป็นวัตถุ Dart
  └─ services/    เก็บผู้ใช้และตะกร้าชั่วคราว + ส่ง HTTP
                       │ JSON ผ่าน /api และ Bearer token
                       ▼
Node.js / Express ใน my_app/server.js
  ├─ ตรวจรูปแบบข้อมูล สิทธิ์ และกฎธุรกิจ
  ├─ libs/        token, กฎเวลา, ตัวเลือกอาหาร, PromptPay, แจ้งเตือน
  └─ models/      คำสั่ง SQL กับ MariaDB/MySQL
                       │
                       ▼
ฐานข้อมูล restaurant_db + ไฟล์ภาพใน my_app/storage
```

**เหตุผลที่แยกชั้น**: Flutter ควรรับผิดชอบประสบการณ์ผู้ใช้และส่งคำขอ, API เป็นผู้ตัดสินสิทธิ์/ความถูกต้อง, ฐานข้อมูลเก็บข้อมูลข้ามการเปิดแอป การซ่อนปุ่มใน Flutter ไม่ใช่การป้องกัน เพราะคนอื่นยิง HTTP เองได้ จึงต้องตรวจซ้ำในเซิร์ฟเวอร์

**คำอธิบายสั้นสำหรับเริ่มสอบ**: “เป็นแอปร้านอาหารที่ลูกค้าสมัครสมาชิก จองโต๊ะ เลือกเมนูและตัวเลือกย่อย สั่งอาหาร ดูสถานะ ชำระผ่าน QR PromptPay พร้อมแนบสลิป ส่วนผู้ดูแลจัดการการจอง ครัว สลิป เมนู โต๊ะ วันหยุดและรายงานยอดขาย Flutter คุยกับ Express ผ่าน REST API โดย Express ตรวจสิทธิ์และใช้ MariaDB เก็บข้อมูล”

### สิ่งที่ต้องแยกคำให้ชัด

| คำ | ความหมายในโค้ดนี้ | อยู่ที่ไหน |
|---|---|---|
| `reservation` | การจองโต๊ะล่วงหน้าตามวัน เวลา จำนวนคน | Flutter `ReservationPage`; SQL ตาราง `reservation` |
| `restaurant_table_session` | รอบการใช้งานโต๊ะของลูกค้า walk-in; แอดมินปิดรอบหลังจบ | `models/table.js`, `models/order.js` |
| `order` | หัวออร์เดอร์ ผูกลูกค้าและอาจผูกการจองหรือโต๊ะ walk-in | `models/order.js` |
| `order_detail` | เมนูแต่ละรายการในออร์เดอร์ รวมจำนวน ราคา และตัวเลือก | `models/order_detail.js` |
| `payment` | หลักฐานและผลตรวจการชำระเงินจริง | `models/payment.js` |
| `customer_notification` | ประวัติข้อความแจ้งเตือนในระบบ | `libs/notifications.js` |
| FCM push | แจ้งเตือนออกไปที่อุปกรณ์ (ต้องตั้ง Firebase) | Flutter `notification_service.dart`, Node `firebase_admin.js` |

---

## 2. จุดเริ่มต้น การตั้งค่า และไวยากรณ์พื้นฐาน

### ไฟล์ตั้งค่า

| ไฟล์ | หน้าที่และเหตุผล |
|---|---|
| [pubspec.yaml](/D:/Project_Main/flutter_application_1/pubspec.yaml) | ชื่อ/เวอร์ชันแอป, Dart SDK `^3.12.2`, dependencies `http`, `firebase_core`, `firebase_messaging`, `qr_flutter`, `image_picker`, รายชื่อรูปใน `assets`. ถ้าไม่ประกาศ asset, `Image.asset` จะหาไฟล์ไม่พบ |
| [package.json](/D:/Project_Main/my_app/package.json) | Node >=22, คำสั่ง `npm run start`, `npm test`, `npm run create-admin` และแพ็กเกจ `express`, `mysql2`, `bcrypt`, `cors`, `firebase-admin` |
| [README_RUN_TH.md](/D:/Project_Main/my_app/README_RUN_TH.md) | ลำดับเปิด MariaDB, รัน migration, ตั้ง `.env`, เปิด backend แล้วรัน Flutter; ควรอธิบายว่ามี **ฐานข้อมูลเดิม** ก่อน migration |
| [main.dart:8](/D:/Project_Main/flutter_application_1/lib/main.dart:8) | `main()` เรียก `WidgetsFlutterBinding.ensureInitialized()` ก่อน `await`/plugin, พยายามตั้ง Firebase แล้ว `runApp` |
| [firebase_options.dart](/D:/Project_Main/flutter_application_1/lib/firebase_options.dart) | ปัจจุบันเป็นตัวอย่างที่โยน `UnsupportedError` จนกว่าจะใช้ FlutterFire สร้างค่าจริง; `try/catch` ใน `main` ทำให้แอปเปิดได้แม้ไม่มี push |
| [app_theme.dart](/D:/Project_Main/flutter_application_1/lib/core/app_theme.dart) | สีและ `ThemeData` รวมศูนย์ เช่น สีส้ม สีพื้นหลัง รูปทรงปุ่มและช่องกรอก; ปรับครั้งเดียวมีผลหลายหน้า |
| [db_pool.js:3](/D:/Project_Main/my_app/libs/db_pool.js:3) | `mysql2/promise` pool, ใช้ connection ซ้ำ จำกัดพร้อมกัน, timezone +07:00 และส่ง date เป็น string เพื่อลดปัญหาแปลงเวลา |

`API_BASE_URL` ถูกอ่านที่ [api_service.dart:12](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:12) ผ่าน `String.fromEnvironment`: ถ้าส่ง `--dart-define=API_BASE_URL=...` จะใช้ค่าที่กำหนด; ถ้าไม่ส่ง เว็บใช้ `http://localhost:3000/api`, Android emulator ใช้ `http://10.0.2.2:3000/api`. `10.0.2.2` คือทางจาก emulator ไปเครื่อง host; มือถือจริงต้องใช้ IP ของคอมพิวเตอร์ที่เปิด backend

### อ่าน Dart/Flutter ให้เข้าใจ

| รูปแบบ | ความหมาย | ตัวอย่างจากโปรเจกต์ |
|---|---|---|
| `StatelessWidget` | หน้าที่ผลแสดงไม่ต้องเก็บ state ของตัวเอง | [WelcomePage:8](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:8) |
| `StatefulWidget` + `State` | หน้าเก็บค่าที่เปลี่ยน เช่น วันที่ที่เลือก/loading; `setState` สั่งสร้าง UI ใหม่ | [ReservationPage:10](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:10) |
| `initState` | ทำครั้งแรกเมื่อ widget เริ่ม เช่น โหลดข้อมูล | [PaymentQrPage:21](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:21) |
| `dispose` | ปิด `TextEditingController`/resource เมื่อหน้าเลิกใช้ ป้องกันค้าง | [LoginPage:26](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:26) |
| `Future<T>`, `async`, `await` | ผลที่จะได้ภายหลัง เช่น HTTP/ฐานข้อมูล; `await` รอให้เสร็จก่อนทำขั้นถัดไป | [PaymentPage:73](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:73) |
| `mounted` | ตรวจว่าหน้ายังอยู่ก่อน `setState`/ใช้ `context` หลัง `await` | [LoginPage:48](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:48) |
| `FutureBuilder` | ผูก UI กับสถานะ loading/success/error ของ Future | [PaymentQrPage:55](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:55) |
| `Navigator.push` | เปิดหน้าใหม่และยังย้อนกลับได้ | [WelcomePage:58](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:58) |
| `pushReplacement` / `pushAndRemoveUntil` | แทนหน้าปัจจุบัน / ล้าง stack เช่น ล็อกอินแล้วกด Back ไม่กลับไป login | [SplashPage:14](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart:14), [LoginPage:58](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:58) |
| `ChangeNotifier` | เก็บ state ร่วมและแจ้งผู้ฟังเมื่อเปลี่ยน | [CartService:7](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart:7) |
| `jsonEncode`/`jsonDecode` | แปลง Map ↔ JSON สำหรับ HTTP | [ApiService:31](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:31) |
| `?`, `??`, `!` | ค่าอาจ null, ค่า fallback, ยืนยันว่าไม่ null ตามลำดับ | [Food.fromJson](/D:/Project_Main/flutter_application_1/lib/models/food.dart) |
| `if (!mounted) return` | กันตอบ HTTP กลับมาหลังผู้ใช้ปิดหน้า | หลายหน้า |

**ตัวอย่างอธิบายโค้ดจริง**: ใน [ApiService._headers:22](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:22), `if (token != null && token.isNotEmpty)` ใส่ `Authorization: Bearer ...` เฉพาะเมื่อมี token; endpoint ที่ต้องล็อกอินจะตรวจ token ใน Node ส่วน endpoint สาธารณะยังเรียกได้โดยไม่มี token. ใน [ApiService.login:31](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:31), ส่ง JSON `username/password`, ตรวจรหัส HTTP 2xx แล้วแปลง `data` เป็น `User`; เมื่อผิดพลาดโยน `Exception` ให้หน้าแสดง `SnackBar`.

---

## 3. แผนที่ไฟล์ Flutter: UI ไหนอยู่ไฟล์ไหน

### จุดเข้า ระบบนำทาง และหน้าบัญชี

| หน้าจอ/ส่วน | ไฟล์และจุดสำคัญ | เชื่อมกับอะไร และทำไม |
|---|---|---|
| เริ่มแอป | [main.dart:8](/D:/Project_Main/flutter_application_1/lib/main.dart:8) | ตั้ง Flutter/Firebase, ธีม, `home: SplashPage` |
| หน้าเปิด | [splash_page.dart:5](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart:5) | พื้นหลัง asset + แตะเพื่อไป Welcome; **ไม่ได้ข้ามอัตโนมัติ** |
| ต้อนรับ | [welcome_page.dart:7](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:7) | ปุ่มไป Login/SignUp; UI ยังมีข้อความอังกฤษบางส่วน |
| ล็อกอิน | [login_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:11), [_login:32](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:32) | `ApiService.login` → `CurrentUserService.setUser` → ลงทะเบียน push ถ้าทำได้ → `roleId==1` ไป AdminDashboard มิฉะนั้น HomeShell |
| สมัครสมาชิก | [signup_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:11), [_signUp:41](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:41) | ตรวจช่องว่าง/รหัสยืนยัน/เบอร์ 10 หลักเบื้องต้น, API ตรวจละเอียดซ้ำ, สมัครแล้วเข้า HomeShell |
| กรอบ 4 แท็บลูกค้า | [home_shell.dart:15](/D:/Project_Main/flutter_application_1/lib/pages/home_shell.dart:15) | `IndexedStack` เก็บ state ของ Home/Menu/Booking/Profile เมื่อสลับแท็บ; [app_bottom_nav.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_bottom_nav.dart) ส่ง index กลับด้วย callback |
| หน้าหลัก | [home_page.dart:16](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:16), [hero:569](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:569) | โหลดภาพ/ข้อความแบนเนอร์, เมนู, การจองล่าสุด; ปุ่มไปจอง/เมนู/เลือกโต๊ะ walk-in. ภาพ fallback เป็น asset |
| โปรไฟล์ | [profile_page.dart:16](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:16) | `AnimatedBuilder` ฟัง `CurrentUserService`; เปิดหน้าข้อมูลส่วนตัว ประวัติ การแจ้งเตือน สถิติ; switch แจ้งเตือนที่ [236](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:236); logout ล้างผู้ใช้ในหน่วยความจำ |
| ข้อมูลส่วนตัว | [personal_information_page.dart:10](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart:10), [รูป:60](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart:60), [บันทึก:98](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart:98) | แก้ username/fullname/phone/email ผ่าน PUT `/users/:id`, เลือกรูปด้วย `image_picker` และส่ง base64; จำกัดรูปฝั่งแอป 3 MB |

### จองโต๊ะ

| หน้าจอ/ส่วน | ไฟล์และจุดสำคัญ | เชื่อมกับอะไร และเงื่อนไข |
|---|---|---|
| หน้าจองใหม่ | [reservation_page.dart:10](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:10), [โหลดโต๊ะ:69](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:69), [ยืนยัน:221](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:221) | เลือกวัน/เวลา/จำนวนคน/โต๊ะ; ทุกครั้งที่เกณฑ์เปลี่ยน โหลด `/availability`; ส่ง POST `/reservations`; สำเร็จเปิดหน้าเมนูพร้อม reservationId |
| ปฏิทินจอง | [reservation_page.dart:1046](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1046), [สถานะสี:1120](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1120) | ดึง `/restaurant/holidays`; อาทิตย์/วันหยุดแดง; วันในช่วงจองที่ยังเปิดเขียว; นอกช่วง/ยังไม่กำหนดเทา; กดได้เฉพาะเขียว. สีเขียวบอกวันตามกฎร้าน **ไม่ได้รับประกันว่ามีโต๊ะว่าง** ต้องโหลด availability ต่อ |
| จำนวนผู้จอง | [reservation_page.dart:997](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:997) | ปุ่มเพิ่ม/ลดใน UI จำกัด 1–8 คน; backend ตรวจอย่างน้อย 1 และเทียบความจุโต๊ะ |
| รายการจองปัจจุบัน | [booking_page.dart:12](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:12), [โหลด:35](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:35) | GET `/users/:id/reservations` เฉพาะสถานะยัง active (1,4); กดยกเลิกเรียก API ตามกฎล่วงหน้า 1 ชม. |
| รายละเอียดการจอง | [reservation_detail_page.dart:7](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart:7) | GET `/reservations/:id`; เซิร์ฟเวอร์ตรวจเจ้าของ/แอดมินก่อนส่งรายละเอียด |
| ประวัติการจอง | [reservation_history_page.dart:9](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:9), [โหลด:27](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:27) | เรียกเมธอดชื่อ `getCompletedReservationsByUserId` แต่จริง ๆ ใช้ `?view=history` และดึง **ทุกสถานะ** รวมยืนยัน ยกเลิก มาใช้บริการ และรอ; แสดงวันที่/เวลา/โต๊ะ/ผล |

### เมนู ตะกร้า ออร์เดอร์ และชำระเงิน

| หน้าจอ/ส่วน | ไฟล์และจุดสำคัญ | เชื่อมกับอะไร และเงื่อนไข |
|---|---|---|
| รายการอาหาร | [food_menu_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:11), [โหลด:55](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:55), [กรองหมวด:114](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:114), [การ์ด:819](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:819) | GET `/menu`, ค้นชื่อและกรอง ข้าว/เส้น/อื่น ๆ; เปิดรายละเอียดพร้อม context การจองหรือโต๊ะ walk-in; ต้องเลือกบริบทโต๊ะก่อนสั่ง |
| รายละเอียดอาหาร | [food_detail_page.dart:10](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:10), [กลุ่มตัวเลือก:99](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:99), [เข้าตะกร้า:177](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:177) | UI เลือก `option_groups`, ตัวเลือกหมดกดไม่ได้, required ต้องเลือก, จำกัด `max_select`, คิดราคาเพิ่มสำหรับแสดงผล; เซิร์ฟเวอร์ตรวจอีกครั้งเมื่อส่งออร์เดอร์ |
| ตะกร้า | [cart_page.dart:10](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:10), [แก้รายการ:714](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:714) | ใช้ `CartService.instance`; เพิ่ม/ลดจำนวน ลบ เปลี่ยนตัวเลือก หมายเหตุ และยอดรวม; ตะกร้าเก็บในหน่วยความจำ |
| ยืนยันออร์เดอร์ | [payment_page.dart:73](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:73) | ชื่อหน้า `PaymentPage` แต่ `_confirmPayment` **สร้างออร์เดอร์** POST `/orders` แล้ว POST `/order-details` ทีละเมนู, สำเร็จล้างตะกร้าและไป ConfirmationPage ที่ [271](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:271); ยังไม่ได้โอนเงินในขั้นนี้ |
| ประวัติออร์เดอร์ | [order_history_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:11), [โหลด:27](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:27), [แก้:65](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:65) | GET `/users/:id/orders`, `/orders/:id/details`; ยกเลิก/แก้เฉพาะสถานะที่ server อนุญาต; เปิด QR เมื่อพร้อมชำระ |
| QR และสลิป | [payment_qr_page.dart:8](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:8), [โหลด QR:24](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:24), [ส่งสลิป:35](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:35) | รับ payload PromptPay จาก server แล้ว `QrImageView` วาดภาพ; แสดง PromptPay ID, ยอด และเมนู; รูปสลิปจาก gallery เป็น base64 ส่ง API; แสดงรอตรวจ/ผ่าน/ไม่ผ่าน |

### แจ้งเตือน สถิติ และผู้ดูแล

| หน้าจอ/ส่วน | ไฟล์และจุดสำคัญ | เชื่อมกับอะไร และเงื่อนไข |
|---|---|---|
| กล่องแจ้งเตือน | [notification_inbox_page.dart:5](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart:5), [รายการ:29](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart:29) | GET `/notifications`; สีส้มเมื่อ `notifications_enabled` ณ **ตอนสร้างข้อความ** เป็น true, เทาเมื่อ false; `IgnorePointer` หุ้มไอคอนกระดิ่งเพื่อไม่ให้กด; pull-to-refresh |
| สถิติยอดนิยมลูกค้า | [restaurant_stats_page.dart:5](/D:/Project_Main/flutter_application_1/lib/pages/restaurant_stats_page.dart:5) | GET `/stats/popular?month=YYYY-MM`; นับเฉพาะออร์เดอร์ที่ชำระแล้ว |
| แดชบอร์ดแอดมิน | [admin_dashboard_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:11), [โหลด:63](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:63), [กราฟ:1041](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1041) | 5 แท็บ ภาพรวม/จอง/ครัว/ชำระ/จัดการ; `Future.wait` เรียกข้อมูลหลาย API พร้อมกัน; กราฟใช้ `CustomPainter` วาดจากยอดขายรายวัน |
| จองในแอดมิน | [admin_dashboard_page.dart:550](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:550) | แยกตาม `dining_date`, แสดงเวลา/ลูกค้า/โต๊ะ/จำนวนคน, เปลี่ยนสถานะผ่าน PATCH `/admin/reservations/:id/status` |
| ครัวในแอดมิน | [admin_dashboard_page.dart:640](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:640) | แยกตาม `order_date`, แต่ละ `order_detail` รับเมนูและเปลี่ยน `food_status`; รวมตัวเลือกและหมายเหตุให้ครัวเห็น |
| ตรวจสลิป | [admin_dashboard_page.dart:666](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:666) | ดูสลิปจาก endpoint ที่ต้องมี token; ยืนยัน/ปฏิเสธผ่าน PATCH `/admin/payments/:id/review` |
| จัดการร้าน | [admin_dashboard_page.dart:694](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:694) | ตั้ง PromptPay, แบนเนอร์และชื่อ, วันหยุด, ลูกค้า, เมนู, โต๊ะ; ฟอร์ม add/edit บางส่วนอยู่ในฟังก์ชัน [_editMenu:395](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:395), [_editTable:484](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:484) |
| หัวข้อ/ตัวเลือกเมนู | [admin_menu_options_dialog.dart:5](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:5), [แก้หัวข้อ:30](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:30), [แก้ตัวเลือก:72](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:72) | เพิ่ม/ลบ/แก้กลุ่ม, required, สูงสุด 1–5, ราคาเพิ่ม และสถานะหมด; เมื่อกดบันทึกส่งโครงสร้าง JSON ไปเมนู |

### ไฟล์ Widget/Model/Service ที่ UI ใช้ซ้ำ

| ไฟล์ | ความหมาย |
|---|---|
| [app_bottom_nav.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_bottom_nav.dart) | แถบนำทาง 4 ปุ่ม, รับ `currentIndex` และ `onChanged` จาก HomeShell |
| [app_buttons.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_buttons.dart) | `PrimaryButton` สีส้มและ `SecondaryButton` เส้นขอบ ลดโค้ดหน้าซ้ำ |
| [food_card.dart](/D:/Project_Main/flutter_application_1/lib/widgets/food_card.dart) | การ์ดอาหารใช้ซ้ำบางจุด; มีรูป fallback ชื่อ ราคาและปุ่ม Add; การ์ดหลักของ `FoodMenuPage` มีการสร้างในไฟล์หน้านั้นเอง |
| [search_field.dart](/D:/Project_Main/flutter_application_1/lib/widgets/search_field.dart) | ช่องค้นหาและปุ่ม filter ส่ง callback กลับหน้า |
| [section_header.dart](/D:/Project_Main/flutter_application_1/lib/widgets/section_header.dart) | ชื่อ section กับปุ่ม action |
| [user.dart](/D:/Project_Main/flutter_application_1/lib/models/user.dart) | `User.fromJson` แปลง `user_id`, `role_id`, `token`, รูป, สถานะจาก API |
| [table_model.dart](/D:/Project_Main/flutter_application_1/lib/models/table_model.dart) | `RestaurantTable`, `available` เทียบสถานะ “ว่าง”, เลขแสดง `T003`; กฎโต๊ะจริงยังตรวจที่ server |
| [reservation.dart](/D:/Project_Main/flutter_application_1/lib/models/reservation.dart) | ข้อมูลวันจอง วันรับบริการ เวลา คน โต๊ะและสถานะ; แยก `bookingDate` กับ `diningDate` |
| [food.dart](/D:/Project_Main/flutter_application_1/lib/models/food.dart) | เมนูจาก JSON, หมวด, image URL/asset fallback, option groups; มี field `rating` ค้างอยู่ใน model แต่ UI ปัจจุบันไม่ได้โชว์ดาว |
| [cart_item.dart](/D:/Project_Main/flutter_application_1/lib/models/cart_item.dart) | เมนู + จำนวน + ตัวเลือก + ราคาเพิ่ม; `unitPrice=base+extra`, `total=unitPrice×quantity`; ราคา Dart ใช้แสดงผล ไม่ใช่ยอดที่ server เชื่อถือ |
| [api_service.dart](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart) | จุดรวม HTTP ทั้งลูกค้า/แอดมิน, header token, encode/decode JSON และ error message |
| [current_user_service.dart](/D:/Project_Main/flutter_application_1/lib/services/current_user_service.dart) | singleton `ChangeNotifier` ของผู้ใช้ที่ล็อกอิน; ยังไม่บันทึกลง secure storage จึงหายเมื่อเปิดแอปใหม่ |
| [cart_service.dart](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart) | singleton ตะกร้า; รวมรายการเมื่อ menu/options/note เหมือนกันทุกค่า, `notifyListeners()` หลังแก้; ยังไม่ persist |
| [notification_service.dart](/D:/Project_Main/flutter_application_1/lib/services/notification_service.dart) | ขอสิทธิ์ FCM, ลงทะเบียน device token ตาม preference, ฟังข้อความขณะเปิดแอปแล้วแสดง SnackBar |
| [food_data.dart](/D:/Project_Main/flutter_application_1/lib/data/food_data.dart) | ข้อมูล `const foods` ตัวอย่างแบบ hard-code พร้อม rating/รูป; เมนูจริงของหน้าอาหารโหลดจาก API จึงต้องไม่อธิบายไฟล์นี้ว่าเป็นฐานข้อมูลร้าน |

---

## 4. แผนที่ฝั่ง Node.js: แต่ละไฟล์ทำอะไร

### `server.js` คือประตูเข้า ไม่ใช่ฐานข้อมูล

[server.js:1](/D:/Project_Main/my_app/server.js:1) import Express, model และ helper; [บรรทัด 121–125](/D:/Project_Main/my_app/server.js:121) เปิด CORS และรับ JSON สูงสุด 8 MB เพื่อรองรับรูป base64. รูป base64 ใหญ่กว่ารูป binary จริง จึงต้องเผื่อ limit. `app.get/post/put/patch/delete` จับ URL และวิธี HTTP; middleware ที่อยู่ก่อน handler ทำงานก่อน. เมื่อ handler `return res.status(...).json(...)`, request นั้นจบแล้ว. [บรรทัด 2133](/D:/Project_Main/my_app/server.js:2133) มี 404 JSON และ error handler เพื่อให้ Flutter แปลผลได้ ไม่ได้เจอ HTML ผิดรูปแบบ. [บรรทัด 2146](/D:/Project_Main/my_app/server.js:2146) เปิด port และเริ่ม worker เตือนการจอง.

| ไฟล์ backend | ฟังก์ชัน/แนวคิดสำคัญ | ทำไมแยกไว้ |
|---|---|---|
| [libs/db_pool.js](/D:/Project_Main/my_app/libs/db_pool.js) | MariaDB pool; `getConnection`, `query`, `release` | ใช้ connection ซ้ำและคืน connection ใน `finally`; งานหลายขั้นใช้ transaction บน connection เดียว |
| [libs/auth_token.js:13](/D:/Project_Main/my_app/libs/auth_token.js:13) | สร้าง token รูปแบบ JWT-like HMAC SHA-256 มี `sub`,`role_id`,`iat`,`exp` อายุ 12 ชม.; [verify:27](/D:/Project_Main/my_app/libs/auth_token.js:27) เช็กลายเซ็นแบบ timing-safe/หมดอายุ; [requireAuth:48](/D:/Project_Main/my_app/libs/auth_token.js:48) โหลดบัญชีจาก DB ใหม่ทุก request; [requireAdmin:70](/D:/Project_Main/my_app/libs/auth_token.js:70) ต้อง role 1 | ไม่เชื่อ role ใน token อย่างเดียว เพราะแอดมินอาจปิดบัญชี/เปลี่ยนสิทธิ์หลังออก token; secret ต้องยาวอย่างน้อย 32 bytes |
| [libs/booking_rules.js:18](/D:/Project_Main/my_app/libs/booking_rules.js:18) | `validateSlot` ตรวจวันที่จริง เวลาเต็มชั่วโมง 09:00–13:00 วันนี้ถึงอีก 2 วัน ไม่ใช่อาทิตย์ ไม่ใช่รอบที่เริ่มแล้ว; ใช้เวลา Bangkok | ป้องกัน client ส่งวัน/เวลาเกินกฎแม้ UI ไม่ให้เลือก |
| [libs/menu_options.js:3](/D:/Project_Main/my_app/libs/menu_options.js:3) | ตรวจโครงสร้างกลุ่ม/ตัวเลือก; [resolveMenuSelections:26](/D:/Project_Main/my_app/libs/menu_options.js:26) ตรวจตัวเลือกมีจริง ไม่ซ้ำ ไม่หมด, required, max แล้วคำนวณราคาเพิ่ม | ไม่ให้ client ปลอมตัวเลือกหรือราคา |
| [libs/promptpay.js:18](/D:/Project_Main/my_app/libs/promptpay.js:18) | สร้างข้อความ EMV/TLV ของ PromptPay สำหรับเบอร์ 10 หลักหรือเลข 13 หลัก ใส่ยอดเงินบาท/CRC16 | QR ต้องบรรจุข้อมูลมาตรฐาน ไม่ใช่แค่ข้อความเบอร์โทร |
| [libs/firebase_admin.js](/D:/Project_Main/my_app/libs/firebase_admin.js) | ตั้ง Firebase Admin ถ้ามี credentials | ส่ง push จาก server; หากไม่มี ระบบบันทึก in-app อย่างเดียว |
| [libs/notifications.js:17](/D:/Project_Main/my_app/libs/notifications.js:17) | `notifyUser` อ่าน preference, บันทึก `customer_notification` พร้อม snapshot เปิด/ปิด, ส่ง FCM หากเปิดและตั้งค่าแล้ว; [worker:70](/D:/Project_Main/my_app/libs/notifications.js:70) วนดูรายการจอง | ประวัติกับ push แยกกัน; ปิด push ก็ยังเก็บประวัติสีเทา |
| [libs/reservation_reminders.js:3](/D:/Project_Main/my_app/libs/reservation_reminders.js:3) | กำหนดเตือน 60 นาที, 10 นาที และเมื่อถึงเวลา; สร้าง key เฉพาะต่อการจอง | worker ใช้ key กันแจ้งซ้ำ |
| [models/user.js:3](/D:/Project_Main/my_app/models/user.js:3) | SQL อ่าน/สร้าง/แก้ผู้ใช้, lookup username/phone, รูป | ซ่อน SQL จาก route หลัก |
| [models/table.js:3](/D:/Project_Main/my_app/models/table.js:3) | โต๊ะทั้งหมด, โต๊ะ walk-in ที่ยังใช้ได้, สร้าง/แก้โต๊ะ, ปิด session | รอบโต๊ะต่างจากสถานะโต๊ะ; โต๊ะพร้อมขายก็อาจถูกใช้ชั่วคราวอยู่ |
| [models/reservation.js:6](/D:/Project_Main/my_app/models/reservation.js:6) | transaction สร้างจอง, query โต๊ะว่าง/วันหยุด/ประวัติ, ยกเลิกพร้อม lock | ป้องกันจองชนกันเมื่อผู้ใช้หลายคนกดพร้อมกัน |
| [models/menu.js:3](/D:/Project_Main/my_app/models/menu.js:3) | กลุ่มตัวเลือกตั้งต้น; parse JSON; อ่านเฉพาะเมนูพร้อมขายหรือทุกเมนูสำหรับแอดมิน; สร้าง/แก้/ลบ | menu option groups เป็นข้อมูลของเมนู ไม่ hard-code หน้าลูกค้า |
| [models/order.js:5](/D:/Project_Main/my_app/models/order.js:5) | transaction สร้างหัวออร์เดอร์, ตรวจโต๊ะ/การจอง/session; อ่านรายการ; สถานะ | Walk-in กับ pre-order ใช้ `order` เดียวกันแต่บริบทโต๊ะต่างกัน |
| [models/order_detail.js:5](/D:/Project_Main/my_app/models/order_detail.js:5) | เพิ่มรายการอาหาร, อ่านรายละเอียด, อัปเดตสถานะอาหาร | ออร์เดอร์หนึ่งมีหลายรายการและครัวทำเสร็จไม่พร้อมกัน |
| [models/payment.js:4](/D:/Project_Main/my_app/models/payment.js:4) | transaction รับสลิป ตรวจยอดและสถานะ, transaction ตรวจ/อนุมัติสลิป | การเปลี่ยน payment และ order ต้องสำเร็จหรือย้อนกลับพร้อมกัน |

**รูปแบบ SQL ที่ต้องอธิบาย**: `WHERE id = ?` กับ array parameter เป็น parameterized query ช่วยไม่ให้ข้อมูลที่ผู้ใช้กรอกกลายเป็นส่วนหนึ่งของคำสั่ง SQL. `JOIN` เชื่อมตารางผ่าน foreign key เพื่อนำชื่อคน/เมนู/สถานะมาแสดง. `BEGIN/COMMIT/ROLLBACK` ทำให้หลายคำสั่งเป็นหน่วยเดียว. `SELECT ... FOR UPDATE` ล็อกแถวใน transaction ป้องกันการเปลี่ยนพร้อมกัน. `finally { conn.release(); }` คืน connection แม้เกิด exception.

### API ทุกกลุ่ม พร้อมตำแหน่ง route

ในตารางนี้ `/api` เป็น prefix ของทุก URL คำว่า “ลูกค้า” หมายถึงใช้ `requireAuth` และหลาย route ตามด้วย `requireActiveUser`; “แอดมิน” หมายถึง `requireAdmin`. บาง GET เปิดสาธารณะเพื่อให้หน้าแสดงข้อมูลร้านก่อน login.

| HTTP/URL | ตำแหน่ง | ผู้เรียก/หน้าที่ |
|---|---|---|
| `GET /` | [127](/D:/Project_Main/my_app/server.js:127) | health/basic response |
| `GET /api/users` | [136](/D:/Project_Main/my_app/server.js:136) | แอดมินอ่านผู้ใช้ |
| `POST /api/login` | [158](/D:/Project_Main/my_app/server.js:158) | username/password → token/user |
| `POST /api/register` | [254](/D:/Project_Main/my_app/server.js:254) | สร้างลูกค้า role 2, bcrypt password |
| `PUT /api/users/:id` | [383](/D:/Project_Main/my_app/server.js:383) | แก้ข้อมูลตนเอง หรือแอดมินตามสิทธิ์ |
| `PUT /api/users/:id/profile-image` / `GET .../profile-image` | [499](/D:/Project_Main/my_app/server.js:499), [538](/D:/Project_Main/my_app/server.js:538) | อัปโหลด/อ่านรูปผู้ใช้ |
| `GET /api/menu`, `GET /api/menu/:id`, `GET /api/menu/:id/image` | [555](/D:/Project_Main/my_app/server.js:555), [732](/D:/Project_Main/my_app/server.js:732), [581](/D:/Project_Main/my_app/server.js:581) | เมนูพร้อมขายและรูป |
| `GET /api/restaurant/banner`, `GET .../image` | [591](/D:/Project_Main/my_app/server.js:591), [595](/D:/Project_Main/my_app/server.js:595) | ชื่อ/รูปแบนเนอร์ลูกค้า |
| `GET /api/tables`, `GET /api/walk-in/tables` | [692](/D:/Project_Main/my_app/server.js:692), [722](/D:/Project_Main/my_app/server.js:722) | โต๊ะทั่วไป/โต๊ะ walk-in ที่ผู้ใช้นี้เลือกได้ |
| `GET /api/availability`, `GET /api/restaurant/holidays` | [1190](/D:/Project_Main/my_app/server.js:1190), [1207](/D:/Project_Main/my_app/server.js:1207) | ค้นโต๊ะว่างและวันหยุดปฏิทิน |
| `POST /api/reservations` | [1217](/D:/Project_Main/my_app/server.js:1217) | สร้างจองหลังตรวจ slot, holiday, ความจุ, ชนกัน |
| `GET /api/reservations/:id`, `GET /api/users/:id/reservations` | [1342](/D:/Project_Main/my_app/server.js:1342), [1423](/D:/Project_Main/my_app/server.js:1423) | รายละเอียด/ปัจจุบัน; `?view=history` ใช้ดูทุกสถานะ |
| `POST /api/reservations/:id/cancel` | [1588](/D:/Project_Main/my_app/server.js:1588) | ลูกค้ายกเลิกได้ก่อนเวลาอย่างน้อย 1 ชม. |
| `POST /api/orders`, `POST /api/order-details` | [797](/D:/Project_Main/my_app/server.js:797), [872](/D:/Project_Main/my_app/server.js:872) | สร้างหัวออร์เดอร์ แล้วเพิ่มเมนูทีละรายการ |
| `GET /api/orders/:id`, `GET /api/orders/:id/details`, `GET /api/users/:id/orders` | [1490](/D:/Project_Main/my_app/server.js:1490), [998](/D:/Project_Main/my_app/server.js:998), [1568](/D:/Project_Main/my_app/server.js:1568) | อ่านออร์เดอร์ของเจ้าของ/แอดมิน |
| `PATCH /api/orders/:orderId/details/:detailId`, `POST /api/orders/:id/cancel` | [1062](/D:/Project_Main/my_app/server.js:1062), [1128](/D:/Project_Main/my_app/server.js:1128) | แก้รายการ/ยกเลิกตามสถานะที่อนุญาต |
| `GET /api/orders/:id/payment-qr`, `GET .../payment-status`, `POST .../payment-slip` | [1677](/D:/Project_Main/my_app/server.js:1677), [1701](/D:/Project_Main/my_app/server.js:1701), [1710](/D:/Project_Main/my_app/server.js:1710) | QR ที่ server คำนวณยอด, สถานะสลิป, แนบรูป |
| `POST /api/push-devices`, `GET/PATCH /api/notification-preference` | [1603](/D:/Project_Main/my_app/server.js:1603), [1618](/D:/Project_Main/my_app/server.js:1618), [1631](/D:/Project_Main/my_app/server.js:1631) | device FCM และเปิด/ปิดแจ้งเตือน |
| `GET /api/notifications`, `PATCH /api/notifications/:id/read` | [1654](/D:/Project_Main/my_app/server.js:1654), [1668](/D:/Project_Main/my_app/server.js:1668) | ประวัติ 100 รายการล่าสุด/mark read; UI ปัจจุบันไม่ได้ใช้การกดกระดิ่งเพื่อ mark read |
| `GET /api/stats/popular?month=YYYY-MM` | [2112](/D:/Project_Main/my_app/server.js:2112) | สถิติเมนูที่ชำระแล้ว |
| `GET /api/admin/dashboard`, `GET /api/admin/reservations`, `PATCH .../:id/status` | [1752](/D:/Project_Main/my_app/server.js:1752), [1775](/D:/Project_Main/my_app/server.js:1775), [1780](/D:/Project_Main/my_app/server.js:1780) | ภาพรวมและจัดการจอง |
| `GET/POST /api/admin/holidays`, `DELETE .../:id` | [1797](/D:/Project_Main/my_app/server.js:1797), [1802](/D:/Project_Main/my_app/server.js:1802), [1817](/D:/Project_Main/my_app/server.js:1817) | เพิ่ม/ลบวันหยุด |
| `GET /api/admin/orders`, `GET /api/admin/order-items`, `PATCH .../:id/accept`, `PATCH .../:id/status` | [1822](/D:/Project_Main/my_app/server.js:1822), [1827](/D:/Project_Main/my_app/server.js:1827), [1832](/D:/Project_Main/my_app/server.js:1832), [1874](/D:/Project_Main/my_app/server.js:1874) | ครัว รับรายการและเปลี่ยนสถานะ |
| `GET /api/admin/payments`, `GET .../:id/slip`, `PATCH .../:id/review` | [1931](/D:/Project_Main/my_app/server.js:1931), [1936](/D:/Project_Main/my_app/server.js:1936), [1946](/D:/Project_Main/my_app/server.js:1946) | ตรวจสลิป |
| `GET/PATCH/PUT/DELETE /api/admin/customers...` | [1962](/D:/Project_Main/my_app/server.js:1962)–[2028](/D:/Project_Main/my_app/server.js:2028) | เปิดปิดบัญชี แก้ข้อมูล เปลี่ยนรหัส soft delete |
| `GET/POST/PUT/DELETE /api/admin/menu...`, `POST /api/admin/menu-image` | [2047](/D:/Project_Main/my_app/server.js:2047)–[2070](/D:/Project_Main/my_app/server.js:2070), [675](/D:/Project_Main/my_app/server.js:675) | CRUD เมนู สถานะพร้อมขาย รูป ตัวเลือก |
| `GET/POST/PUT /api/admin/tables...`, `DELETE .../walk-in-session` | [2077](/D:/Project_Main/my_app/server.js:2077)–[2100](/D:/Project_Main/my_app/server.js:2100) | CRUD โต๊ะ/ปิดรอบโต๊ะ |
| `GET/PUT /api/admin/payment-settings/promptpay` | [607](/D:/Project_Main/my_app/server.js:607), [611](/D:/Project_Main/my_app/server.js:611) | ตั้งบัญชีรับโอนที่ QR ใช้จริง |
| `GET /api/admin/restaurant/banner`, `PUT .../title`, `POST .../banner` | [603](/D:/Project_Main/my_app/server.js:603), [627](/D:/Project_Main/my_app/server.js:627), [643](/D:/Project_Main/my_app/server.js:643) | เปลี่ยนข้อความและรูปบนหน้าแรก |

`ApiService` ฝั่ง Flutter มีเมธอดราย endpoint อยู่ใน [api_service.dart](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart). ลูกค้าส่วนใหญ่มีเมธอดตั้งชื่อเฉพาะ เช่น `createReservation`, `createOrder`, `getPaymentQr`. ฝั่งแอดมินใช้ wrapper `adminGet/Post/Put/Patch/Delete` ที่ [635](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:635) เพื่อลดโค้ด HTTP ซ้ำ. JSON ตอบกลับใช้รูปแบบ `{isError, data, message}` เป็นหลัก แต่บาง model คืน `errorMessage`; เวลาอธิบายควรพูดว่า “รูปแบบหลัก” ไม่ใช่ทุก route เหมือนกันเป๊ะ.

---

## 5. ฐานข้อมูลและความสัมพันธ์

### ตารางหลัก

```text
user (user_id PK, username, password hash, role_id, สถานะ)
  ├── reservation (reservation_id PK, user_id FK, table_id FK, วัน/เวลา/คน/สถานะ)
  │     └── order.reservation_id (nullable)
  ├── order (order_id PK, user_id FK, table_id nullable, สถานะ, paid_at)
  │     ├── order_detail (orderdetail_id PK, order_id FK, menu_id FK,
  │     │                  quantity, price ณ ตอนสั่ง, selected_options snapshot)
  │     └── payment (payment_id PK, order_id FK, amount, slip, review status)
  ├── restaurant_table_session (รอบโต๊ะ walk-in)
  ├── push_device (FCM token)
  └── customer_notification (ข้อความที่เห็นในแอป)

table (table_id PK, table_number, capacity, statustable_id)
  ├── reservation
  └── restaurant_table_session

menu (menu_id PK, price, category, statusmenu_id, option_groups_json, menu_image)
  └── order_detail

restaurant_holiday (holiday_date UNIQUE, holiday_name)
notification_delivery (notification_key UNIQUE กันเตือนซ้ำ)
```

`PK` เป็นตัวระบุแถว, `FK` อ้างอีกตาราง, `UNIQUE` กันข้อมูลซ้ำ. ชื่อตาราง `order` และ `user` อยู่ใน backtick ใน SQL บางแห่ง เพราะเป็นคำที่มีความหมายพิเศษ/อาจชนชื่อคำสงวน. `price` ใน `order_detail` คือราคาต่อหน่วย ณ เวลาเพิ่มรายการ รวมตัวเลือก ณ ตอนนั้น; หากแอดมินเปลี่ยนราคาเมนูภายหลัง ยอดของออร์เดอร์เก่าไม่ควรเปลี่ยน. `selected_options` เก็บ snapshot ชื่อและราคาเพิ่มด้วยเหตุผลเดียวกัน.

### Migration แต่ละไฟล์

| ลำดับ | ไฟล์ | เพิ่มอะไรและส่งผลต่อระบบไหน |
|---|---|---|
| 1 | [20261009_restaurant_features.sql](/D:/Project_Main/my_app/db/migrations/20261009_restaurant_features.sql) | `user.is_active`, index การจอง, สถานะจอง 1/2/3/4, สถานะออร์เดอร์/อาหาร, ความสัมพันธ์ payment↔order, ตารางวันหยุด/อุปกรณ์/แจ้งเตือน/key กันซ้ำ |
| 2 | [20261010_notification_preference.sql](/D:/Project_Main/my_app/db/migrations/20261010_notification_preference.sql) | `user.notification_enabled` |
| 3 | [20261011_walk_in_table_sessions.sql](/D:/Project_Main/my_app/db/migrations/20261011_walk_in_table_sessions.sql) | `order.table_id` และ `restaurant_table_session` สำหรับลูกค้าหน้าร้าน |
| 4 | [20261012_menu_description.sql](/D:/Project_Main/my_app/db/migrations/20261012_menu_description.sql) | `menu.description`; โค้ด CRUD ปัจจุบันเน้นชื่อ/ราคา/หมวด/ตัวเลือก จึงตรวจการใช้ description จริงก่อนตอบว่าปรับจากแอดมินได้ |
| 5 | [20261013_customer_admin.sql](/D:/Project_Main/my_app/db/migrations/20261013_customer_admin.sql) | `user.is_deleted` สำหรับ soft delete |
| 6 | [20261014_menu_choice_groups.sql](/D:/Project_Main/my_app/db/migrations/20261014_menu_choice_groups.sql) | `menu.option_groups_json`, `order_detail.selected_options` |
| 7 | [20261015_notification_event_preference.sql](/D:/Project_Main/my_app/db/migrations/20261015_notification_event_preference.sql) | `customer_notification.notifications_enabled` สถานะเปิดปิดขณะเกิดข้อความ ใช้กำหนดสีกระดิ่งย้อนหลัง |
| 8 | [20261016_menu_category_image.sql](/D:/Project_Main/my_app/db/migrations/20261016_menu_category_image.sql) | หมวด `category` และรูป `menu_image`; อัปเดตหมวดเดิมจากชื่อเมนู |

**เรื่องที่ต้องตอบตามจริง**: migration เหล่านี้เป็นการแก้ **schema เดิม**; repository นี้ไม่ได้มีไฟล์สร้างตารางฐานทั้งหมดตั้งแต่ศูนย์. [README_RUN_TH.md](/D:/Project_Main/my_app/README_RUN_TH.md) บอกให้นำเข้า schema ปัจจุบันก่อน แล้วใช้ migration ตามลำดับ. ไฟล์แรกมี `ADD COLUMN` บางส่วนโดยไม่มี `IF NOT EXISTS` จึงไม่ควรรันซ้ำ. ระหว่างสอบหากถามวิธีติดตั้ง ให้พูดว่าต้องมี MariaDB, schema เดิม, migrations, `.env`, Node backend และ Flutter app ตามลำดับ.

### รหัสสถานะที่อาจารย์ถาม

| ชนิด | ค่า | ความหมาย/ผล |
|---|---|---|
| `role_id` | 1 / 2 | แอดมิน / ลูกค้า; middleware ตรวจใน DB |
| `statusreservation_id` | 1 / 2 / 3 / 4 | ยืนยันแล้ว / ยกเลิก / มาใช้บริการแล้ว / รอยืนยัน; 1 และ 4 เป็น active ที่กันโต๊ะ |
| `statustable_id` | 1 / 2 | พร้อมใช้/ไม่พร้อมใช้; รอบ walk-in ที่ยังไม่ปิดเป็นอีกเงื่อนไข |
| `statusmenu_id` | 1 / 2 | พร้อมขาย / หยุดขาย; ตัวเลือกย่อยหมดไม่ได้บังคับให้เมนูทั้งเมนูหยุดขาย |
| `food_status` | `รอทำ` / `กำลังทำ` / `ทำเสร็จแล้ว` | สถานะรายการอาหารหนึ่งรายการ |
| `order_status` | `รอรับออร์เดอร์`, `กำลังทำ`, `รอชำระเงิน`, `รอตรวจสอบการชำระ`, `ชำระแล้ว`, `ชำระเงินไม่ผ่าน`, `ยกเลิก` | วงจรออร์เดอร์; QR ต้องรอชำระเงิน/ชำระเงินไม่ผ่าน และอาหารทุกรายการเสร็จ |
| `payment_status_id` | 1 / 2 / 3 | ผ่าน / ไม่ผ่าน / รอตรวจสอบ |

---

## 6. เดินโค้ดจริง: หน้าหนึ่งเชื่อมอีกชั้นอย่างไร

### กรณี A: สมัครสมาชิกและล็อกอิน

1. ผู้ใช้กรอกใน [SignUpPage:41](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:41). Flutter เช็กช่องจำเป็น, รหัสยืนยันตรงกัน, username ขั้นต่ำ, เบอร์ 10 หลัก เพื่อให้ feedback ทันที.
2. [ApiService.register:59](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:59) POST JSON ไป `/api/register`.
3. [server.js:254](/D:/Project_Main/my_app/server.js:254) ตรวจซ้ำอย่างจริงจัง: username รูปแบบที่อนุญาต ความยาวรหัสผ่าน 8–72 bytes ชื่อ/อีเมล/โทรศัพท์, username และเบอร์ซ้ำ. โทรศัพท์ไทยถูก normalize เป็น `+66...` ที่ [server.js:32](/D:/Project_Main/my_app/server.js:32). `bcrypt` hash รหัสผ่านก่อนเก็บ; ไม่มีการเก็บ plain password.
4. [models/user.js:159](/D:/Project_Main/my_app/models/user.js:159) INSERT `user`; role ลูกค้าเป็น 2. Server สร้าง token; Flutter `User.fromJson` แล้วเก็บใน `CurrentUserService`.
5. เมื่อ login [LoginPage:32](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:32) ส่งไป [server.js:158](/D:/Project_Main/my_app/server.js:158); server โหลด password hash และ `bcrypt.compare`. ผ่านแล้วออก token 12 ชั่วโมง. Flutter ดู role และพาเข้า AdminDashboard หรือ HomeShell.
6. Request ถัดไป [ApiService._headers:22](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:22) ใส่ Bearer token; [requireAuth:48](/D:/Project_Main/my_app/libs/auth_token.js:48) ตรวจลายเซ็น/หมดอายุและสถานะบัญชีจาก DB อีกครั้ง. ดังนั้นปิดบัญชีแล้ว token เก่าก็ใช้ต่อไม่ได้.

**คำตอบ “ทำไมต้องตรวจซ้ำสองชั้น?”**: ฝั่ง Flutter ตรวจเพื่อประสบการณ์ผู้ใช้; server ตรวจเพื่อความถูกต้องและความปลอดภัยของฐานข้อมูล แม้มีคนส่ง API โดยไม่ผ่านแอป.

### กรณี B: เลือกวันและจองโต๊ะ

1. [ReservationPage](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart) เริ่มจากวันที่/เวลา/จำนวนคน. ปฏิทินโหลดวันหยุดจาก `/restaurant/holidays`, สีแดงสำหรับอาทิตย์/วันหยุดพิเศษ สีเขียวเมื่ออยู่ในช่วงจองและยังเปิด สีเทาสำหรับวันที่อยู่นอกกฎ. ปีที่แสดงในหัวปฏิทินบวก 543 เพื่อเป็น พ.ศ. แต่วันที่ส่ง API ยังคง `YYYY-MM-DD` ค.ศ.
2. เมื่อเปลี่ยนวัน เวลา หรือจำนวนคน [ReservationPage._loadTables:69](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:69) ขอ `/availability`. [models/reservation.js:125](/D:/Project_Main/my_app/models/reservation.js:125) เลือกโต๊ะที่ `statustable_id=1`, `capacity>=guests`, ไม่มี session ที่ยังเปิด และไม่มี reservation active เวลาเดียวกัน.
3. ผู้ใช้เลือกโต๊ะและกดยืนยัน [ReservationPage:221](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:221). API ส่งวัน/เวลา/คน/โต๊ะ. Server ที่ [server.js:1217](/D:/Project_Main/my_app/server.js:1217) **ไม่เชื่อ `user_id` และ `booking_date` จาก client**: ดึง user จาก token และกำหนดวันสร้างตามเวลา Bangkok ใหม่, ตรวจ `validateSlot`, จำนวนคน, วันหยุด.
4. [models/reservation.js:6](/D:/Project_Main/my_app/models/reservation.js:6) เริ่ม transaction, ล็อกแถวลูกค้าก่อน (กันลูกค้ากดสร้าง 2 โต๊ะเวลาเดียวกัน), ล็อกโต๊ะ, ตรวจออร์เดอร์ค้าง/ความจุ/session/การจองซ้ำ แล้ว INSERT สถานะ 1 และ commit. หากข้อใดพลาด rollback. ข้อมูล availability ที่โหลดก่อนหน้าอาจเก่าแล้ว จึงต้องตรวจอีกครั้งก่อน INSERT.
5. หลังสำเร็จ server บันทึกการแจ้งเตือน; Flutter ไปเมนูพร้อม `reservationId`, ทำให้ออร์เดอร์ถัดไปผูกกับการจองนั้น. ผู้ใช้ดูปัจจุบันใน BookingPage และทุกสถานะใน ReservationHistoryPage.
6. ยกเลิกที่ [models/reservation.js:265](/D:/Project_Main/my_app/models/reservation.js:265) ได้เฉพาะสถานะ 1/4 และต้องห่างเวลาเริ่มอย่างน้อย 60 นาที; transaction lock แถวก่อนเปลี่ยนเป็นสถานะ 2. ถ้าอาจารย์ถาม “ทำไมประวัติเก่าต้องอยู่?” ตอบว่าเปลี่ยนสถานะ ไม่ลบแถว จึงตรวจสอบย้อนหลังได้.

**ประเด็นเวลาที่ต้องพูดให้ชัด**: กฎการจองใน helper ใช้ `Asia/Bangkok`, แต่บาง query walk-in ใช้ `CURRENT_DATE()/CURRENT_TIME()` ของฐานข้อมูล; การตั้ง timezone ของ DB/server ต้องสอดคล้องกัน จึงจะไม่เกิดรอบเหลื่อม. ปฏิทินสีเขียวคือเปิดตามกฎวัน ไม่ใช่ยืนยันว่าโต๊ะที่ต้องการว่าง.

### กรณี C: ลูกค้า walk-in เลือกโต๊ะโดยไม่จอง

1. หน้า Home/Menu เปิดทางเลือกโต๊ะหน้าร้านและ GET `/walk-in/tables` [server.js:722](/D:/Project_Main/my_app/server.js:722). [models/table.js:53](/D:/Project_Main/my_app/models/table.js:53) กรองโต๊ะพร้อมใช้ ไม่มี session ของผู้อื่น และไม่มีการจอง active ในชั่วโมงปัจจุบัน.
2. ตอน POST `/orders` [models/order.js:5](/D:/Project_Main/my_app/models/order.js:5) ล็อก user/โต๊ะด้วย transaction และตรวจซ้ำ; ถ้าไม่มี session จะสร้าง `restaurant_table_session`. ถ้ามี session ของผู้ใช้เดิมก็สั่งต่อได้; ของคนอื่นไม่ได้. หากมีออร์เดอร์ค้างโต๊ะเดิม ระบบไม่ให้เริ่มโต๊ะอื่น.
3. `order.reservation_id` เป็น null และ `order.table_id` มีค่า, `order_channel` เป็น `walk_in`. แอดมินปิด session เมื่อเก็บโต๊ะเสร็จผ่าน `/admin/tables/:id/walk-in-session` [server.js:2100](/D:/Project_Main/my_app/server.js:2100).

**เหตุผลของ session**: `table_status` บอกสถานะเชิงบริหาร เช่น โต๊ะเปิดบริการหรือไม่ ส่วน session บอกว่าตอนนี้ใครใช้โต๊ะอยู่. ถ้ามีแต่สถานะโต๊ะ จะไม่รู้รอบใช้งานและอาจให้ลูกค้าคนอื่นสั่งโต๊ะเดียวกัน.

### กรณี D: เลือกตัวเลือกอาหารและเพิ่มตะกร้า

1. GET `/menu` แปลง JSON ด้วย [Food.fromJson](/D:/Project_Main/flutter_application_1/lib/models/food.dart) แล้ว [FoodMenuPage](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart) กรองหมวด/ค้นหา. `menu.option_groups_json` ถูก parse ใน [models/menu.js:18](/D:/Project_Main/my_app/models/menu.js:18); ถ้าเป็น null ใช้กลุ่มค่าเริ่มต้น แต่ถ้าข้อมูล JSON เสียหรือไม่ใช่ array จะได้กลุ่มว่าง.
2. [FoodDetailPage.initState](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:49) เลือกตัวเลือกแรกที่ยังขายในกลุ่ม required, ถ้ามี. [_buildOptionGroup:99](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:99) แสดง ChoiceChip, ตัวเลือกที่หมด `onSelected: null`; กลุ่มเลือกได้ 1 จะสลับค่า, เลือกได้หลายจะเพิ่ม/เอาออกไม่เกิน `max_select`.
3. ราคาบนหน้า `base + extras`, คูณจำนวน. [_addToCart:177](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:177) ตรวจ required อีกครั้งและเก็บ snapshot ตัวเลือก. [CartService.add](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart) รวมกับรายการเดิมเฉพาะเมนู ตัวเลือก ราคาเพิ่ม หมายเหตุ ฯลฯ ตรงกันทั้งหมด; ต่างหนึ่งอย่างเป็นรายการใหม่.
4. แอดมินปรับกลุ่ม/ตัวเลือกที่ [AdminMenuOptionsDialog](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart). ตัวเลือกหมดมี `available=false` แล้วลูกค้าเลือกไม่ได้; เมนูทั้งจานยังขายได้. [libs/menu_options.js:26](/D:/Project_Main/my_app/libs/menu_options.js:26) ตรวจอีกครั้งตอนบันทึก order detail เพราะตัวเลือกอาจหมดระหว่างที่ลูกค้าเปิดหน้ารายละเอียดไว้.

**ตัวอย่างราคา**: เมนู 50 บาท + ไข่ดาว 10 บาท × 2 จาน = 120 บาท. แต่ client ส่ง `price` ไปก็จริง; [server.js:872](/D:/Project_Main/my_app/server.js:872) ไม่ใช้ค่าราคานั้นเป็นยอดจริง. Server โหลด `menu.price` จาก DB แล้วบวก extra price ของ option ที่ยังมีจริง ได้ `finalPrice`, จึงป้องกันการแก้ JSON เป็นราคา 1 บาท.

### กรณี E: ส่งออร์เดอร์ ครัวรับรายการ และแก้ไข

1. [CartPage](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart) ส่งบริบท `reservationId` หรือ `tableId` ไป [PaymentPage](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart). ชื่อนี้อาจทำให้สับสน: ขั้นนี้คือ “ยืนยันรายการอาหาร”, ไม่ใช่ชำระเงินจริง.
2. [_confirmPayment:73](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:73) ป้องกันกดซ้ำด้วย `_isSaving`, ตรวจ login/ตะกร้าไม่ว่าง, POST หัวออร์เดอร์. [models/order.js](/D:/Project_Main/my_app/models/order.js) ตรวจว่า reservation เป็นของผู้ใช้และ active หรือโต๊ะ walk-in ใช้ได้.
3. Flutter วน `cart.items` ส่ง POST `/order-details` ทีละรายการ. Server ตรวจเจ้าของออร์เดอร์, สถานะที่ยังเพิ่มได้, `quantity` 1–50, เมนูยังพร้อมขาย, option ยังมี/ยังไม่หมด, ราคาจริง แล้ว [models/order_detail.js:5](/D:/Project_Main/my_app/models/order_detail.js:5) บันทึกจำนวน ราคา ตัวเลือก/หมายเหตุ.
4. สำเร็จแล้วล้างตะกร้าและแสดง ConfirmationPage. ถ้ารายการใดล้มเหลว Flutter **พยายาม** เรียก cancel order ใหม่เพื่อลดข้อมูลค้าง. นี่เป็นการชดเชยข้าม HTTP ไม่ใช่ transaction เดียวครอบทั้งหัวออร์เดอร์และทุกรายการ; ถ้า cancel ไม่สำเร็จอาจต้องให้ร้านตรวจภายหลัง. ตอบตามนี้ดีกว่าบอกว่า “atomic ทั้งออร์เดอร์”.
5. ครัวใน [AdminDashboardPage._kitchen:640](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:640) แสดงแต่ละ `order_detail` ตามวันและเวลา. กดรับเมนู PATCH `/admin/order-items/:id/accept`, server lock แถวแล้วเปลี่ยนอาหารเป็น `กำลังทำ`, ออร์เดอร์เป็น `กำลังทำ` และแจ้งลูกค้า.
6. เมื่อครัวเปลี่ยน food status [server.js:1874](/D:/Project_Main/my_app/server.js:1874) server query จำนวนรวม/จำนวนที่ทำเสร็จ. ถ้าเสร็จทุกจาน → order `รอชำระเงิน`; ถ้ามีจานเริ่มทำ → `กำลังทำ`; ถ้ายังไม่เริ่ม → `รอรับออร์เดอร์`. เหตุผลคือสถานะหัวออร์เดอร์เป็นผลรวมของรายการย่อย ไม่ควรกำหนดด้วยจานใดจานหนึ่ง.

### กรณี F: QR PromptPay, สลิป และยอดขาย

1. หลังอาหารทุกจานเสร็จ ลูกค้าเปิด [PaymentQrPage](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart). GET `/orders/:id/payment-qr` [server.js:1677](/D:/Project_Main/my_app/server.js:1677) ตรวจเจ้าของและสถานะ, โหลดรายการที่ทำเสร็จทั้งหมด, คำนวณ `amount = Σ(quantity×price)` จาก DB.
2. [libs/promptpay.js:18](/D:/Project_Main/my_app/libs/promptpay.js:18) สร้าง payload โดยใช้ PromptPay ID ที่แอดมินตั้งใน `storage/payment_settings/settings.json` หรือ fallback env. Flutter `QrImageView` วาด QR จาก payload และแสดง ID/ยอดเป็นตัวหนังสือเพื่อให้ลูกค้าตรวจซ้ำ.
3. หลังโอน ลูกค้าเลือกรูปสลิป ส่ง base64 ไป `/orders/:id/payment-slip` [server.js:1710](/D:/Project_Main/my_app/server.js:1710). [models/payment.js:4](/D:/Project_Main/my_app/models/payment.js:4) ตรวจว่ารายการเป็นของตน, ทุกจานเสร็จ, ยังไม่มีสลิปรอตรวจ และยอดตรง DB; INSERT payment สถานะ 3 แล้ว order `รอตรวจสอบการชำระ` ใน transaction.
4. แอดมินเปิด [AdminDashboardPage._payments:666](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:666), ดูรูปที่ endpoint ต้องผ่าน `requireAdmin`, กดยืนยัน/ปฏิเสธ. [models/payment.js:49](/D:/Project_Main/my_app/models/payment.js:49) lock payment/order, ป้องกันตรวจซ้ำ, ตั้ง payment 1 ผ่านหรือ 2 ไม่ผ่าน. ถ้าผ่าน order `ชำระแล้ว` พร้อม `paid_at`; ถ้าไม่ผ่าน `ชำระเงินไม่ผ่าน` ให้ส่งใหม่.
5. [แดชบอร์ด:1752](/D:/Project_Main/my_app/server.js:1752) ยอดขายเดือนนี้ SUM `payment.amount` ที่สถานะผ่าน; เมนูยอดนิยมคิดเฉพาะ order `ชำระแล้ว` โดย `paid_at` ในเดือนนั้น, `revenue = Σ(quantity×order_detail.price)`. กราฟจากยอดขายรายวันแล้ว [CustomPainter:1063](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1063) วาดเส้น. “ยอดขาย” จึงไม่ได้คิดจากออร์เดอร์ที่เพิ่งสร้างหรือสลิปที่ยังไม่ได้ตรวจ.

**ข้อสังเกตตรง ๆ**: การแนบสลิปและให้แอดมินกดผ่านเป็นการตรวจหลักฐานด้วยคน ระบบไม่ได้ต่อธนาคารเพื่อยืนยันยอดโอนอัตโนมัติ; QR ถูกสร้างตามจำนวนเงิน แต่การกด “ส่งสลิป” ไม่ได้พิสูจน์เองว่าเงินเข้าแล้ว.

### กรณี G: การแจ้งเตือนและสีของกระดิ่ง

1. เหตุการณ์จอง/เปลี่ยนสถานะ/ครัว/ชำระเงินเรียก [notifyUser:17](/D:/Project_Main/my_app/libs/notifications.js:17). Helper อ่าน `user.notification_enabled` **ขณะเกิดเหตุการณ์**, INSERT ข้อความพร้อมค่า snapshot ลง `customer_notification` เสมอ. ถ้าเปิดและมี Firebase Admin + token จึงส่ง FCM.
2. ใน [NotificationInboxPage:29](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart:29), สีส้ม/กระดิ่ง active อ่านจาก snapshot ของแต่ละแถว, สีเทาเมื่อปิดในตอนนั้น; ปรับ switch ตอนนี้ไม่ได้ย้อมสีประวัติเก่า. `IgnorePointer` ทำให้ตัวรูปกระดิ่งไม่มี action. Endpoint mark read มีอยู่แต่หน้านี้ไม่ได้เรียกจากกระดิ่ง.
3. [ProfilePage._NotificationPreferenceControl:236](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:236) อ่าน/บันทึก preference; ถ้าเปิดลองลงทะเบียน FCM token. ถ้าตั้ง Firebase ไม่ครบ การบันทึก switch ยังสำเร็จได้ แต่ push จริงส่งไม่ได้.
4. Worker ที่ [notifications.js:70](/D:/Project_Main/my_app/libs/notifications.js:70) ทำงานทุก 30 วินาที ตรวจจองที่ยัง active แล้วเตือนก่อน 60 นาที, ก่อน 10 นาที และเมื่อถึงเวลา ตาม [reservation_reminders.js:3](/D:/Project_Main/my_app/libs/reservation_reminders.js:3). ตาราง `notification_delivery.notification_key` แบบ UNIQUE ป้องกัน worker สร้างเตือนซ้ำสำหรับการจองและระยะเวลาเดียวกัน.

**ความละเอียดที่ควรพูด**: worker ไม่ใช่ scheduler ในโทรศัพท์ จึงทำงานได้เมื่อ backend เปิดอยู่. การเตือนอาจช้ากว่าจุดเวลาเป๊ะเล็กน้อยเพราะ polling ทุก 30 วินาที. หาก backend ปิดข้ามช่วงเตือน อาจพลาดรอบนั้น. ในโค้ด key กันซ้ำถูกบันทึกก่อน `notifyUser`; ถ้าบันทึก key สำเร็จแต่การสร้าง notification ล้มเหลว อาจไม่ retry รอบนั้น.

### กรณี H: แอดมินจัดการข้อมูลหน้าร้าน

- **รูป/ข้อความแบนเนอร์**: ฟอร์มใน [AdminDashboardPage:194](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:194) และ [231](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:231) → admin API [server.js:627](/D:/Project_Main/my_app/server.js:627)/[643](/D:/Project_Main/my_app/server.js:643) → เก็บไฟล์และ `banner.json` ใน `storage/restaurant_banner` → [HomePage](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart) โหลด URL และ title. ค่าเริ่มต้นเมื่อไม่มีการตั้งคือ “ร้านอาหาร” กับรูป asset.
- **เมนู**: ฟอร์ม [AdminDashboardPage._editMenu:395](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:395) + dialog ตัวเลือก → `POST/PUT /admin/menu`; backend ตรวจชื่อ ราคา >=0 หมวดสามประเภท รูป filename ที่อนุญาต status 1/2 และรูปแบบ option groups. ถ้าหยุดขายเมนู ไม่แสดงในเมนูลูกค้า; ถ้าตัวเลือกเดียวหมด จะยังแสดงเมนูแต่ตัวเลือกนั้นกดไม่ได้.
- **วันหยุด**: แอดมิน POST `/admin/holidays` โดยวันที่ต้องเป็นวันจริง ชื่อไม่ว่าง/<=150 ตัวอักษร และ `holiday_date` UNIQUE; ลูกค้าเห็นวันแดงในปฏิทิน และ server ปฏิเสธจองวันนั้น.
- **ลูกค้า**: แอดมินเปิด/ปิด `is_active`, แก้ข้อมูล/รหัส และ soft delete `is_deleted`, เพื่อคงประวัติการจอง/ออร์เดอร์; `requireAuth` อ่าน DB ใหม่จึงตัดสิทธิ์บัญชีที่ถูกปิดได้.
- **โต๊ะ**: แอดมินเพิ่มหมายเลข/ความจุ/สถานะ และปิดรอบ walk-in; ถ้าโต๊ะมีประวัติ ไม่ควรลบทิ้งเพื่อรักษาความสัมพันธ์. ใน UI จัดการมีการ์ดแยกเป็นชั้น ๆ แต่ข้อมูลหลักอยู่ใน `table` กับ session.

---

## 7. เงื่อนไขที่สำคัญต่อความถูกต้องของระบบ

### ขอบเขตความรับผิดชอบ

| เงื่อนไข | ฝั่ง Flutter ทำเพื่ออะไร | ฝั่ง server ทำเพื่ออะไร |
|---|---|---|
| ช่องกรอกสมัครสมาชิก | แจ้งข้อผิดพลาดเร็ว | ป้องกันข้อมูลผิดจากทุก client, เช็กซ้ำกับ DB, hash password |
| ปฏิทินวันแดง/เขียว/เทา | ให้เลือกได้ง่ายและเห็นวันปิดชัด | `validateSlot`, วันหยุดและ availability เป็นกฎจริง |
| เลือกตัวเลือกอาหาร | ปิด chip ของที่หมดและคำนวณยอด preview | ยืนยัน option ยังมีและคำนวณราคาใหม่จาก DB |
| ปุ่มแอดมิน | แสดงเฉพาะผู้ดูแล | `requireAdmin` ปฏิเสธลูกค้าที่เรียก URL เอง |
| QR ชำระ | แสดง QR/PromptPay ID/ยอด | ตรวจสถานะและคำนวณยอดจาก `order_detail` |
| เตือนการจอง | แสดงข้อความและเปิด push เมื่อมี Firebase | worker เป็นคนตัดสินเวลาที่ต้องแจ้งและ key กันซ้ำ |

### HTTP status และการแสดงข้อผิดพลาด

`200/201` หมายถึงสำเร็จ/สร้างใหม่, `400` ข้อมูลไม่ถูกต้องหรือกฎบางอย่างไม่ผ่าน, `401` ไม่มี/หมดอายุ token, `403` ไม่มีสิทธิ์หรือบัญชีถูกปิด, `404` ไม่พบข้อมูล, `409` สถานะ/ข้อมูลขัดแย้ง เช่น โต๊ะถูกจองไปแล้วหรือเมนูหยุดขาย, `413` JSON ใหญ่เกิน, `500` ความผิดพลาด server. Flutter [ApiService](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart) มักแปลง `message` ที่ server ส่งเป็น `Exception`; หน้าแสดงผ่าน SnackBar หรือ error widget. การ `return` หลัง `res.status(...).json(...)` สำคัญ เพราะไม่ให้ handler วิ่งต่อไปแก้ DB แม้ตอบ error แล้ว.

### ทำไมจึงมี `loading`/ตัวกันกดซ้ำ

หน้า [LoginPage:20](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:20), [PaymentPage:28](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:28), [AdminDashboardPage:19](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:19) มีตัวแปรสถานะขณะรอ API. หากกดสร้างออร์เดอร์หรือจองซ้ำระหว่างรอ อาจส่ง request หลายครั้ง เกิดรายการซ้ำ. UI ปิดปุ่ม/return ชั่วคราว; server ยังต้องมีกฎ/transaction เพิ่ม เพราะ client อื่นอาจยิงซ้ำได้. Admin `_savingReservationStatuses` และ `_savingOrderItemStatuses` กันการเปลี่ยนสถานะเดียวกันซ้ำระหว่าง save.

### รูปภาพอยู่ตรงไหน

รูปใน `flutter_application_1/assets` คือไฟล์ที่แพ็กไปกับแอปและเป็น fallback. เมนูที่เปิดขายมีภาพอาหาร/เครื่องดื่มตามชื่อใน `assets/menu`; คำสั่ง `npm run install-menu-photos` คัดลอกภาพชุดนี้ไป `my_app/storage/menu_images` และบันทึกชื่อไฟล์ใน DB. รูปโปรไฟล์/เมนู/แบนเนอร์/สลิปที่อัปโหลดเก็บเป็นไฟล์ใน `my_app/storage` ส่วน DB หรือ JSON config เก็บชื่อไฟล์. Flutter โหลดผ่าน API เช่น `/menu/:id/image`, `/users/:id/profile-image`, `/restaurant/banner/image`. การแยกเก็บช่วยไม่ต้องยัด binary ภาพลง SQL แถวหลัก; endpoint ที่เป็นรูปส่วนตัวหรือสลิปต้องตรวจสิทธิ์. โค้ด server จำกัดประเภท/ขนาดและทำชื่อไฟล์ที่ควบคุมได้ก่อนอ่านด้วย `path.basename` ในบางจุด เพื่อไม่ให้นำ input มาเป็น path ตามใจ. ภาพชุดตัวอย่างเป็นภาพสร้างให้ดูเหมือนภาพถ่าย ไม่ใช่ภาพถ่ายจานจริงของร้าน; แอดมินเปลี่ยนเป็นภาพของร้านได้.

### การแยก “สถานะ” หลายชนิด

อย่าพูดเพียงว่า “สถานะออร์เดอร์” แล้วรวมทุกอย่างเข้าด้วยกัน:

- `reservation_status` บอกผลของการจอง เช่น มาใช้บริการแล้วหรือยกเลิก.
- `table_status` บอกโต๊ะพร้อมให้บริการหรือไม่; `restaurant_table_session` บอกมีคนกำลังนั่งอยู่หรือไม่.
- `statusmenu_id` บอกทั้งเมนูยังขายไหม; `option.available` บอกตัวเลือกย่อยยังมีไหม.
- `food_status` ต่อจาน; `order_status` ทั้งออร์เดอร์; `payment_status_id` ของหลักฐานการโอน.

การมีหลายสถานะทำให้โมเดลตรงกับโลกจริง เช่น อาหารบางจานเสร็จแต่ทั้งออร์เดอร์ยังทำอยู่ หรือโต๊ะเปิดให้บริการแต่มีลูกค้านั่งอยู่แล้ว.

### ส่วนที่ยังไม่สมบูรณ์หรือควรตอบอย่างซื่อสัตย์

1. **Firebase**: [firebase_options.dart](/D:/Project_Main/flutter_application_1/lib/firebase_options.dart) ยังเป็น placeholder. หากไม่ได้รัน `flutterfire configure` และตั้ง Firebase Admin, push FCM ยังไม่ทำงาน แม้ประวัติการแจ้งเตือนใน DB ยังทำงานได้.
2. **Session ฝั่ง Flutter**: `CurrentUserService` และ `CartService` เป็น singleton ใน RAM; ปิด/รีสตาร์ตแอปแล้วต้อง login ใหม่และตะกร้าหาย. หากจะใช้งานจริงควรเพิ่ม secure storage สำหรับ token และพิจารณาบันทึกตะกร้าหรือ sync server.
3. **ยอดจองวันนี้ในแดชบอร์ด**: query [server.js:1752](/D:/Project_Main/my_app/server.js:1752) `COUNT(*) WHERE dining_date=CURRENT_DATE()` **นับทุกสถานะ** รวมยกเลิก ขณะที่ชื่อ UI ว่า “การจองวันนี้”. ถ้าอาจารย์ถามว่าหมายถึงจองสำเร็จเท่านั้นหรือไม่ ให้ตอบตาม query ว่าตอนนี้ยังรวมยกเลิก.
4. **กราฟยอดขาย**: ยอดรวม query ใช้ `payment_status_id=1` และวันที่ตั้งแต่ต้นเดือนโดย **ไม่มีเงื่อนไขปลายเดือน**; ในวันปัจจุบันปกติไม่มีข้อมูลอนาคตจึงดูเป็นเดือนนี้ แต่ถ้ามี row อนาคตจะถูกรวม. Query รายวันมีปลายเดือนแล้ว. นี่เป็นจุดปรับปรุงความแม่นของรายงาน.
5. **สลิป**: เป็นการตรวจด้วยคน ไม่ได้เชื่อม bank API, จึงไม่ควรพูดว่า “ระบบตรวจสลิป/เงินอัตโนมัติ”.
6. **หลาย HTTP ต่อออร์เดอร์**: หัวออร์เดอร์และรายละเอียดไม่ใช่หนึ่ง transaction ฝั่ง client; มีการพยายาม cancel เป็น compensation เมื่อผิดพลาด แต่ไม่รับประกัน atomic ทุกกรณี.
7. **เตือนล่วงหน้า**: ต้องเปิด backend ต่อเนื่อง; worker polling ทุก 30 วินาทีและ key กันซ้ำ. หาก worker หยุด/ฐานข้อมูลพลาดในช่วงที่ควรส่ง อาจพลาดข้อความ.
8. **ปี พ.ศ. กับข้อมูล API**: หัวปฏิทินเป็น พ.ศ.; ค่าที่เก็บและส่ง API เป็น ค.ศ. ไม่ควรนำ 2569 ส่งเป็นวันที่ SQL 2026.
9. **Android release**: [build.gradle.kts](/D:/Project_Main/flutter_application_1/android/app/build.gradle.kts) ยังใช้ `applicationId` ตัวอย่างและ `signingConfig` debug สำหรับ release; [AndroidManifest.xml](/D:/Project_Main/flutter_application_1/android/app/src/main/AndroidManifest.xml) อนุญาต cleartext HTTP เพื่อพัฒนา. การเผยแพร่จริงควรตั้ง application ID/keystore/HTTPS; ปัจจุบันอธิบายเป็นสภาพ dev.
10. **โปรไฟล์รูป**: อัปโหลดจำกัด 3 MB ที่ UI และต้องมี server validation อีกชั้น; หากรูปโหลดไม่ได้ ProfilePage แสดง avatar fallback.
11. **ชื่อ `getCompletedReservationsByUserId`**: ชื่อเมธอดอาจชวนเข้าใจผิด เพราะปัจจุบัน `view=history` ดึงทุกสถานะ ไม่ได้เฉพาะ “เสร็จสิ้น”. ควรพูดตาม behavior และถ้าจะ refactor ให้เปลี่ยนชื่อเป็น `getReservationHistoryByUserId`.
12. **ไฟล์ `food_data.dart` กับ field rating**: เป็นข้อมูลตัวอย่าง/โครงเดิม ไม่ใช่แหล่งข้อมูลเมนูหลัก; ดาวไม่แสดงในเมนูจริง. อธิบายตามโค้ด ไม่อ้างว่าระบบให้คะแนนอาหารใช้งานอยู่.
13. **ตะกร้าข้ามบัญชีใน process เดียวกัน**: ปุ่ม logout ใน [ProfilePage](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart) เรียก `CurrentUserService.clearUser()` แต่ไม่ได้เรียก `CartService.clear()`. เพราะตะกร้าเป็น singleton อีกตัว รายการเดิมอาจอยู่หากเปลี่ยนบัญชีในแอปโดยไม่ปิด process; นี่เป็นจุดที่ควรแก้ก่อนใช้งานหลายบัญชีบนเครื่องเดียว.
14. **CORS/HTTP สำหรับพัฒนา**: [server.js:121](/D:/Project_Main/my_app/server.js:121) เปิด `cors()` กว้าง และ Android manifest อนุญาต cleartext; เหมาะกับการพัฒนาในเครื่อง แต่ deployment จริงควรจำกัด origin และใช้ HTTPS เพื่อป้องกัน token/ข้อมูลเดินทางแบบไม่เข้ารหัส.
15. **หน้า Home ใช้คำว่า “เมนูยอดนิยม” แต่ยังไม่ได้เรียงยอดขาย**: [home_page.dart:336](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:336) โหลด `/menu`, กรอง แล้วแสดง 4 รายการแรก. หน้า [RestaurantStatsPage](/D:/Project_Main/flutter_application_1/lib/pages/restaurant_stats_page.dart) และแดชบอร์ด admin ต่างหากที่ใช้ยอดขายจริง. ถ้าถามชื่อหัวข้อ Home ให้ตอบตาม behavior และเสนอแก้ label หรือใช้ popular API.
16. **สถานะในหน้ารายละเอียดการจองคลาดเคลื่อน**: [reservation_detail_page.dart:253](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart:253) map 1/2/3/4 เป็น Pending/Confirmed/Cancelled/Completed แต่ DB ใช้ Confirmed/Cancelled/Served/Pending; หน้านี้ยังแสดง `tableId` แทนเลขโต๊ะ. หน้า History map ถูกต้อง. ควรรวม formatter สถานะและแก้เลขโต๊ะก่อนสาธิตหน้านี้.

---

## 8. ไฟล์ประกอบที่ควรรู้ก่อนเข้าสอบ

| ไฟล์/โฟลเดอร์ | จุดประสงค์และคำตอบเมื่อถูกถาม |
|---|---|
| [scripts/create_admin.js](/D:/Project_Main/my_app/scripts/create_admin.js) | อ่าน ADMIN_* จาก `.env`, bcrypt hash รอบ 12, สร้าง/เลื่อนสิทธิ์แอดมินหนึ่งบัญชีและกันสร้างแอดมินคนที่สอง; เป็น script ตั้งต้น ไม่ใช่ปุ่มสมัครแอดมินในแอป |
| [create_customer.js](/D:/Project_Main/my_app/create_customer.js), [create_test_user.js](/D:/Project_Main/my_app/create_test_user.js) | script ช่วยสร้างข้อมูลลูกค้า/ผู้ใช้สำหรับพัฒนา; ไม่ใช่เส้นทางหลักของ UI |
| [test_db.js](/D:/Project_Main/my_app/test_db.js), [test.http](/D:/Project_Main/my_app/test.http) | ใช้ตรวจการเชื่อมต่อ DB/เรียก API ระหว่างพัฒนา; ระวังใช้ endpoint กับข้อมูลจริง |
| [test/unit.test.js](/D:/Project_Main/my_app/test/unit.test.js) | unit tests สำหรับกฎ slot/วันอาทิตย์/ช่วงจอง, เตือน 60/10/0, ตัวเลือกอาหาร และ token/บัญชีถูกปิด; **การมีไฟล์ test ไม่เท่ากับผ่านทุกกรณี** |
| [test/widget_test.dart](/D:/Project_Main/flutter_application_1/test/widget_test.dart) | widget test ตรวจ Splash → Welcome โดยกดไอคอน; เป็นตัวอย่างทดสอบ UI ส่วนเล็ก |
| [analysis_options.yaml](/D:/Project_Main/flutter_application_1/analysis_options.yaml) | ตั้ง Flutter lint rules ช่วยเตือน style/ข้อผิดพลาดขณะเขียน |
| [android/app/build.gradle.kts](/D:/Project_Main/flutter_application_1/android/app/build.gradle.kts) | ตั้ง package/SDK/Java 17/version/signing สำหรับ Android |
| [android/app/src/main/AndroidManifest.xml](/D:/Project_Main/flutter_application_1/android/app/src/main/AndroidManifest.xml) | permission INTERNET, activity หลัก, อนุญาต HTTP ช่วงพัฒนา |
| `my_app/.env` | ความลับ/ค่าฐานข้อมูล/secret/PromptPay; **ไม่ควรเปิดโชว์รหัสในห้องสอบหรือ commit**. อ่านชื่อ key จาก `.env.example` แทน |
| `my_app/storage/` | เก็บรูปอัปโหลดและ config ที่แก้ในระบบ; ไม่ใช่ Flutter asset |

### คำศัพท์เทคนิคที่พูดกับอาจารย์ได้

- **REST API**: HTTP URL/verb แทนการอ่าน/สร้าง/แก้ข้อมูล; ตัวอย่าง POST `/api/reservations`.
- **Middleware**: ฟังก์ชันก่อน route เช่น `requireAuth`, `requireAdmin`.
- **Hash**: แปลงรหัสผ่านแบบย้อนกลับไม่ได้; `bcrypt.compare` ตรวจตอน login.
- **HMAC token**: ลายเซ็นพิสูจน์ว่า token ไม่ถูกแก้; ไม่ได้เข้ารหัสข้อมูลข้างใน จึงอย่าใส่ password ลง token.
- **Transaction**: หลาย SQL ต้อง commit พร้อมกันหรือ rollback พร้อมกัน.
- **Race condition**: คนสองคนกดจองโต๊ะเดียวกันพร้อมกัน; lock กับตรวจใน transaction ช่วยกัน.
- **Snapshot**: เก็บข้อมูล ณ ขณะนั้น เช่น ตัวเลือก/ราคาในรายการอาหาร และ preference ตอนสร้างแจ้งเตือน.
- **Soft delete**: ทำเครื่องหมายลบแทนลบ row เพื่อรักษาประวัติ.
- **Optimistic UI**: แสดงค่าที่เปลี่ยนก่อน server ตอบเพื่อให้ลื่น แล้ว reload/แก้กลับถ้าไม่สำเร็จ; ดู [AdminDashboardPage:106](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:106).
- **Fallback**: ใช้รูป/ข้อความสำรองเมื่อ server ไม่มีค่า หรือรูปโหลดผิด.
- **Idempotency**: เรียกซ้ำแล้วไม่สร้างผลซ้ำ; notification key ช่วยกันเตือนซ้ำ แต่ endpoint สร้างออร์เดอร์ยังไม่ได้มี idempotency key ครอบคลุมทุกกรณี.

---

## 9. โครงพูด 60 นาทีพร้อมจุดเปิดโค้ด

| เวลา | สิ่งที่พูด/สาธิต | เปิดไฟล์ |
|---|---|---|
| 0–5 นาที | ปัญหาและผู้ใช้ 2 บทบาท ลูกค้ากับแอดมิน; ฟีเจอร์หลัก | `main.dart`, `home_shell.dart`, `admin_dashboard_page.dart` |
| 5–10 นาที | สถาปัตยกรรม Flutter → HTTP/JSON → Express → MariaDB; เหตุผลแยกชั้น | `api_service.dart`, `server.js`, `db_pool.js` |
| 10–17 นาที | สมัคร/ล็อกอิน/role/token/bcrypt และสิทธิ์ | `signup_page.dart`, `login_page.dart`, `server.js:158/254`, `auth_token.js` |
| 17–26 นาที | ปฏิทิน 3 สี, วันหยุด, โต๊ะว่าง, การจองไม่ชนกัน, ประวัติ | `reservation_page.dart`, `booking_rules.js`, `models/reservation.js` |
| 26–35 นาที | หมวดอาหาร, option หมด, ตะกร้า, ราคา server | `food_menu_page.dart`, `food_detail_page.dart`, `menu_options.js`, `server.js:872` |
| 35–42 นาที | ออร์เดอร์ walk-in/จองและครัวเปลี่ยนสถานะ | `models/order.js`, `admin_dashboard_page.dart:640`, `server.js:1874` |
| 42–50 นาที | QR/PromptPay/สลิป/อนุมัติ/ยอดขายกราฟ | `payment_qr_page.dart`, `promptpay.js`, `models/payment.js`, `server.js:1752` |
| 50–55 นาที | notification แบบ in-app เทียบ push, เวลาล่วงหน้า, snapshot สี | `notifications.js`, `reservation_reminders.js`, `notification_inbox_page.dart` |
| 55–60 นาที | ข้อจำกัดจริงและแนวทางปรับปรุง, รับคำถาม | ส่วน 7 ของคู่มือนี้ |

**ตัวอย่างประโยคเชื่อมระหว่างไฟล์**: “เมื่อกดปุ่มยืนยันใน `ReservationPage`, `ApiService` สร้าง HTTP POST. Route ใน `server.js` ตรวจเวลาที่กรุงเทพและวันหยุด แล้วเรียก `reservationModel.createReservation`. Model ล็อกแถวโต๊ะใน transaction และบันทึกลง MariaDB. ผลลัพธ์กลับมาเป็น JSON; Flutter ใช้ ID ที่ได้ไปหน้ารายการอาหาร.” ถ้าพูดเส้นนี้คล่อง จะตอบคำถาม ‘หน้านี้เชื่อมตรงไหน’ ได้แทบทุกหน้า.

---

## 10. คำถามที่อาจารย์อาจถาม และแนวตอบที่ตรงกับโค้ด

### โครงสร้างและ UI

1. **ทำไมเลือก Flutter?** — โค้ด UI ชุดเดียวรองรับ web/Android และใช้ widget สร้างหน้าจอ; โปรเจกต์นี้มี `kIsWeb` ใน ApiService เพื่อเลือก host API ต่างกัน และมีโฟลเดอร์ `android` สำหรับ build โทรศัพท์. ไม่ต้องอ้างว่าส่งขึ้น store แล้ว เพราะ config ยังเป็นค่า development.
2. **UI เริ่มที่ไฟล์ไหน?** — [main.dart:8](/D:/Project_Main/flutter_application_1/lib/main.dart:8) เรียก `runApp(RestaurantApp)` และกำหนด `home: SplashPage`; จากนั้น Splash แตะไป Welcome, Login/SignUp, แล้วแยก HomeShell/AdminDashboard ตาม role.
3. **ทำไม HomeShell ใช้ `IndexedStack`?** — เวลาเปลี่ยนแท็บยังรักษา state/ตำแหน่ง/ข้อมูลที่โหลดของหน้าแต่ละแท็บ; `AppBottomNav` ไม่รู้จักเนื้อหาหน้า เพียงส่ง index กลับ. ข้อแลกเปลี่ยนคือทุกหน้าลูกค้าอยู่ใน tree พร้อมกันและใช้หน่วยความจำมากกว่าสร้างทีละหน้า.
4. **`setState` กับ `ChangeNotifier` ต่างกัน?** — `setState` อัปเดต state เฉพาะหน้า เช่น วันจอง/loading; `ChangeNotifier` ใช้ค่าร่วมหลายหน้า เช่น ผู้ใช้และตะกร้า แล้วผู้ฟัง rebuild เมื่อ notify.
5. **ทำไมเรียก `dispose()`?** — `TextEditingController` ถือ resource/listener; ต้องปล่อยเมื่อ widget หาย. ดู [LoginPage:26](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:26).
6. **ทำไมเช็ก `mounted` หลัง `await`?** — คำขอ HTTP อาจตอบกลับหลังปิดหน้า ถ้า `setState`/ใช้ context ตอนนั้นจะผิด lifecycle; จึงตรวจว่าหน้ายังอยู่.
7. **`FutureBuilder` มีสถานะอะไร?** — waiting แสดงโหลด, hasError แสดงข้อผิดพลาด, hasData แสดงข้อมูล; ดู [ReservationHistoryPage](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart) และ [PaymentQrPage](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart).
8. **รูปหน้าแรกเปลี่ยนได้จากไหน?** — แอดมินอัปโหลดและแก้ข้อความในแท็บจัดการ, API เก็บไฟล์และ config, HomePage โหลดจาก `/restaurant/banner`; ไม่มีค่าก็ใช้รูป asset/คำ “ร้านอาหาร”.
9. **ทำไมบาง widget แยกไฟล์?** — ปุ่ม/แถบล่าง/ช่องค้นหาที่ใช้ซ้ำควรมีพฤติกรรมและสไตล์เดียว ลด duplication. แต่การ์ดเมนูเฉพาะของหน้า FoodMenuPage อยู่ในไฟล์หน้านั้น เพราะมีบริบทการสั่งของหน้านั้น.

### บัญชีและความปลอดภัย

10. **ทำไมไม่เก็บรหัสผ่านตรง ๆ?** — ถ้าฐานข้อมูลรั่ว plain password ถูกใช้ทันที; bcrypt เก็บ hash และมี salt/work factor. Login ใช้ `bcrypt.compare`; token ใช้หลัง login แทนการส่งรหัสผ่านทุก request.
11. **token มีอะไร และปลอดภัยอย่างไร?** — payload มี user ID/role/เวลาเริ่ม/หมดอายุ, HMAC SHA-256 ลงลายเซ็นด้วย secret. Server ตรวจลายเซ็นและ `exp`, โหลดสถานะบัญชี/role จาก DB ใหม่. Payload decode ได้ ไม่ใช่การเข้ารหัส จึงไม่ใส่ข้อมูลลับ.
12. **ถ้า user แก้ `role_id` ใน Flutter จะเป็น admin ไหม?** — ไม่ได้ เพราะ route `/api/admin/...` ตรวจ token กับบัญชีจริงใน DB ผ่าน `requireAdmin`. การนำทาง UI ช่วย UX เท่านั้น.
13. **ถ้าแอดมินปิดบัญชี แต่ token ยังไม่หมดอายุ?** — `requireAuth` query `user` ทุก request และปฏิเสธ `is_active=0` หรือ `is_deleted=1` ทันที.
14. **ทำไมลบลูกค้าแบบ soft delete?** — ข้อมูลการจอง ออร์เดอร์ และชำระเงินอ้าง `user_id`; การลบจริงอาจทำให้ความสัมพันธ์/ประวัติหาย. `is_deleted=1` ปิดการใช้งานแต่เก็บ audit ย้อนหลัง.
15. **SQL injection ป้องกันอย่างไร?** — ข้อมูลจากผู้ใช้ส่งผ่าน `?` parameter; `mysql2` จัดการ escaping แทนการต่อ string SQL จาก input. กรณีสร้าง SQL dynamic เช่นจำนวน placeholder ของสถานะ ใช้จำนวนจาก constant ที่โค้ดควบคุม.
16. **ทำไมต้องตั้ง `AUTH_TOKEN_SECRET` 32 bytes?** — เป็นกุญแจ HMAC; ค่าสั้น/เดาง่ายทำให้ปลอม token ได้. [auth_token.js:4](/D:/Project_Main/my_app/libs/auth_token.js:4) ตรวจตอนเริ่ม server.

### จองและเวลา

17. **ทำไมต้องล็อกแถวตอนจอง?** — ถ้าสอง request อ่านว่าโต๊ะว่างพร้อมกันโดยไม่มี lock อาจ INSERT ชนกัน. Transaction + `FOR UPDATE` ทำให้ขั้นตรวจและเพิ่มเป็นลำดับสำหรับโต๊ะ/ลูกค้าที่เกี่ยวข้อง.
18. **โต๊ะว่างที่แสดงก่อนกด ยืนยันว่าจองได้แน่หรือไม่?** — ไม่แน่ เพราะมีคนอื่นจองหลังโหลดรายการได้. Server ตรวจอีกครั้งภายใต้ transaction และตอบ conflict ถ้าถูกแย่งไป.
19. **วันที่สีแดง/เขียว/เทาหมายถึงอะไร?** — แดงคืออาทิตย์หรือวันหยุดพิเศษที่ร้านปิด; เขียวคือวันที่อยู่ในช่วงเปิดรับจองตามกฎ; เทาคือนอกช่วง/ยังไม่กำหนด. มีเฉพาะเขียวที่กดได้. สีเขียวไม่ได้รับประกันโต๊ะว่าง.
20. **จำกัดจองถึงเมื่อไร?** — วันนี้ถึงอีก 2 วัน นับแบบวันปฏิทินกรุงเทพ, รอบเต็มชั่วโมง 09:00–13:00, ไม่รับวันอาทิตย์และวันหยุดพิเศษ. รอบของวันนี้ต้องยังไม่เริ่ม.
21. **ทำไม `booking_date` กับ `dining_date` แยกกัน?** — วันทำรายการอาจต่างจากวันที่จะไปใช้บริการ; ใช้วิเคราะห์/แสดงประวัติได้ถูก. Server สร้าง booking date ตามเวลาปัจจุบัน ไม่เชื่อค่าที่ client ส่ง.
22. **ประวัติการจองทำไมมีรายการยกเลิกด้วย?** — หน้า “จอง” ปกติกรอง active 1/4; หน้า “ประวัติ” ขอ `?view=history` แล้ว SQL ไม่กรองสถานะ จึงแสดงทุกผลให้ตรวจย้อนหลัง.
23. **ทำไมเวลาหน้า calendar เป็น พ.ศ. แต่ DB เป็น ค.ศ.?** — พ.ศ. ใช้แสดงให้ผู้ใช้ไทยอ่านง่าย; ISO `YYYY-MM-DD` ค.ศ. เหมาะกับ API/SQL และการคำนวณ. แปลงเฉพาะการแสดงปี.

### เมนู ออร์เดอร์ และข้อมูลราคา

24. **ตัวเลือก “หมด” ทำงานอย่างไร?** — แอดมินตั้ง `available=false` ใน JSON ของ option. Flutter disable ChoiceChip; server ตรวจ option ที่เลือกอีกครั้ง หากหมดคืน error. เมนูหลักยังขายได้ถ้าตัวเลือกอื่นตอบ requirement ได้.
25. **ทำไมเก็บ `selected_options` ลง order detail?** — เป็น snapshot ว่าลูกค้าเลือกอะไรและราคาเพิ่มเท่าไร ณ วันสั่ง; ต่อให้แอดมินเปลี่ยนชื่อ/ราคาเมนูภายหลัง ครัวยังเห็นรายการเดิม และราคาเก่าไม่เปลี่ยน.
26. **ถ้าคนแก้ราคาฝั่ง Flutter/HTTP เองจะเกิดอะไร?** — Backend ไม่รับราคาจาก client เป็นราคาจริง; โหลด base price จาก DB แล้วใช้ `resolveMenuSelections` คำนวณ extras. จึงลดโอกาสสั่งถูกกว่าราคาจริง.
27. **ทำไมต้องมี `order` กับ `order_detail`?** — หัวออร์เดอร์มีเจ้าของ/โต๊ะ/สถานะรวม; รายละเอียดมีแต่ละจาน จำนวน ตัวเลือก และสถานะครัว. ความสัมพันธ์หนึ่งต่อหลาย.
28. **การสั่งล่วงหน้ากับ walk-in ต่างกัน?** — แบบจองใช้ `reservation_id` ที่ตรวจเจ้าของและสถานะ; walk-in ใช้ `table_id` และเปิด/ใช้ `restaurant_table_session`. ทั้งสองลงตาราง order เดียวโดย `order_channel` แยกแหล่ง.
29. **ทำไมสถานะทั้งออร์เดอร์เปลี่ยนเมื่ออาหารทุกจานเสร็จ?** — QR ยังไม่ควรเปิดหากมีจานที่ยังทำอยู่; server นับรายการทั้งหมด/ที่เสร็จและสรุปสถานะ parent เป็น `รอชำระเงิน` เฉพาะเมื่อเสร็จทุกจาน.
30. **ทำไมหน้า `PaymentPage` ถึงยังไม่จ่าย?** — ชื่อไฟล์เก่าตาม flow แต่โค้ด `_confirmPayment` สร้างออร์เดอร์/รายการเท่านั้น. หน้าจ่ายจริงคือ `PaymentQrPage` หลังครัวทำเสร็จ. เป็นชื่อที่ควร refactor ในอนาคต.
31. **ถ้าส่งรายการอาหารจานที่สามล้มเหลวหลังสร้างสองจาน?** — Flutter พยายาม cancel order ใหม่; แต่เป็นหลาย HTTP call จึงไม่ atomic ทั้งชุด. ถ้าต้องการแข็งแรงกว่านี้ควรมี API เดียวรับหัวและรายการทั้งหมดแล้ว transaction เดียวใน DB.

### การชำระ สถิติ และแจ้งเตือน

32. **QR ใครคำนวณยอด?** — Server ดึง `order_detail` จาก DB แล้วรวม quantity×price; helper สร้าง PromptPay payload; Flutter แค่วาด QR. ป้องกันยอดถูกปรับจาก client.
33. **ส่งสลิปแล้วถือว่าจ่ายสำเร็จหรือยัง?** — ยัง. Payment เป็นสถานะ 3 รอตรวจ; แอดมินตรวจรูปและกดผ่านจึงเป็นสถานะ 1, order เป็น `ชำระแล้ว` และมี `paid_at`. ไม่มี bank API ยืนยันอัตโนมัติ.
34. **ยอดขายรายเดือนมาจากไหน?** — `SUM(payment.amount)` เฉพาะ `payment_status_id=1`; เมนูยอดนิยมมาจาก `order_detail` JOIN `order` ที่สถานะชำระแล้ว. กราฟใช้ยอดรวมแต่ละวัน. อย่าเอายอดตะกร้าหรือออร์เดอร์ที่ยังรอจ่ายมารวม.
35. **กระดิ่งสีส้ม/เทาอิง switch ปัจจุบันไหม?** — ไม่. อิง `notifications_enabled` ที่ snapshot ลงแต่ละ notification ตอนข้อความเกิด; ถ้าตอนนั้นเปิดเป็นส้ม ถ้าปิดเป็นเทา แม้เปลี่ยน switch ภายหลังสีเก่ายังเดิม.
36. **กดกระดิ่งแล้วมีอะไรเกิดขึ้น?** — ในหน้า inbox ไอคอนหุ้ม `IgnorePointer` และไม่มี callback; ตอนนี้กดไม่ได้ตาม requirement. API mark read มีอยู่แต่ UI ไม่ผูกกับไอคอนนี้.
37. **FCM ไม่ตั้งค่า จะไม่มีการแจ้งเตือนเลยไหม?** — ข้อความยังถูก INSERT ลง `customer_notification` และเห็นในกล่องข้อความ. ที่ขาดคือ push ไปโทรศัพท์นอกแอป. `main()` จับ error Firebase เพื่อไม่ให้แอปหยุด.
38. **เตือนก่อน 1 ชั่วโมงและ 10 นาทีอย่างไร?** — Node worker query active reservation ทุก 30 วินาทีในหน้าต่างเวลาที่กำหนด, สร้าง unique delivery key ต่อรายการ/ช่วงเวลา, แล้วเรียก notifyUser. มีเตือนเมื่อถึงเวลาจองด้วย.
39. **ทำไมต้องเก็บ `notification_delivery`?** — ถ้า worker ตรวจทุก 30 วินาทีโดยไม่มี key จะสร้างแจ้งเตือนเดิมซ้ำ. UNIQUE key + `INSERT IGNORE` ทำให้รอบเดิมส่งครั้งเดียวตาม intent.

### ประเมินงานและสิ่งที่จะปรับปรุง

40. **โปรเจกต์นี้ทดสอบอะไรอยู่แล้ว?** — มี Node unit tests ของ booking rules, menu options, reminder และ auth; มี Flutter widget test ของ Splash→Welcome. ยังไม่ได้อ้างว่าทุก flow ผ่าน end-to-end และคู่มือนี้เป็นการอ่านโค้ด ไม่ใช่ผลรันทดสอบ.
41. **ความเสี่ยงใหญ่สุดก่อนนำไปใช้งานจริง?** — ตั้ง Firebase/HTTPS/release signing และเก็บ token อย่างปลอดภัย, ทำ order+details ให้ atomic, เชื่อมการตรวจโอนจริงหากต้องการอัตโนมัติ, ติดตั้ง/สำรองฐานข้อมูล, เพิ่ม integration tests. ยกประเด็นที่เกี่ยวกับคำถาม ไม่ต้องบอกว่าทุกอย่างไร้บัค.
42. **ถ้าลูกค้าบอกประวัติจองว่าง ควรไล่ตรงไหน?** — เช็กว่า login เป็น user เดิม, `CurrentUserService.userId`, URL ที่เรียก `?view=history`, HTTP response, route ตรวจสิทธิ์, SQL `getReservationsByUserId(historyOnly:true)` และข้อมูลในตาราง reservation. ไม่สรุปทันทีว่า UI ผิด.
43. **ถ้าปฏิทินเป็นสีแดงแทบทุกวัน?** — ตรวจวันอาทิตย์/วันหยุดจาก API, ช่วงจองวันนี้ถึงอีก 2 วัน, เวลาเครื่อง/เซิร์ฟเวอร์/DB, เงื่อนไข `_statusFor`. สีแดงตามโค้ดควรเกิดจากวันปิด ส่วนวันนอกช่วงเป็นสีเทา.
44. **ทำไม API ต้องคืน error เป็น JSON?** — Flutter `jsonDecode` response; ถ้า Express คืน HTML error จะ parse พังและผู้ใช้ไม่เห็นข้อความจริง. 404/error handler กลางช่วยคืน `message` ที่หน้าแสดงได้.
45. **ถ้าอาจารย์ถามว่าปรับปรุงจุดใดก่อน?** — เลือกเรื่องที่มีผลต่อความถูกต้องมากสุด: API สร้าง order พร้อม details ใน transaction เดียวและ idempotency key; จากนั้น persistence ของ token/ตะกร้า, ตรวจสิทธิ์รูป, test ครบ flow, release config. อธิบายเหตุผลด้วยตัวอย่าง failure จริง.

---

## 11. วิธีไล่โค้ดเองระหว่างเตรียมสอบ

เมื่อสงสัย “ปุ่มนี้ทำอะไร” ให้ทำตามลำดับนี้:

1. ค้นคำบนปุ่มใน `flutter_application_1/lib/pages/` แล้วดู `onPressed` / `onTap` ว่าเรียกฟังก์ชันไหน.
2. ในฟังก์ชันนั้นดูว่ามี `ApiService.xxx` หรือใช้ `CurrentUserService`/`CartService` อย่างเดียว.
3. ถ้าเรียก API ให้ดู URL/HTTP verb ใน `api_service.dart` และ JSON fields ที่ส่ง.
4. ค้น route เดียวกันใน `my_app/server.js`; อ่าน middleware ก่อน handler, validation, `res.status`, model/helper ที่ถูกเรียก.
5. ไปอ่าน SQL ใน `my_app/models/` หรือกฎใน `my_app/libs/`; ดูตารางที่เปลี่ยน, transaction, error.
6. ย้อนจาก `return res.json` มาที่ `ApiService` และ `setState`/`FutureBuilder` ของหน้า ว่าผู้ใช้เห็นอะไรเมื่อสำเร็จหรือผิดพลาด.

**ตัวอย่างค้นด้วย PowerShell ในโฟลเดอร์โปรเจกต์**:

```powershell
rg -n 'ยืนยันการจอง|_confirmReservation|createReservation' flutter_application_1/lib
rg -n "app.post\('/api/reservations'|createReservation" my_app/server.js my_app/models
rg -n 'order_status|food_status|payment_status_id' my_app/server.js my_app/models
```

ลำดับนี้ช่วยตอบแบบอธิบายเหตุและผล ไม่ใช่ท่องว่า “มีปุ่มอยู่ไฟล์นั้น”. ก่อนสอบให้ฝึกพูด flow A–H โดยไม่มองคู่มือรอบหนึ่ง แล้วเปิดไฟล์เช็กจุดที่ยังจำสลับกัน.

---

## 12. ดัชนีฟังก์ชันสำหรับเปิดตอบคำถามทันที

### Flutter `ApiService`: เรียกอะไรจากจุดไหน

ไฟล์เดียว: [api_service.dart](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart). ตัวเลขในคอลัมน์แรกเป็นบรรทัดเริ่มต้นของเมธอด. เมธอดส่วนมากแปลง HTTP response เป็น `User`, `Food`, `Reservation` หรือ `Map` แล้วโยน `Exception` เมื่อ response ไม่ใช่ 2xx.

| บรรทัด/เมธอด | หน้าที่และหน้าเรียกหลัก |
|---|---|
| [15 `baseUrl`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:15), [22 `_headers`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:22) | เลือก host API และแนบ Bearer token; ทุกหน้าที่เรียก API ใช้ร่วมกัน |
| [31 `login`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:31), [59 `register`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:59) | LoginPage / SignUpPage |
| [90 `updateUser`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:90), [123 `updateProfileImage`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:123) | PersonalInformationPage |
| [136 `getReservationsByUserId`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:136), [141 `getCompletedReservationsByUserId`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:141), [165 `_getReservations`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:165) | BookingPage / ReservationHistoryPage; flag history เพิ่ม query parameter |
| [146 `uploadMenuImage`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:146) | AdminDashboardPage ฟอร์มเมนู |
| [153 `getRestaurantBanner`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:153), [162 `restaurantBannerImageUrl`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:162) | HomePage |
| [199 `createReservation`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:199), [245 `getReservationById`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:245) | ReservationPage / ReservationDetailPage |
| [276 `getMenus`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:276), [305 `getTables`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:305), [369 `getWalkInTables`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:369) | Home/Menu/เลือกโต๊ะ |
| [335 `createOrder`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:335), [383 `createOrderDetail`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:383) | PaymentPage ตอนยืนยันสั่ง |
| [433 `getAvailability`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:433), [451 `cancelReservation`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:451), [461 `getHolidays`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:461) | ReservationPage/BookingPage/ปฏิทิน |
| [477 `getOrdersByUserId`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:477), [491 `getOrderDetails`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:491), [502 `updateOrderDetail`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:502), [525 `cancelOrder`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:525) | OrderHistoryPage และ compensation ใน PaymentPage |
| [535 `getPopularMenus`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:535) | RestaurantStatsPage |
| [548 `getPaymentQr`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:548), [560 `submitPaymentSlip`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:560), [571 `getPaymentStatus`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:571) | PaymentQrPage |
| [580 `registerPushDevice`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:580), [590 `getNotificationPreference`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:590), [602 `setNotificationPreference`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:602) | NotificationService/Profile switch |
| [615 `getNotifications`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:615), [626 `markNotificationRead`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:626) | NotificationInboxPage ใช้ตัวแรก; ตัวหลังมี API รองรับแต่หน้าไม่ได้ผูกกับกระดิ่ง |
| [635–641 `adminGet/Post/Put/Patch/Delete/_adminRequest`](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:635) | AdminDashboardPage; helper กลางใช้ `http.Request` สำหรับ verb ต่าง ๆ |

### Flutter `AdminDashboardPage`: โค้ดส่วนไหนของแต่ละแท็บ

| บรรทัด/ฟังก์ชัน | ความหมาย |
|---|---|
| [19–43 state](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:19) | `index`, loading/error, list จอง/ครัว/สลิป/ลูกค้า/วันหยุด/เมนู/โต๊ะ และ controller ต่าง ๆ |
| [44 `initState`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:44), [50 `dispose`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:50) | เริ่มโหลดและปล่อย controller |
| [63 `_load`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:63) | `Future.wait` 10 endpoint, แปลงผลเข้าตัวแปร state; หาก endpoint หนึ่งผิด `Future.wait` ล้มทั้งรอบและขึ้น error/loading ตาม flag |
| [106 `_changeReservation`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:106), [128 `_changeFoodStatus`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:128), [151 `_acceptOrder`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:151), [170 `_reviewPayment`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:170) | action ของแท็บจอง/ครัว/ชำระ |
| [178 `_addHoliday`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:178), [384 `_pickHolidayDate`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:384) | เพิ่มวันหยุดและเลือกวัน |
| [194 `_changeRestaurantBanner`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:194), [231 `_saveRestaurantBannerTitle`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:231) | เปลี่ยนรูป/ข้อความหน้าแรก |
| [251 `_savePromptPayId`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:251) | เก็บเบอร์/เลข 13 หลักที่ QR ใช้ |
| [275 `_toggleCustomer`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:275), [283 `_editCustomer`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:283), [322 `_resetCustomerPassword`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:322), [361 `_deleteCustomer`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:361) | จัดการบัญชีลูกค้า |
| [395 `_editMenu`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:395), [457 `_cancelMenu`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:457) | เพิ่ม/แก้เมนู และหยุดขายโดยเปลี่ยน `statusmenu_id` เป็น 2; ไม่ลบประวัติออร์เดอร์ |
| [484 `_editTable`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:484) | เพิ่ม/แก้โต๊ะ |
| [515 `build`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:515), [532 `_dashboard`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:532) | สร้าง scaffold แท็บและภาพรวม |
| [550 `_reservations`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:550), [568 `_dateSections`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:568), [600 `_timeBadge`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:600) | กลุ่มรายการตามวัน, ป้ายเวลาแยกชัด |
| [626 `_selectedOptionsText`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:626), [640 `_kitchen`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:640) | แปลง JSON ตัวเลือกเป็นข้อความให้ครัวและแสดงรายการ |
| [666 `_payments`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:666), [694 `_management`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:694) | สลิปและการตั้งค่าร้าน |
| [1041 `_SalesChart`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1041), [1063 `_SalesChartPainter`](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1063) | widget กราฟ/วาดเส้นจากข้อมูลรายวันบน `Canvas` |

### Backend models: เมธอด SQL ที่ควรเปิดเมื่ออาจารย์ถาม

| ไฟล์ | ฟังก์ชันหลักและบรรทัด |
|---|---|
| [models/user.js](/D:/Project_Main/my_app/models/user.js) | `getAllUsers` [5](/D:/Project_Main/my_app/models/user.js:5), `getUserByUsername` [52](/D:/Project_Main/my_app/models/user.js:52), `getUserByPhone` [102](/D:/Project_Main/my_app/models/user.js:102), `getUserById` [110](/D:/Project_Main/my_app/models/user.js:110), `createUser` [159](/D:/Project_Main/my_app/models/user.js:159), `updateUser` [207](/D:/Project_Main/my_app/models/user.js:207), `updateProfileImage` [258](/D:/Project_Main/my_app/models/user.js:258) |
| [models/table.js](/D:/Project_Main/my_app/models/table.js) | `getAllTables` [5](/D:/Project_Main/my_app/models/table.js:5), `getWalkInTables` [53](/D:/Project_Main/my_app/models/table.js:53), `clearWalkInSession` [76](/D:/Project_Main/my_app/models/table.js:76), `updateTable` [84](/D:/Project_Main/my_app/models/table.js:84), `createTable` [92](/D:/Project_Main/my_app/models/table.js:92) |
| [models/reservation.js](/D:/Project_Main/my_app/models/reservation.js) | `createReservation` [6](/D:/Project_Main/my_app/models/reservation.js:6), `getAvailableTables` [125](/D:/Project_Main/my_app/models/reservation.js:125), `isRestaurantHoliday` [153](/D:/Project_Main/my_app/models/reservation.js:153), `getHolidays` [161](/D:/Project_Main/my_app/models/reservation.js:161), `getReservationById` [169](/D:/Project_Main/my_app/models/reservation.js:169), `getReservationsByUserId` [213](/D:/Project_Main/my_app/models/reservation.js:213), `cancelForUser` [265](/D:/Project_Main/my_app/models/reservation.js:265), `getAdminReservations` [294](/D:/Project_Main/my_app/models/reservation.js:294) |
| [models/menu.js](/D:/Project_Main/my_app/models/menu.js) | `DEFAULT_OPTION_GROUPS` [3](/D:/Project_Main/my_app/models/menu.js:3), `parseGroups` [18](/D:/Project_Main/my_app/models/menu.js:18), `getAllMenu` [34](/D:/Project_Main/my_app/models/menu.js:34), `getMenuById` [80](/D:/Project_Main/my_app/models/menu.js:80), `createMenu` [126](/D:/Project_Main/my_app/models/menu.js:126), `updateMenu` [134](/D:/Project_Main/my_app/models/menu.js:134), `deleteMenu` [142](/D:/Project_Main/my_app/models/menu.js:142) |
| [models/order.js](/D:/Project_Main/my_app/models/order.js) | `createOrder` [5](/D:/Project_Main/my_app/models/order.js:5), `getOrderById` [115](/D:/Project_Main/my_app/models/order.js:115), `getOrdersByUserId` [163](/D:/Project_Main/my_app/models/order.js:163), `updateStatus` [217](/D:/Project_Main/my_app/models/order.js:217), `getAdminOrders` [225](/D:/Project_Main/my_app/models/order.js:225) |
| [models/order_detail.js](/D:/Project_Main/my_app/models/order_detail.js) | `createOrderDetail` [5](/D:/Project_Main/my_app/models/order_detail.js:5), `getOrderDetails` [102](/D:/Project_Main/my_app/models/order_detail.js:102), `getOrderDetailsByOrderId` [152](/D:/Project_Main/my_app/models/order_detail.js:152), `updateFoodStatus` [208](/D:/Project_Main/my_app/models/order_detail.js:208), `getAdminOrderDetails` [216](/D:/Project_Main/my_app/models/order_detail.js:216) |
| [models/payment.js](/D:/Project_Main/my_app/models/payment.js) | `createSlipReview` [4](/D:/Project_Main/my_app/models/payment.js:4), `reviewPayment` [49](/D:/Project_Main/my_app/models/payment.js:49), `getPaymentForOrder` [87](/D:/Project_Main/my_app/models/payment.js:87), `getAdminPayments` [99](/D:/Project_Main/my_app/models/payment.js:99) |

### สรุปสามประโยคสุดท้ายสำหรับปิดการนำเสนอ

“ระบบนี้แยก Flutter ซึ่งรับ input/แสดง UI ออกจาก Express ที่ตรวจสิทธิ์ กฎร้าน และความถูกต้องของราคา ก่อนเขียน MariaDB. เส้นทางหลักตั้งแต่จองโต๊ะจนถึงชำระเงินจริงเชื่อมด้วย ID และสถานะที่ตรวจซ้ำใน server โดยใช้ transaction ในจุดเสี่ยงแข่งกัน. สิ่งที่ต้องปรับก่อนใช้งานจริงคือการตั้ง Firebase และ release security, การเก็บ session อย่างปลอดภัย, และรวมการสร้างออร์เดอร์ทุกจานให้เป็น transaction เดียว.”

---

## 13. อ่านบรรทัดสำคัญแบบ “โค้ดนี้มีไว้ทำไม”

### `main()` และ lifecycle ของ Flutter

ที่ [main.dart:8](/D:/Project_Main/flutter_application_1/lib/main.dart:8):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.initialize();
  } catch (error) {
    debugPrint('Firebase is not configured yet: $error');
  }
  runApp(const RestaurantApp());
}
```

- `Future<void>` เพราะมีงาน asynchronous ก่อนเริ่ม UI; `void` คือไม่มีค่าผลลัพธ์ที่ต้องคืน.
- `ensureInitialized` เตรียม Flutter binding ให้ plugin/Firebase ใช้ก่อนวาดหน้าจอ.
- `await` ทำให้ตั้ง Firebase ก่อน `runApp`; ถ้าล้ม `catch` บันทึก error แล้วแอปยังเปิดได้. ดังนั้น “แอปเปิดได้” **ไม่พิสูจน์ว่า FCM พร้อม**.
- `const RestaurantApp()` ให้ Flutter reuse object immutable ในจุดที่ทำได้; `MaterialApp` ตั้ง theme และหน้าแรก.

### เงื่อนไข token ใน header

ที่ [api_service.dart:22](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart:22):

```dart
final token = CurrentUserService.instance.user?.authToken;
return {
  'Content-Type': 'application/json',
  if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
};
```

`?.` อ่าน `authToken` เฉพาะเมื่อ `user` ไม่ null. `if` ใน Map เป็น collection-if ของ Dart; key Authorization มีเฉพาะเมื่อมี token. Content-Type บอก server ว่า body เป็น JSON. คำว่า Bearer เป็นรูปแบบของ authorization header; server ตัดคำนี้ก่อน verify. นี่เป็นการส่งตัวตน ไม่ใช่การอนุญาตอัตโนมัติ—server ยังตรวจ role/สถานะเอง.

### การรวมรายการตะกร้า

ที่ [cart_service.dart](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart), `_items.indexWhere(...)` หารายการเดิมโดยดู ID เมนูและตัวเลือกทุกชนิด รวม `jsonEncode(selectedOptions)` กับหมายเหตุ. ถ้าไม่พบ (`index == -1`) เพิ่ม `CartItem` ใหม่; ถ้าพบเพิ่ม quantity; สุดท้าย `notifyListeners()` เพื่อให้ widget ที่ฟังอยู่รู้ว่าต้องวาดใหม่. `List.unmodifiable(_items)` ใน getter กันโค้ดหน้าจอแก้ list โดยไม่ผ่าน service เพราะจะข้ามการแจ้ง listener. `fold` ใช้สะสมจำนวนหรือยอดรวมจากทุก item.

**ตัวอย่างความแตกต่าง**: ข้าวผัดธรรมดา 2 จานรวมเป็น 1 CartItem quantity 2 แต่ข้าวผัดหนึ่งจานเพิ่มไข่และอีกจานไม่เพิ่มไข่ต้องเป็น 2 CartItem เพราะครัวต้องเห็นตัวเลือกต่างกัน.

### การจองแบบ transaction

ที่ [models/reservation.js:6](/D:/Project_Main/my_app/models/reservation.js:6) ลำดับสำคัญคือ `getConnection → beginTransaction → SELECT user FOR UPDATE → SELECT table FOR UPDATE → ตรวจชน → INSERT → commit`, และเมื่อเกิด error `rollback`, สุดท้าย `release`. ต้องใช้ **connection เดียว** ตั้งแต่ begin ถึง commit เพราะ transaction ผูกกับ connection. ถ้าใช้ `pool.query` แยกครั้งโดยไม่ถือ connection เดิม จะไม่อยู่ใน transaction เดียวกัน. Lock user ป้องกันผู้ใช้คนเดิมสร้างสองรายการใน slot เดียวกันคนละโต๊ะ; lock table ป้องกันสองคนจองโต๊ะเดียวกันพร้อมกัน.

### ตัวเลือกอาหารและราคาจริง

ที่ [libs/menu_options.js:26](/D:/Project_Main/my_app/libs/menu_options.js:26) `chosenByGroup` เป็น `Map` เก็บตัวเลือกของแต่ละกลุ่ม, `snapshot` เป็นข้อมูลที่บันทึกลง order detail. Loop แรกเช็กว่า `group_id`/`option_id` มีในเมนูจริง, ยังไม่ sold out, ไม่ซ้ำ; Loop หลังเช็กทุกกลุ่มว่าที่บังคับต้องมีอย่างน้อย 1 และไม่เกิน `max_select`. `reduce` รวม `extra_price`. เหตุผลที่ต้องมี loop หลังคือถ้า client ส่ง selections เป็น array ว่าง Loop แรกไม่วิ่งเลย แต่ยังต้องจับว่ากลุ่มบังคับไม่ได้เลือก.

### กราฟยอดขาย

ที่ [admin_dashboard_page.dart:1041](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1041) แปลง `daily_sales` เป็น Map วันที่→ยอด แล้วสร้าง list ของ **ทุกวันในเดือน** โดยวันไม่มีรายได้เป็น 0. [CustomPainter:1063](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1063) วาดเส้น grid, หา `maxValue` เป็นสเกลแนวตั้ง, จุด X ตามลำดับวันที่, จุด Y เป็น `ยอด/maxValue` จากด้านล่างกราฟ, แล้วเชื่อมด้วย `Path.lineTo`. ถ้าทุกค่า 0 จะไม่วาดเส้นยอดขายเพื่อหลีกเลี่ยงหารด้วย 0. `shouldRepaint` บอก Flutter เมื่อข้อมูลกราฟเปลี่ยนควรวาดใหม่.

### วิธีอ่าน SQL รายงานรายเมนู

ที่ [server.js:1752](/D:/Project_Main/my_app/server.js:1752), `JOIN order_detail od JOIN menu m JOIN order o` ทำให้รู้ทั้งจำนวนจาน ชื่อเมนู และสถานะชำระ. `WHERE o.order_status='ชำระแล้ว'` ตัดออร์เดอร์ที่ยังไม่ได้เงิน, `GROUP BY m.menu_id, m.menu_name` รวมรายการเมนูเดียวกัน, `SUM(od.quantity)` เป็นจำนวนจาน, `SUM(od.quantity*od.price)` เป็นยอดต่อเมนู, `ORDER BY plates DESC LIMIT 10` เอา 10 เมนูยอดนิยม. `NULLIF(ยอดรวม,0)` ในการหารเปอร์เซ็นต์ป้องกันหารด้วยศูนย์. ถ้าราคาเมนูปัจจุบันเปลี่ยน รายงานยังใช้ราคาใน order detail ณ วันซื้อ.

### ตั้งค่ารูปและบัญชีรับเงินทำไมแยกจาก DB

ที่ [server.js:69](/D:/Project_Main/my_app/server.js:69)–[114](/D:/Project_Main/my_app/server.js:114) อ่าน/เขียน `storage/payment_settings/settings.json` และ `storage/restaurant_banner/banner.json`. เขียนไฟล์ชั่วคราวแล้ว rename เพื่อลดโอกาสไฟล์ config ถูกอ่านตอนเขียนค้างครึ่งเดียว. PromptPay ID จาก config มาก่อน `.env` หากถูกต้อง; หากไม่มีใช้ env fallback. นี่เป็นการเลือกเก็บค่าตั้งร้านในไฟล์ ไม่ใช่ตาราง SQL; ข้อแลกเปลี่ยนคือเวลา deploy หลายเครื่องต้องแชร์ storage/ซิงก์ config ให้ตรงกัน.
