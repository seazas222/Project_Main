# แผนที่ทุกหน้าจอ Restaurant App สำหรับสอบแบบชี้หน้าจอ

อ่านคู่กับ [คู่มือสถาปัตยกรรมและคำถามสอบ](/D:/Project_Main/PROJECT_INTERVIEW_GUIDE_TH.md) เอกสารนี้เรียงตาม **สิ่งที่เห็นบนหน้าจอ** แล้วตอบต่อทันทีว่าอยู่ไฟล์/บรรทัดใด เกิดจาก state อะไร กดแล้วไปไหน เรียก API ใด และเหตุใดต้องมีเงื่อนไขนั้น อ้างอิงโค้ดใน `D:\Project_Main` วันที่ 14 ตุลาคม 2026. ลิงก์ `:เลข` คือบรรทัดเริ่มต้น ให้เลื่อนอ่านรอบ ๆ บรรทัดนั้นด้วย

## วิธีตอบเมื่ออาจารย์ชี้จุดใดจุดหนึ่ง

ใช้ประโยค 5 ส่วน: **“สิ่งนี้คืออะไร → UI อยู่ในไฟล์/บรรทัด → ผู้ใช้ทำอะไรได้ → ฟังก์ชัน/API/ตารางที่เชื่อม → เงื่อนไข/เหตุผล”** ตัวอย่าง: “กระดิ่งนี้อยู่ `notification_inbox_page.dart:54`; เป็น `IgnorePointer` จึงกดไม่ได้ สีอ่านจาก `notifications_enabled` ที่บันทึกตอนเกิดข้อความใน `customer_notification` ไม่ใช่ค่า switch ปัจจุบัน”

## เส้นทางหน้าจอทั้งแอป

```text
main → Splash (แตะ) → Welcome → Login / SignUp
                                  ├─ role 2 → HomeShell: Home | Menu | Booking | Profile
                                  │              Home → จองโต๊ะ → Menu แบบ reservation
                                  │              Home → สั่งที่ร้าน → เลือกโต๊ะ → Menu แบบ walk-in
                                  │              Menu → รายละเอียดอาหาร → ตะกร้า → ยืนยันออร์เดอร์
                                  │                                              → หน้าสำเร็จ
                                  │              Profile → ข้อมูลส่วนตัว | ประวัติจอง → รายละเอียดจอง
                                  │                      | แจ้งเตือน | ประวัติออร์เดอร์ → QR
                                  │                      | สถิติเมนูยอดนิยม
                                  └─ role 1 → AdminDashboard: ภาพรวม | จอง | ครัว | ชำระ | จัดการ
```

`HomeShell` ใช้ [IndexedStack](/D:/Project_Main/flutter_application_1/lib/pages/home_shell.dart:26) เก็บ state ของ 4 แท็บลูกค้า; แอดมินใช้ [NavigationBar](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:515) ของตัวเอง. หน้าที่เปิดด้วย `Navigator.push` มีปุ่มย้อนกลับตาม navigation stack. หลัง login และหลังยืนยัน order ใช้ `pushAndRemoveUntil` เพื่อไม่กลับไปขั้นก่อนหน้าเมื่อกด Back.

---

## 1. หน้า Splash → Welcome → Login → Sign up

### Splash — [splash_page.dart:23](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart:23)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รูปเต็มจอ | `Image.asset('assets/restaurant.jpg')` และ `BoxFit.cover` ยืดรูปให้เต็มกรอบ; asset ต้องลงใน `pubspec.yaml`. ภาพนี้เป็นไฟล์ติดตั้งแอป ไม่ใช่แบนเนอร์ที่ admin เปลี่ยนได้ |
| ชั้นสีดำโปร่ง | `Stack` ซ้อน `Container(color: black.withValues(alpha:.52))` ทับรูปเพื่อให้ตัวหนังสือขาวอ่านชัด; `StackFit.expand` ขยายทุกชั้นเต็มจอ |
| ไอคอนร้าน ชื่อ “ร้านอาหาร” และข้อความ “Reserve • Order • Enjoy” | สร้างด้วย `Center → Column`; ส่วนนี้เป็น static text ยังไม่อ่านค่าชื่อแบนเนอร์จาก server. ชื่อที่ admin เปลี่ยนจะแสดงบน **หน้า Home hero** ไม่ใช่ Splash |
| แตะตรงไหนของหน้าก็ไปต่อ | [GestureDetector/onTap:25](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart:25) เรียก [_goToWelcome:13](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart:13) และ `Navigator.pushReplacement` แทน Splash ด้วย Welcome; ไม่มี timer ไปเอง |

### Welcome — [welcome_page.dart:11](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:11)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| พื้นหลังครีม/โลโก้ร้าน | สีจาก `AppColors.cream` ใน `core/app_theme.dart`; โลโก้เป็น `Container` วงกลมกับไอคอน ไม่ใช่รูปที่ upload |
| ข้อความต้อนรับ | Text คงที่ใน `Column`; `SingleChildScrollView` ให้หน้าสั้น/คีย์บอร์ดไม่ล้น, `ConstrainedBox(maxWidth:390)` กันฟอร์มยืดกว้างเกินบนเว็บ |
| ปุ่ม Log in | [onPressed:68](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:68) `Navigator.push` ไป LoginPage; ไม่มี HTTP จนกด login จริง |
| ปุ่ม Sign up | [onPressed:78](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart:78) ไป SignUpPage |

### Login — [login_page.dart:80](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:80)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| ลูกศรย้อนกลับ | `Navigator.pop(context)` กลับ Welcome |
| Username/Password | `TextEditingController` ที่ [บรรทัด 19–20](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:19) ถือข้อความจาก TextField; `dispose()` ปล่อย controller เมื่อหน้าเลิกใช้ |
| รูปตาในรหัสผ่าน | [suffixIcon:134](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:134) กลับค่า `hide` ด้วย `setState`, `obscureText: hide` จึงซ่อน/แสดงตัวอักษร ไม่เปลี่ยนรหัสใน DB |
| ปุ่ม Log in/กำลังเข้าสู่ระบบ | [บรรทัด 153](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:153) เมื่อ `loading` ปุ่ม disabled เพื่อกัน request ซ้ำ; [_login:32](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart:32) เช็กค่าว่างก่อน POST `/api/login` |
| หลัง login สำเร็จ | `User.fromJson` จาก API เก็บใน `CurrentUserService`; ลองลงทะเบียน push; role 1 ไป AdminDashboard, role อื่นไป HomeShell; ล้าง stack เดิมเพื่อกัน Back กลับหน้า login |
| “Sign up” ด้านล่าง | เปิด SignUpPage อีกทางหนึ่ง |
| ข้อผิดพลาด | `catch` แสดง server `message` ผ่าน SnackBar; ถ้าหน้าถูกปิดระหว่างรอ ใช้ `mounted` ก่อน `setState`/navigation |

### Sign up — [signup_page.dart:130](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:130)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| ชื่อผู้ใช้/ชื่อจริง/โทรศัพท์/อีเมล | TextField แต่ละตัวมี controller. โทรศัพท์ใช้ `FilteringTextInputFormatter.digitsOnly` กับ `maxLength:10`; อีเมลไม่บังคับ |
| รหัสผ่าน/ยืนยันรหัสผ่าน + รูปตา | ตัวแปร `hidePassword`/`hideConfirm` แยกกัน; กดตาแก้ `obscureText` ของช่องนั้น |
| ปุ่มสมัครสมาชิก | [_signUp:41](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:41) ตรวจช่องจำเป็น รหัสตรงกัน username อย่างน้อย 3 รหัสอย่างน้อย 8 เบอร์ 10 หลัก; [_completeSignUp:81](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart:81) ส่ง POST `/api/register` และเข้าหน้าลูกค้า |
| ทำไมตรวจที่ backend ซ้ำ | กฎ UI เป็น feedback; [server.js:254](/D:/Project_Main/my_app/server.js:254) ต้องตรวจรูปแบบ/ซ้ำ/ความยาวจริง, normalize เบอร์, bcrypt hash และสร้าง role 2; client ที่ยิง API เองจะข้าม UI ได้ |

---

## 2. แถบลูกค้าและหน้า Home

### แถบล่าง — [home_shell.dart:26](/D:/Project_Main/flutter_application_1/lib/pages/home_shell.dart:26), [app_bottom_nav.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_bottom_nav.dart)

ปุ่ม Home/Menu/Booking/Profile มีเลข index 0/1/2/3. `AppBottomNav` รับ `currentIndex` แล้วเปลี่ยนสีไอคอน/ข้อความเป็นส้มเมื่อเลือก; กดแล้ว callback `onChanged(index)` ให้ HomeShell `setState` เปลี่ยนหน้าใน IndexedStack. เมนูแท็บ `FoodMenuPage()` ที่เปิดจากแถบล่าง **ยังไม่มี reservationId/tableId** จึงใช้ดูอาหารได้ แต่จะเข้า detail เพื่อสั่งต้องมีบริบทโต๊ะ.

### Home — [home_page.dart:184](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:184)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รูปหน้าร้าน/ชื่อบนรูป | [_Hero:569](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:569) รับ `bannerImage/bannerTitle`. [_loadRestaurantBanner:74](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:74) GET `/restaurant/banner`; รูปผ่าน `/restaurant/banner/image`. ไม่มีค่า/โหลดเสียใช้ `assets/restaurant.jpg` กับ “ร้านอาหาร”. `Stack` ซ้อน gradient สีดำเพื่อให้อ่านข้อความขาว |
| ปุ่ม “จองโต๊ะ” บนภาพ | callback [_openReservation:173](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:173) ไป ReservationPage |
| ปุ่ม “ดูเมนู” บนภาพ | [_openFoodMenu:97](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:97) ไป FoodMenuPage พร้อม keyword/category ปัจจุบัน แต่ยังไม่มีโต๊ะ; ดูได้ก่อนสั่ง |
| ปุ่ม “สั่งอาหารที่ร้าน” | [_openWalkInOrder:109](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:109) GET `/walk-in/tables`, เปิด bottom sheet “เลือกโต๊ะที่นั่งอยู่”, แสดงหมายเลข/ความจุ. เลือกแล้วเปิด FoodMenuPage พร้อม `walkInTableId`. ถ้าไม่มีโต๊ะ/โหลดผิด แสดง SnackBar |
| ไอคอนถุงอาหารพร้อมเลข | [AnimatedBuilder:223](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:223) ฟัง `CartService.itemCount`; ปุ่มบน Home เรียก `_showReservationMessage` ซึ่งบอกให้จองโต๊ะก่อน ไม่ได้เปิดตะกร้าจากจุดนี้ |
| ช่องค้นหาและไอคอนกรอง | [AppSearchField:272](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:272) `onChanged` เก็บ keyword ใน state; `_openHomeCategoryFilter` แสดง bottom sheet ทั้งหมด/ข้าว/เส้น/อื่น ๆ. การกรองทำบน list ที่โหลดมาแล้ว ไม่ยิง API ทุกตัวอักษร |
| การ์ด “การจองโต๊ะ” | [_ReservationPreview:806](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:806) เป็นทางลัดไป ReservationPage; ข้อความ “ดูรายละเอียดการจองของคุณ” บนการ์ดเป็น static, onTap จริงพาไปหน้าจองใหม่ |
| “เมนูยอดนิยม / ดูทั้งหมด” | [SectionHeader](/D:/Project_Main/flutter_application_1/lib/widgets/section_header.dart) กดดูทั้งหมดไป FoodMenuPage. [FutureBuilder:336](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart:336) รอ GET `/menu`, error มี “ลองใหม่”, ไม่มีผลมี “ไม่พบเมนู” |
| การ์ดอาหาร 4 ใบ | กรอง keyword/category แล้ว `.take(4)` จากรายการเมนูที่โหลดมา; **ไม่ได้เรียงตามยอดขาย** แม้หัวข้อชื่อ “เมนูยอดนิยม”. [FoodCard](/D:/Project_Main/flutter_application_1/lib/widgets/food_card.dart) แสดงรูป/ชื่อ/ราคาและปุ่ม Add แต่แตะหรือ Add ใน Home จะขึ้นข้อความให้จองโต๊ะก่อน |

**ข้อมูลหน้า Home เชื่อมกันอย่างไร**: แบนเนอร์จากไฟล์ config ใน backend, เมนูจากตาราง `menu`, badge จากตะกร้าใน RAM, โต๊ะ walk-in จาก `table` + `restaurant_table_session` + reservation รอบปัจจุบัน. จึงไม่ใช่ทุกชิ้นบนหน้าเดียวมาจากฐานข้อมูลแหล่งเดียว.

---

## 3. หน้าเมนู → รายละเอียด → ตะกร้า → ยืนยันรายการ

### Food Menu — [food_menu_page.dart:221](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:221)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| ชื่อ “รายการอาหาร” | `AppBar` ของหน้านี้; [initState:47](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:47) รับ keyword/category เริ่มต้นและเรียก [_loadMenus:55](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:55) GET `/menu` |
| ไอคอน tune มุมบน | [_openCategoryPicker:114](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:114) เปิด bottom sheet เลือกหมวด; สีส้มเมื่อหมวดไม่ใช่ “ทั้งหมด” |
| ถุงอาหารและเลขสีส้ม | ฟัง `CartService.itemCount`; [_openCart:168](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:168) ต้องมีบริบทโต๊ะ และตะกร้าไม่ว่าง จึงเปิด CartPage; ไม่ผ่านแสดง SnackBar |
| แถบโต๊ะด้านบน | แสดงเฉพาะ `hasOrderContext` ([บรรทัด 105–112](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:105)): มี `reservationId`+ชื่อโต๊ะ หรือ `walkInTableId`; ด้านขวาบอก “สั่งที่ร้าน”/“การจอง #...” |
| ช่องค้นหา | เก็บ `search` ด้วย `setState`, [filteredFoods:89](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:89) เปรียบเทียบชื่อแบบ lowercase |
| chip ทั้งหมด/ข้าว/เส้น/อื่น ๆ | `selectedCategory` ใช้คัด `food.category`; เลือกแล้ว rebuild ทันที ไม่ต้องเรียก API ใหม่ |
| การ์ดรูป/ชื่อ/ราคา | [_FoodMenuCard:819](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:819), grid กำหนด `maxCrossAxisExtent:280`; รูป admin upload มาก่อน หากพัง fallback asset; กดการ์ดเรียก [_openFoodDetail:144](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:144) |
| ทำไมไม่มีปุ่ม + | การ์ดนี้จงใจให้เปิดรายละเอียดก่อน เพื่อเลือก option/หมายเหตุ; หากไม่มีโต๊ะ `_openFoodDetail` แจ้งให้จองหรือเลือกโต๊ะ |
| วงโหลด/ข้อผิดพลาด/ไม่พบเมนู | [_buildContent:599](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart:599) แยก 3 state; error มีปุ่มลองใหม่, list มี pull-to-refresh |

### Food Detail — [food_detail_page.dart:232](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:232)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รูปใหญ่/ชื่อ/ราคาเริ่มต้น | อ่าน `Food` object ที่หน้าก่อนส่งมา; รูป network หรือ asset fallback. ค่า `base` แปลง String “฿50” เป็นตัวเลขเพื่อคิดยอด preview |
| ถุงอาหารบน AppBar | [_openCart:161](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:161) ไป CartPage โดยส่ง reservation/table context ต่อ |
| หัวข้อ “ระดับความเผ็ด/ขนาด/ไข่/รูปแบบรับอาหาร” หรือหัวข้อที่ admin ตั้ง | `widget.food.optionGroups` จาก `menu.option_groups_json`, แสดงด้วย [_buildOptionGroup:99](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:99). `initState:54` เลือก option แรกที่ยังมีในกลุ่ม required เป็นค่าเริ่มต้น |
| chip ตัวเลือกที่มี “หมด” | `available=false` หรือ `sold_out=true` → `onSelected:null` กดไม่ได้; ราคาเพิ่มแสดงใน label. `max_select=1` สลับหนึ่งค่า, มากกว่า 1 เพิ่ม/ลดไม่เกินเพดาน |
| ช่อง “หมายเหตุ” | `noteController` รับข้อความเช่น “ไม่ใส่ผัก”; ส่งไปตะกร้า/ครัว; `dispose` ปล่อย controller |
| แผงสรุปราคา | `base`, `extras`, `unitPrice=base+extras`, `total=unitPrice×quantity`; แสดง “ราคาเพิ่มเติม” เฉพาะเมื่อ extras>0. นี่เป็น preview ฝั่ง Flutter; ราคาแท้ตรวจใหม่ที่ server |
| ปุ่ม −/จำนวน/+ | `quantity` เริ่ม 1; ลบต่ำกว่า 1 ไม่ได้ใน UI; บวกเพิ่มแล้ว `setState` อัปเดตยอด |
| “เพิ่มลงตะกร้า” | [_addToCart:177](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart:177) ตรวจกลุ่ม required, วนตามจำนวนแล้ว `CartService.add`, เก็บ snapshot กลุ่ม/ตัวเลือก/ราคาเพิ่ม/หมายเหตุ; ชื่อ+option เหมือนกันจะรวมจำนวน; SnackBar ยืนยัน |

### Cart — [cart_page.dart:27](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:27)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| ชื่อ “รายการอาหาร” และ “ล้างทั้งหมด” | AppBar; ล้างปรากฏเฉพาะตะกร้าไม่ว่าง, กดเรียก `CartService.clear()` ทันที ไม่มี dialog ยืนยัน |
| แถบโต๊ะ | แสดงชื่อโต๊ะและ “สั่งที่ร้าน” หรือเลขการจองจาก constructor `reservationId`, `reservationTable`, `tableId` |
| การ์ดแต่ละจาน | รูป/ชื่อ/ตัวเลือก/วิธีรับ/หมายเหตุ/ราคาต่อจาน/ราคารวม มาจาก `CartItem`; การ์ดไม่ใช่ข้อมูล DB เพราะตะกร้ายังอยู่ใน RAM |
| “แก้ไขรายการ” | [_editCartItem:714](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:714) เปิด dialog ให้เปลี่ยนตัวเลือกและหมายเหตุ; option หมด disable, required ต้องเลือก, บันทึกด้วย `CartService.replaceItem` |
| ปุ่ม −/+/จำนวน | `decrement` ลดจำนวนหรือเอารายการออกเมื่อเหลือ 1; `increment` เพิ่มจำนวน; `AnimatedBuilder` ฟัง service แล้วคำนวณยอดใหม่ |
| ยอดรวมสินค้า/ยอดรวมทั้งหมด | `subtotal = cart.subtotal`, `total=subtotal`; ขณะนี้ไม่มีค่าส่ง/ภาษี/ส่วนลดแยก จึงสองยอดเท่ากัน |
| ปุ่ม “ชำระเงิน • ฿...” | [บรรทัด 579](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:579) ไป `PaymentPage`; **ยังไม่โอนเงิน** ในขั้นนี้, หน้า PaymentPage คือยืนยันการสั่งอาหาร. ชื่อปุ่มอาจทำให้เข้าใจผิด ต้องตอบตาม flow จริง |
| ตะกร้าว่าง | [_EmptyCart:801](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart:801) แสดงไอคอนและ “กรุณาเพิ่มเมนูอาหารก่อน” |

### ยืนยันรายการและหน้าสำเร็จ — [payment_page.dart:173](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:173), [ConfirmationPage:271](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:271)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| แผงโต๊ะ/ยอด/สถานะ | `CartService.subtotal` หรือ amount ที่รับมา; สถานะเริ่ม “รอรับออร์เดอร์” เพื่อบอกว่าร้านยังไม่ได้รับรายการ |
| การ์ด QR | ข้อความ “ชำระหลังอาหารทำเสร็จ”; QR ไม่ได้แสดงบนหน้านี้ เพราะ server เปิด QR เมื่อทุกจานทำเสร็จ |
| “ยืนยันการสั่งอาหาร” | [_confirmPayment:73](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart:73) เช็ก login/ตะกร้า/กันกดซ้ำ, POST `/orders` แล้ว `/order-details` ทีละรายการ. Server ผูกโต๊ะและคำนวณราคาจริง. หากรายการล้มเหลวพยายามยกเลิกออร์เดอร์ที่เพิ่งสร้าง |
| วงโหลด/ปุ่ม disabled | `_isSaving`; ป้องกันการส่งซ้ำระหว่างรอ. Error เป็น SnackBar สี danger |
| หน้าสำเร็จ “รับออร์เดอร์แล้ว” | ConfirmationPage แสดงโต๊ะ Order ID ยอด preview และสถานะ; ปุ่ม “กลับหน้าหลัก” ล้าง navigation stack ไป HomeShell. หน้านี้ไม่ได้หมายความว่าจ่ายเงินจริงแล้ว |

---

## 4. หน้า “จองโต๊ะ” และปฏิทิน

### การจองใหม่ — [reservation_page.dart:331](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:331)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| ภาพร้านด้านบน | รูป `assets/restaurant.jpg` ประกอบหน้าจอง เป็น asset ในแอป แยกจากรูปแบนเนอร์ Home ที่แอดมินเปลี่ยนได้ |
| ช่องวันที่ | [_pickDate:126](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:126) เปิดปฏิทินแบบ custom; เมื่อเลือกแล้วเปลี่ยน `_selectedDate` และเรียก `_loadTables` ใหม่ เพราะโต๊ะว่างเปลี่ยนตามวัน |
| ช่องเวลา | [_pickTime:165](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:165) เปิด `SimpleDialog` ให้เลือกชั่วโมงที่ร้านเปิด และโหลดโต๊ะใหม่เพราะ availability เป็นรายช่วงเวลา |
| จุดสีแดง/เขียว/เทา | [_DateStatusLegend:1255](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1255): แดง=ปิด, เขียว=เปิดให้จอง, เทา=ยังเลือกไม่ได้/นอกช่วงที่เปิดจอง. สีเป็นตัวช่วยสื่อความหมาย; ต้องอธิบายกติกาเวลาจริงด้วย |
| แจ้งเตือนวันหยุด | ข้อมูลมาจาก `GET /api/restaurant/holidays` ที่ [_loadTables:69](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:69); วันอาทิตย์และวันหยุดพิเศษทำให้ปิดการจอง |
| จำนวนผู้จองและปุ่ม −/+ | [_guestSelector:997](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:997) เก็บใน `_guests`, ต่ำสุด 1 สูงสุด 8; เมื่อเปลี่ยนต้องคำนวณโต๊ะที่รองรับใหม่ |
| การ์ดโต๊ะ | availability จาก `GET /api/availability`, ใช้ความจุและเวลาพิจารณา. แตะโต๊ะว่างแล้วเก็บ `_selectedTable`; สีส้มบอกเลือกอยู่ สีเขียวบอกว่าง สีแดงในโค้ดใช้กับโต๊ะไม่พร้อม แต่ API ปกติส่งโต๊ะว่างมาเป็นหลัก |
| สรุปโต๊ะที่เลือก | สะท้อนวัน เวลา จำนวนคน และโต๊ะจาก state ปัจจุบัน ไม่ใช่จองสำเร็จแล้ว |
| ปุ่ม “ยืนยันการจอง” | [_confirmReservation:221](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:221) disabled เมื่อยังไม่มีโต๊ะ/กำลังโหลด/วันปิด, เช็กผู้ใช้ แล้ว POST `/api/reservations`. Server ตรวจวันเปิด ความจุ การชนเวลา และข้อมูลอีกชั้น; สำเร็จพาไป FoodMenu โดยส่ง reservationId กับ tableLabel |
| วงโหลด/ข้อความ error | `_loadingTables` และ `_error`; มี retry `_loadTables` เพื่อแก้กรณี API/เครือข่ายล้มเหลว โดยไม่ให้ผู้ใช้จองจากข้อมูลโต๊ะเก่า |

**ปฏิทินจริง** อยู่ที่ [_ReservationCalendarDialog:1046](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1046) ไม่ใช่ `showDatePicker` มาตรฐาน: `_statusFor` ที่ [1119](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart:1119) จัดสีตามวันอาทิตย์/วันหยุด/ช่วงเวลาจอง; สีเขียวเท่านั้นที่แตะเลือกได้. Header ใช้ปี พ.ศ. โดยบวก 543 แต่ข้อมูลวันส่ง API เป็น ISO ค.ศ. ตรรกะ `_initialReservationStart` เลือกเวลาแรกที่ใช้ได้เพื่อไม่เปิดมาที่เวลาผ่านไปแล้ว. ควรตอบให้ชัดว่า **UI ช่วยกรองเบื้องต้น ส่วน server ยืนยันกติกาจริง** ที่ [booking_rules.js](/D:/Project_Main/my_app/libs/booking_rules.js).

## 5. “การจองของฉัน” กับ “ประวัติการจอง” เป็นคนละหน้า

### แท็บ Booking ปัจจุบัน — [booking_page.dart:124](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:124)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| หัวข้อ “การจองของฉัน” | แสดงรายการ active ที่โหลดด้วย [_loadReservations:35](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:35) จาก API จองของ user ปัจจุบัน; หน้าอยู่ใน `IndexedStack` ของ HomeShell |
| ดึงหน้าลงเพื่อโหลดใหม่ | `RefreshIndicator` เรียก `_loadReservations`, เหมาะเมื่อแอดมินเปลี่ยนสถานะจากอีกเครื่อง |
| วงโหลด/ข้อความผิดพลาด/ลองใหม่ | state `loading/error`; ระหว่างโหลดไม่ควรแสดง “ไม่มีรายการ” เพราะยังไม่รู้ผล |
| กรณีไม่มีจอง | empty state กับปุ่มพาไป ReservationPage; ไม่ได้แปลว่าประวัติทั้งหมดหาย เพียงแยก active จาก history |
| การ์ดจอง | [_bookingCard:188](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:188): ภาพร้าน, เลขโต๊ะ, วันและเวลา, จำนวนคน, สถานะ. แปลง model เป็นข้อความให้ผู้ใช้เข้าใจ |
| “สั่งอาหาร” | [บรรทัด 285](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:285) ไป FoodMenu พร้อม context ของ reservation และโต๊ะ เพื่อผูกออร์เดอร์กับการจองที่ถูกต้อง |
| “ออร์เดอร์และการชำระเงิน” | [บรรทัด 305](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:305) ไป OrderHistoryPage ของ user |
| “ยกเลิก” | [บรรทัด 326](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart:326) เรียก API cancel แล้วรีโหลด; UI ปิดสำหรับสถานะยกเลิก/เสร็จ. Server ยังเช็กสิทธิ์เจ้าของรายการและเวลาล่วงหน้าอย่างน้อยหนึ่งชั่วโมง |

### ประวัติการจอง — [reservation_history_page.dart:48](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:48)

เปิดจาก Profile. [_loadReservations:27](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:27) เรียก `getCompletedReservationsByUserId` ซึ่งใช้ `view=history`; **ชื่อเมธอดพูดว่า completed แต่ API history ส่งหลายสถานะ**. `FutureBuilder` แยก loading/error/empty, รีเฟรชได้. [_reservationCard:184](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:184) แสดงเลขจอง โต๊ะ วันสร้างรายการ วันกิน เวลา จำนวนคน และป้ายสถานะ. [_statusBadge:327](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart:327) ใช้รหัสจริง: 1 ยืนยัน, 2 ยกเลิก, 3 ใช้บริการแล้ว, 4 รอดำเนินการ. แตะการ์ดไป ReservationDetailPage.

### รายละเอียดการจอง — [reservation_detail_page.dart:35](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart:35)

หน้านี้รับเพียง `reservationId` ผ่าน constructor; [initState:26](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart:26) เรียก `ApiService.getReservationById` ใหม่ และ `FutureBuilder` แยก loading/error/success. มีหัวข้อภาษาอังกฤษ, บรรทัดโต๊ะ/วัน/เวลา/คน/สถานะ. **จุดที่ต้องตอบอย่างตรงไปตรงมา:** [_statusBadge:253](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart:253) แปลรหัสเป็น `Pending, Confirmed, Cancelled, Completed` ตามลำดับ 1–4 ซึ่งไม่ตรงกับ DB และหน้าประวัติ; และบรรทัดโต๊ะใช้ `tableId` แทนเลขโต๊ะที่คนเห็น. ถ้าอาจารย์ชี้หน้ารายละเอียดและถามว่า status ผิดไหม ให้ตอบว่าเป็นข้อผิดพลาดของ mapping เฉพาะหน้านี้, ควรใช้ enum/formatter กลางจาก source เดียวกับ History แล้วแสดง tableNumber.

---

## 6. ประวัติออร์เดอร์ → QR → ส่งสลิป

### ประวัติออร์เดอร์ — [order_history_page.dart:313](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:313)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รายการออร์เดอร์ | [_load:27](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:27) เรียก API ตาม user ปัจจุบัน; `FutureBuilder` แสดง loading/error/ข้อมูล. การดึงลง `_refresh` สร้าง Future ใหม่ |
| กลุ่มกำลังทำ | [บรรทัด 323](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:323) กรอง `รอรับออร์เดอร์` และ `กำลังทำ` จาก order status |
| กลุ่มเสร็จ/ชำระ | [บรรทัด 324](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:324) กรอง `รอชำระเงิน`, `รอตรวจสอบการชำระ`, `ชำระเงินไม่ผ่าน`, `ชำระแล้ว`. เป็น **สถานะออร์เดอร์** ซึ่งต่างจากสถานะอาหารรายจาน |
| การ์ดแต่ละออร์เดอร์ | [_orderCard:357](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:357) แสดง #เลขออร์เดอร์, ยอด, วัน, ป้ายสถานะ, รายละเอียดเพิ่มเติมตามข้อมูล API |
| ไอคอน/ทางไป QR | มีเมื่อถึงสถานะที่ให้ชำระหรือชำระไม่ผ่าน; เปิด `PaymentQrPage(orderId)` ไม่สร้าง QR ในรายการประวัติโดยตรง |
| เมนูแก้ไข/ยกเลิก | PopupMenu [บรรทัด 378](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:378) มีเฉพาะออร์เดอร์ `รอรับออร์เดอร์`; เมื่อครัวรับแล้วไม่ควรเปลี่ยนออร์เดอร์ย้อนหลัง |
| แก้ไขรายการอาหาร | [_editOrder:65](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:65) เปิดรายการย่อย; ไอคอน edit ขึ้นเฉพาะจาน `food_status == รอทำ`. [_editOrderItem:118](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:118) แก้เมนู/จำนวน 1–99/ตัวเลือก/หมายเหตุ แล้วส่ง PATCH; server ตรวจสิทธิ์ ความพร้อมขาย และคำนวณราคาใหม่ |
| ยกเลิกออร์เดอร์ | [_cancelOrder:39](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart:39) ขอคำยืนยันใน dialog ก่อนยิง API และรีเฟรชรายการ |

**รายละเอียดที่ควรยอมรับเมื่อถูกถาม:** ช่องตัวเลือกใน dialog แก้ออร์เดอร์ยังแสดง option ที่หมดให้แตะได้บางกรณี; server จะปฏิเสธ option หมดผ่าน `resolveMenuSelections`. จึงเป็น UX ที่ควรแก้ให้ disable ก่อนกด ส่วนความถูกต้องยังบังคับฝั่ง server.

### ชำระผ่าน QR — [payment_qr_page.dart:55](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:55)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| หัวข้อ “ชำระออร์เดอร์ #...” | `orderId` ถูกส่งจากหน้าออร์เดอร์เป็น constructor parameter; ใช้ขอข้อมูลเฉพาะออร์เดอร์นั้น |
| วงโหลด | `qrFuture = ApiService.getPaymentQr(orderId)` ใน `initState`; `FutureBuilder` แยก waiting/success/error |
| ข้อความ “ยังสร้าง QR ไม่ได้” | อ่าน `Exception` แล้วแยกกรณีร้านไม่ตั้ง PromptPay, รอสลิป, จ่ายแล้ว, อาหารยังไม่เสร็จ; ปุ่มลองใหม่สร้าง Future อีกครั้ง. ข้อความ client เป็นตัวช่วย แต่ server ตัดสินว่าจะออก QR ได้หรือไม่ |
| ยอดชำระ | `data['amount']` จาก server, format ทศนิยม 2 ตำแหน่ง. ยอดนี้เป็นยอดออร์เดอร์จริงหลัง backend คำนวณ ไม่ใช้ยอด preview ใน Cart |
| รูป QR | [QrImageView:118](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:118) แปลง `qr_payload` เป็นลาย QR บนเครื่อง; payload มาจาก backend PromptPay ไม่ใช่รูป QR ที่ admin อัปโหลด |
| เบอร์โทร/เลขประจำตัว PromptPay | `data['promptpay_id']` ใน `SelectableText` ให้คัดลอกได้; admin ตั้งค่าในแท็บจัดการร้าน; ไม่ใช่เลขบัญชีธนาคารทุกชนิด |
| รายการอาหาร | วน `data['items']` แสดงชื่อ × จำนวน และ `price × quantity` ที่ server ส่งมา |
| ป้ายสถานะชำระ | `_loadPayment` GET payment status อีก endpoint; อาจมาช้ากว่า QR เพราะเป็น Future แยก |
| ปุ่ม “แนบสลิปการโอน” | [_sendSlip:35](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart:35) เปิด gallery ผ่าน `image_picker`, อ่าน bytes, สร้าง data URI base64 แล้วส่ง API. `sending` ปิดปุ่มขณะส่ง; status 3 รอตรวจ/1 ชำระแล้วปิดปุ่ม; admin เป็นผู้ตรวจสลิปและ approve/reject |

## 7. โปรไฟล์ ข้อมูลส่วนตัว แจ้งเตือน และสถิติ

### Profile — [profile_page.dart:26](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:26)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รูป/ชื่อ/ชื่อผู้ใช้/โทรศัพท์ | `AnimatedBuilder` ฟัง `CurrentUserService`, จึง rebuild เมื่อบันทึกข้อมูลส่วนตัว. URL รูปจาก server หรือ placeholder; **รูปในหน้า Profile ไม่ใช่ปุ่มเปลี่ยน** |
| “ข้อมูลส่วนตัว” | [บรรทัด 124](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:124) ไป PersonalInformationPage ซึ่งเป็นที่แก้รูป ชื่อจริง ชื่อผู้ใช้ เบอร์ อีเมล |
| “ประวัติการจอง” | [บรรทัด 138](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:138) ไป ReservationHistoryPage ไม่ใช่แท็บจองปัจจุบัน |
| “การแจ้งเตือน” | [บรรทัด 152](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:152) ไป NotificationInboxPage |
| “ประวัติออร์เดอร์” | [บรรทัด 158](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:158) ไป OrderHistoryPage |
| “สถิติเมนูยอดนิยม” | [บรรทัด 164](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:164) ไป RestaurantStatsPage |
| สวิตช์เปิด/ปิดแจ้งเตือน | [_NotificationPreferenceControl:236](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:236) GET/PATCH preference; มี loading/disabled ขณะบันทึก. นี่กำหนดการแจ้งเตือนในอนาคต; สีของ **ข้อความเก่า** อ้างค่า snapshot ตอนข้อความถูกสร้าง |
| “ออกจากระบบ” | [บรรทัด 173](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart:173) เคลียร์ `CurrentUserService` แล้วกลับหน้าเริ่มต้น. **CartService ไม่ได้เคลียร์** ตรงนี้ อาจเหลือรายการใน memory เมื่อสลับ account ใน process เดียว; เป็นจุดปรับปรุงด้าน isolation |

### ข้อมูลส่วนตัว — [personal_information_page.dart:166](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart:166)

| ถ้าชี้ที่... | อ่าน/ตอบจากโค้ด |
|---|---|
| รูปพร้อมไอคอนแก้ไข | แตะแล้วใช้ `ImagePicker.gallery`, บีบอัดด้วย `maxWidth:1200`, `imageQuality:82`, จำกัด 3 MB; encode base64 → PUT API → อัปเดต `CurrentUserService`. Spinner ระหว่างส่งกันแตะซ้ำ |
| ช่องชื่อจริง | บังคับไม่ว่าง; ค่าเริ่มจาก user ปัจจุบัน |
| ช่องชื่อผู้ใช้ | ตรวจ `[A-Za-z0-9_.-]{3,50}`; server ตรวจชื่อซ้ำและสิทธิ์เจ้าของบัญชีอีกครั้ง |
| โทรศัพท์/อีเมล | รับข้อมูลแก้ไขและส่งไป backend ตามฟอร์ม; อีเมลไม่ใช่ชื่อใช้ล็อกอินในโค้ดนี้ |
| ปุ่มบันทึก | disabled/แสดงโหลดระหว่างส่ง, เรียก API profile แล้วแทน user ใน service; `dispose` controllers ป้องกัน resource ค้าง |

### กล่องแจ้งเตือน — [notification_inbox_page.dart:29](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart:29)

`FutureBuilder` เรียก GET notification; มี loading/error/empty และดึงลงเพื่อรีเฟรช. แต่ละแถวเป็น `Row` ระหว่างไอคอน, ชื่อ, ข้อความ, เวลาส่ง. [กระดิ่งที่บรรทัด 54](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart:54) ห่อด้วย `IgnorePointer` จึง **กดไม่ได้**. สีส้มเมื่อ `row['notifications_enabled']` เป็น true/1, สีเทาเมื่อ false/0. ค่านี้เป็น snapshot **ตอนเกิด notification**, ไม่ใช่ค่า toggle ปัจจุบัน. ด้าน API มี mark-read แต่หน้านี้ไม่เรียก จึงไม่มีการแตะกระดิ่งเพื่อเปลี่ยนสี/อ่าน. โปรดแยก “สีตอนส่ง” ออกจาก “อ่านแล้วหรือยัง”.

### สถิติเมนูยอดนิยมของลูกค้า — [restaurant_stats_page.dart:22](/D:/Project_Main/flutter_application_1/lib/pages/restaurant_stats_page.dart:22)

ตอน `initState` สร้างเดือน `YYYY-MM` จากเวลาปัจจุบันและ `ApiService.getPopularMenus(month)`. `FutureBuilder` แยก loading/error/empty. แต่ละ `ListTile` มีเลขอันดับ, ชื่อเมนู, จำนวนจาน, เปอร์เซ็นต์; ข้อมูลจาก backend ที่นับออร์เดอร์ชำระแล้ว. ไม่ใช่กราฟยอดขายรายวันของ admin และไม่ได้รีเฟรชเดือนอัตโนมัติถ้าค้างหน้านี้ข้ามเดือน.

---

## 8. หลังบ้าน: โครงร่วมทั้งห้าแท็บ

ไฟล์หลักคือ [admin_dashboard_page.dart:18](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:18). `index` เลือกแท็บ, `loading/error` ควบคุม state, list แปดชุดถือข้อมูลหลังบ้าน, controllers ถือข้อความในฟอร์ม. [initState:44](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:44) เรียก [_load:63](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:63) ซึ่งใช้ `Future.wait` โหลด dashboard, reservations, order-items, payments, customers, holidays, menu, tables, banner, PromptPay **10 endpoint พร้อมกัน**. ผลใส่ state แล้ว rebuild; หาก endpoint ใด throw, `Future.wait` ทำให้หน้า error ทั้งหน้า. `_load(showLoading:false)` หลังเปลี่ยนค่าใช้รีเฟรชเงียบ ๆ เพื่อลดการกระพริบ.

[build:515](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:515) มี AppBar ชื่อตามแท็บ, ปุ่ม Refresh, Logout, พื้นที่ loading/error/content, `RefreshIndicator`, และ `NavigationBar` ห้าปุ่มที่ [522](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:522). `onDestinationSelected` เปลี่ยน `index` ด้วย `setState`. การ logout ใน AppBar เคลียร์ user และล้าง navigation stack. **ไม่มีหน้าข้อมูลส่วนตัว admin ในไฟล์นี้**; ถ้าอาจารย์ถามว่าแก้ชื่อ admin ผ่าน UI ไหน ให้ตรวจโค้ดปัจจุบันก่อนตอบ และอย่าอ้างว่าเมนูลูกค้าใช้ได้กับ admin.

### แท็บ 1 “ภาพรวม” — [_dashboard:532](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:532)

| จุดบนหน้า | แหล่งข้อมูลและเหตุผล |
|---|---|
| “ยอดขายเดือนนี้” | `dashboard['monthly_sales']` จาก `/admin/dashboard`; ฝั่ง backend รวมยอดที่ชำระจริง จึงไม่เอาออร์เดอร์รอชำระมานับ |
| “การจองวันนี้” | `dashboard['today_reservations']`; เป็นจำนวนรายการในวันที่ server นิยามว่าปัจจุบัน. ตรวจเงื่อนไข SQL ก่อนพูดว่าไม่นับรายการยกเลิก เพราะ query ปัจจุบันไม่ได้ตัดสถานะทุกกรณี |
| “กราฟยอดขายรายวัน” | `daily_sales` แปลงเป็น `DateTime → double`, เติมวันที่ไม่มียอดเป็น 0, `CustomPaint` วาดเส้นส้มและเส้นกริดที่ [_SalesChartPainter:1063](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:1063). ความสูงแต่ละจุด = `sales/maxValue`, แนวนอน = ลำดับวันในเดือน. ถ้าทุกวัน 0 จะมีแต่เส้นกริด |
| เมนูยอดนิยมเดือนนี้ | `popular_menus`: ชื่อ, จำนวนจาน `plates`, ยอดรวมรายเมนู `revenue`, สัดส่วน `percentage`; ใช้ข้อมูลรวมจาก backend ไม่ใช่ลำดับเมนูในหน้า Home |

### แท็บ 2 “การจอง” — [_reservations:550](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:550)

`_dateSections` ที่ [568](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:568) ใช้ key `dining_date`, แยกหัวข้อ “วันที่ YYYY-MM-DD” กับจำนวนรายการและเรียงวันใหม่ก่อน. การ์ดแต่ละใบมีชื่อผู้จอง เลขโต๊ะ [_timeBadge:600](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:600) ดึง `HH:mm` จาก timestamp จำนวนคน โทรศัพท์ และ dropdown 4 สถานะ: ยืนยันแล้ว(1), ยกเลิก(2), มาใช้บริการแล้ว(3), รอยืนยัน(4). เปลี่ยน dropdown → [_changeReservation:106](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:106) เปลี่ยน UI ทันทีแบบ optimistic, PATCH `/admin/reservations/:id/status`, แล้วโหลดใหม่. Set `_savingReservationStatuses` กันกดซ้ำในรายการเดียว; หาก API ล้มเหลว reload ค่าเดิม.

### แท็บ 3 “ครัว” — [_kitchen:640](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:640)

ใช้ `_dateSections` เหมือนแท็บจองแต่ key `order_date` จึงแยกตาม **วันสั่ง**. การ์ดแสดง Order #, ชื่อเมนู × จำนวน, เวลา, โต๊ะ, option ที่ลูกค้าเลือก, หมายเหตุ. [_selectedOptionsText:626](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:626) decode JSON ที่อยู่ใน `selected_options` และต่อข้อความ `ชื่อกลุ่ม: ชื่อตัวเลือก`. ปุ่ม “รับเมนูนี้” ปรากฏเฉพาะจาน `รอทำ` และออร์เดอร์ไม่ยกเลิก/ชำระแล้ว, เรียก [_acceptOrder:151](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:151). Dropdown เปลี่ยน `รอทำ → กำลังทำ → ทำเสร็จแล้ว` ผ่าน [_changeFoodStatus:128](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:128). สถานะรายจานมีผลต่อสถานะออร์เดอร์รวมและจังหวะที่สร้าง QR ได้; server เป็นผู้บังคับลำดับจริง.

### แท็บ 4 “ชำระเงิน” — [_payments:666](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:666)

บนสุดเป็นคำแนะนำให้ตรวจยอดกับสลิป. ถ้าไม่มีรายการแสดง empty card กับปุ่ม “โหลดใหม่”. ถ้ามี `ExpansionTile` ต่อ payment แสดง Order #, ยอด, ชื่อลูกค้า, payment status. ภาพสลิปโหลดผ่าน endpoint admin ที่ต้องแนบ `ApiService.authHeaders`, จึงเปิดให้ดูเฉพาะผู้มีสิทธิ์. เมื่อ `payment_status_id == 3` (รอตรวจ) แสดง “ปฏิเสธ” และ “ยืนยันชำระแล้ว”; ทั้งคู่เรียก [_reviewPayment:170](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:170) PATCH พร้อม `approved: false/true` แล้ว reload. **การอัปโหลดสลิปไม่ได้เท่ากับจ่ายสำเร็จ**; ยอดขายถูกนับเมื่อแอดมินยืนยัน.

### แท็บ 5 “จัดการร้าน” — [_management:694](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:694)

หน้าเป็น `ListView` ที่แยกแต่ละงานเป็น `Card`; หัวข้อลูกค้า เมนู โต๊ะเป็น `ExpansionTile` พร้อม `PageStorageKey` และ `maintainState` จึงจำสถานะเปิด/ปิดเมื่อ rebuild. รายละเอียดตามลำดับที่นิ้วอาจารย์เลื่อนลงไปเจอ:

| ส่วนที่ชี้ | UI → ฟังก์ชัน → API/เหตุผล |
|---|---|
| “QR รับชำระเงิน” [700](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:700) | ช่อง PromptPay ปิดตัวเลขด้วย `obscureText`, รูปตาแสดง/ซ่อน. [_savePromptPayId:251](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:251) ตัด space/ขีด, รับเบอร์ขึ้น 0 จำนวน 10 หลักหรือเลข 13 หลัก, PUT `/admin/payment-settings/promptpay`. เมื่อกดบันทึกปิดปุ่มชั่วคราว. QR ของลูกค้าสร้างจากเลขนี้และยอดออร์เดอร์ ไม่ได้ upload QR คงที่ |
| “ข้อความบนแบนเนอร์” [752](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:752) | TextField จำกัด 50 ตัวอักษร; [_saveRestaurantBannerTitle:231](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:231) บังคับ 1–50 และ PUT `/admin/restaurant/banner/title`. Home hero ดึงค่าจาก public banner endpoint; Splash ยังเป็นข้อความคงที่ |
| “รูปหน้าร้าน” [798](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:798) | Preview ภาพปัจจุบันและปุ่มเลือกรูป. [_changeRestaurantBanner:194](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:194) gallery, maxWidth 2000/quality86, จำกัด 5 MB, รองรับ jpeg/png/webp, base64 POST `/admin/restaurant/banner`. เก็บ URL ที่ server ส่งกลับใน state |
| “วันหยุดพิเศษ” [829](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:829) | ขั้น 1 เลือกวันที่ด้วย `showDatePicker` [_pickHolidayDate:384](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:384) ตั้งแต่วันนี้ถึง 3 ปี, ขั้น 2 กรอกชื่อ, กดเพิ่ม [_addHoliday:178](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:178) POST `/admin/holidays`. การ์ดวันหยุดแต่ละอันแยกชั้น มี `_dateBadge` สีแดงและปุ่มลบ DELETE. วันนั้นลูกค้าจะเห็นสีแดงและจองไม่ได้ |
| “ลูกค้า (n)” [894](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:894) | การ์ดแต่ละรายแสดงชื่อ @username โทร อีเมล และ badge active/suspended; Switch [_toggleCustomer:275](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:275) PATCH สถานะ. เมนู ⋮ แก้ข้อมูล [_editCustomer:283](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:283), ตั้งรหัสใหม่ [_resetCustomerPassword:322](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:322) ขั้นต่ำ 8 ตัวและยืนยันซ้ำ, ลบบัญชี [_deleteCustomer:361](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:361) มี dialog ยืนยัน. Server เก็บประวัติจองและออร์เดอร์ไว้แม้ลบบัญชี |
| “เมนูอาหาร (n)” [947](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:947) | ปุ่มเพิ่ม; แต่ละการ์ดชื่อ หมวด ราคา badge พร้อมขาย/หยุดขาย. ไอคอนหยุดขาย [_cancelMenu:457](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:457) มี confirmation แล้ว PUT statusmenu_id=2 **ไม่ได้ลบ record**. ไอคอนดินสอเปิด [_editMenu:395](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:395) |
| Dialog เพิ่ม/แก้เมนู [395](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:395) | ชื่อ ราคา dropdown หมวด `ข้าว/เส้น/อื่นๆ`, รูปเก่าหรือ preview รูปใหม่, picker <=3MB, dropdown พร้อมขาย/หมด, ปุ่มจัดการหัวข้อย่อย. `defaultMenuOptionGroups` สำหรับเมนูใหม่; กดบันทึก upload รูปก่อนแล้ว POST/PUT ข้อมูลเมนู. server ตรวจราคา/รูป/กลุ่ม option อีกชั้น |
| “โต๊ะ (n)” [983](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:983) | ปุ่มเพิ่ม; การ์ดเลขโต๊ะ ความจุ สถานะเปิด/ปิด และ “มีลูกค้าใช้บริการ”. ไอคอนปิดรอบแสดงเมื่อ `is_occupied`, DELETE `/admin/tables/:id/walk-in-session`. ดินสอเปิด [_editTable:484](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart:484) แก้หมายเลข จำนวนที่นั่ง และสถานะ, POST/PUT. โต๊ะปิดใช้งานไม่ควรเสนอให้จอง |

### Dialog “หัวข้อและตัวเลือกของเมนู” — [admin_menu_options_dialog.dart:111](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:111)

เปิดจาก dialog เพิ่ม/แก้เมนู; state ของกลุ่มแยกใน dialog จนกดบันทึกจึงส่งกลับผู้เรียก. [_editGroup:30](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:30) ให้ชื่อกลุ่ม, `required`, `maxSelect` 1–5; ตัวอย่าง “ไข่” บังคับเลือกสูงสุด 1. [_editOption:72](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:72) ให้ชื่อตัวเลือก, ราคาเพิ่มอย่างน้อย 0, สวิตช์ available/หมด. การ์ดกลุ่มขยายได้, ปุ่มเพิ่ม/แก้/ลบ group และ option. ตอน save บังคับว่ากลุ่มที่ต้องเลือกต้องมี option อย่างน้อยหนึ่งตัว. [_defaultMenuOptionGroups:210](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart:210) เติมกลุ่มตัวอย่างให้เมนูใหม่. ฝั่งลูกค้า FoodDetail จะ disable option ที่หมดและคำนวณราคาเพิ่ม; server ตรวจซ้ำเพื่อกัน request ดัดแปลง.

---

## 9. ดัชนีไฟล์ทั้งหมดที่เขียนเป็นโค้ดแอป

ส่วนนี้หมายถึง **ไฟล์ต้นฉบับที่ทีมต้องเข้าใจ**, ไม่ใช่ทุกไฟล์ที่ Flutter/Gradle/npm สร้างเองหลายพันไฟล์ใน `build`, `.dart_tool`, `node_modules`, `android/.gradle`, binary รูป หรือ lockfile. แต่ละไฟล์มีหน้าที่ต่างกัน; ชื่อหน้าในข้อ 1–8 ด้านบนบอกตำแหน่ง UI ระดับปุ่ม ส่วน [คู่มือหลักข้อ 3–5](/D:/Project_Main/PROJECT_INTERVIEW_GUIDE_TH.md) อธิบาย API/SQL ลึกกว่า.

### Flutter: entry, ธีม, state และข้อมูล

| ไฟล์ | อธิบายให้อาจารย์ฟัง |
|---|---|
| [main.dart](/D:/Project_Main/flutter_application_1/lib/main.dart) | เรียก Flutter binding, ตั้ง Firebase แบบพยายาม, สร้าง `MaterialApp`/theme และกำหนด Splash เป็นหน้าแรก. ถ้า `runApp` ไม่ถูกเรียกจะไม่มี widget tree |
| [firebase_options.dart](/D:/Project_Main/flutter_application_1/lib/firebase_options.dart) | ค่าแพลตฟอร์ม Firebase ยังเป็น placeholder; แอป catch error จึงเปิดได้ แต่ push จริงต้อง configure เพิ่ม |
| [app_theme.dart](/D:/Project_Main/flutter_application_1/lib/core/app_theme.dart) | `AppColors` และ `ThemeData` รวมสี orange/cream/background/grey/danger, ฟอนต์, AppBar, input/button shape. เหตุผลคือให้ทุกหน้าตรงกัน |
| [food_data.dart](/D:/Project_Main/flutter_application_1/lib/data/food_data.dart) | ข้อมูลอาหารตัวอย่าง hard-code จากระยะต้น; เมนูจริงโหลด HTTP/DB. มี field rating เก่าแต่ UI ไม่แสดงดาว |
| [user.dart](/D:/Project_Main/flutter_application_1/lib/models/user.dart) | `User.fromJson` แปลงผล login/profile เป็นชนิด Dart; ถือ id, role, token, ชื่อ, โทร, รูป |
| [table_model.dart](/D:/Project_Main/flutter_application_1/lib/models/table_model.dart) | แปลงโต๊ะ, id/number/capacity/status/available; UI ใช้แสดงหมายเลข ส่วน server ตัดสินการชนจริง |
| [reservation.dart](/D:/Project_Main/flutter_application_1/lib/models/reservation.dart) | แยกวันกดจอง `bookingDate` กับวันมา `diningDate`, เวลา คน โต๊ะ สถานะ. ถ้าไม่แยกจะตอบคำถามประวัติจองผิด |
| [food.dart](/D:/Project_Main/flutter_application_1/lib/models/food.dart) | เมนูจาก API: ชื่อ ราคา หมวด รูป ตัวเลือกย่อย, fallback เมื่อ field ไม่มี; rating คงค้างแต่ไม่ใช้แสดง |
| [cart_item.dart](/D:/Project_Main/flutter_application_1/lib/models/cart_item.dart) | หนึ่งรายการในตะกร้า: food, จำนวน, option ที่เลือก, หมายเหตุ; `unitPrice` และ `total` สำหรับ preview |
| [api_service.dart](/D:/Project_Main/flutter_application_1/lib/services/api_service.dart) | HTTP client กลาง, base URL แยก web/emulator/มือถือ, Bearer header, decode JSON, แปลง error, เมธอดแต่ละ route และ admin wrappers |
| [current_user_service.dart](/D:/Project_Main/flutter_application_1/lib/services/current_user_service.dart) | `ChangeNotifier` singleton ถือ user/token ปัจจุบัน; Profile ฟังเพื่ออัปเดต UI หลังแก้ข้อมูล. ข้อมูลยังอยู่แค่ memory |
| [cart_service.dart](/D:/Project_Main/flutter_application_1/lib/services/cart_service.dart) | `ChangeNotifier` singleton ถือรายการ/โต๊ะ/การจอง, รวมเมนูที่ option+note เหมือนกัน, เพิ่มลดลบล้าง, notify ให้ badge/summary เปลี่ยน |
| [notification_service.dart](/D:/Project_Main/flutter_application_1/lib/services/notification_service.dart) | ลงทะเบียน FCM token, ฟัง foreground message, แสดง SnackBar; ทำงานได้เต็มเมื่อ Firebase ถูก configure |

### Flutter: widgets ใช้ซ้ำและหน้าทั้งหมด

| ไฟล์ | ใช้ที่ไหน/ต้องตอบอะไร |
|---|---|
| [app_bottom_nav.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_bottom_nav.dart) | แถบ Home/Menu/Booking/Profile; รับ index และ callback จาก HomeShell |
| [app_buttons.dart](/D:/Project_Main/flutter_application_1/lib/widgets/app_buttons.dart) | Primary/Secondary button แบบร้าน; รับข้อความและ callback เพื่อให้ปุ่มหลายหน้าเหมือนกัน |
| [food_card.dart](/D:/Project_Main/flutter_application_1/lib/widgets/food_card.dart) | การ์ดอาหารที่ Home ใช้; `FoodMenuPage` มีการ์ดอีกแบบในไฟล์ของตัวเอง |
| [search_field.dart](/D:/Project_Main/flutter_application_1/lib/widgets/search_field.dart) | ช่องค้นหาและ action filter; รับ callback จากหน้าเจ้าของ state |
| [section_header.dart](/D:/Project_Main/flutter_application_1/lib/widgets/section_header.dart) | หัวข้อ section กับปุ่มทางขวา; แยก UI ซ้ำ |
| [splash_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/splash_page.dart), [welcome_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/welcome_page.dart) | จุดเริ่มและทางเลือก Login/SignUp; ไม่เรียกฐานข้อมูล |
| [login_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/login_page.dart), [signup_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/signup_page.dart) | ฟอร์ม/validation/request บัญชี; role แยกหน้าหลัง login |
| [home_shell.dart](/D:/Project_Main/flutter_application_1/lib/pages/home_shell.dart), [home_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/home_page.dart) | กรอบ 4 แท็บและ Home/banner/walk-in/ค้นหา/เมนูแนะนำ |
| [food_menu_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/food_menu_page.dart), [food_detail_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/food_detail_page.dart) | รายการเมนู/หมวด/ค้นหา และเลือกรายการย่อย/หมายเหตุ/จำนวน |
| [cart_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/cart_page.dart), [payment_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/payment_page.dart) | ตะกร้า/แก้ item/preview และ **ยืนยันสร้างออร์เดอร์**; ConfirmationPage อยู่ท้าย `payment_page.dart` ไม่ใช่ไฟล์แยก |
| [reservation_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/reservation_page.dart), [booking_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/booking_page.dart) | จองใหม่/ปฏิทิน และแท็บจองที่ยัง active |
| [reservation_history_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/reservation_history_page.dart), [reservation_detail_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/reservation_detail_page.dart) | ประวัติทุกสถานะ และรายละเอียดที่ดึง API ใหม่ |
| [order_history_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/order_history_page.dart), [payment_qr_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/payment_qr_page.dart) | ออร์เดอร์/แก้/ยกเลิก และ QR/สลิป |
| [profile_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/profile_page.dart), [personal_information_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/personal_information_page.dart) | เมนูโปรไฟล์/switch และฟอร์มแก้ข้อมูล/รูป |
| [notification_inbox_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/notification_inbox_page.dart), [restaurant_stats_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/restaurant_stats_page.dart) | ประวัติแจ้งเตือนสีตาม snapshot และอันดับเมนูยอดนิยม |
| [admin_dashboard_page.dart](/D:/Project_Main/flutter_application_1/lib/pages/admin_dashboard_page.dart), [admin_menu_options_dialog.dart](/D:/Project_Main/flutter_application_1/lib/pages/admin_menu_options_dialog.dart) | หลังบ้าน 5 แท็บ/จัดการร้าน และฟอร์ม option เมนู |

### Node.js: API, helper, SQL model และ migration

| ไฟล์ | บทบาทที่ต้องอธิบาย |
|---|---|
| [server.js](/D:/Project_Main/my_app/server.js) | Express entry point: middleware, public/auth/admin routes, status/error response, เริ่ม HTTP และ reminder worker. ถ้าถาม “ปุ่มนี้ยิงไหน” ให้หา route ที่นี่ก่อน |
| [db_pool.js](/D:/Project_Main/my_app/libs/db_pool.js) | สร้าง MySQL connection pool จาก `.env`, คุม timezone/connection; models ใช้ query/transaction |
| [auth_token.js](/D:/Project_Main/my_app/libs/auth_token.js) | ออกและตรวจ token HMAC, `requireAuth` อ่าน user จริงจาก DB, `requireAdmin` เช็ก role; UI ซ่อนปุ่มอย่างเดียวไม่ใช่ระบบสิทธิ์ |
| [booking_rules.js](/D:/Project_Main/my_app/libs/booking_rules.js) | ตรวจ date/time ที่จองได้ตามเวลาไทย, ช่วงวัน, วันอาทิตย์, เวลาเปิด; ทำบน server เพื่อกัน request ดัดแปลง |
| [menu_options.js](/D:/Project_Main/my_app/libs/menu_options.js) | normalize/validate group และตัวเลือก, ตรวจ required/max/soldout, คำนวณราคา option จริง |
| [promptpay.js](/D:/Project_Main/my_app/libs/promptpay.js) | ประกอบ PromptPay payload แบบ EMV/TLV พร้อม CRC และจำนวนเงิน; `qr_flutter` วาด payload นั้นเป็น QR |
| [firebase_admin.js](/D:/Project_Main/my_app/libs/firebase_admin.js) | เตรียม Firebase Admin สำหรับ push เมื่อมี credential; in-app notification ยังบันทึกได้ถ้า push ไม่พร้อม |
| [notifications.js](/D:/Project_Main/my_app/libs/notifications.js) | บันทึกข้อความ, snapshot ว่าเปิดแจ้งเตือนขณะส่งหรือไม่, ส่ง push เมื่อเปิด, เรียก reminder worker |
| [reservation_reminders.js](/D:/Project_Main/my_app/libs/reservation_reminders.js) | นิยามจังหวะเตือนก่อนจอง 60 นาที/10 นาที/ถึงเวลา และ key ไม่ให้แจ้งซ้ำ |
| [models/user.js](/D:/Project_Main/my_app/models/user.js) | SQL ผู้ใช้/login/profile/รูป/notification preference/สถานะบัญชี |
| [models/table.js](/D:/Project_Main/my_app/models/table.js) | SQL โต๊ะ, ความจุ, สถานะ, โต๊ะ walk-in และ session; โต๊ะปิดไม่ควรเสนอ |
| [models/reservation.js](/D:/Project_Main/my_app/models/reservation.js) | SQL จอง/availability/history/ยกเลิก/holiday; transaction และ lock กันชนกัน |
| [models/menu.js](/D:/Project_Main/my_app/models/menu.js) | SQL เมนู/หมวด/รูป/option groups/สถานะพร้อมขาย; query ลูกค้าไม่เหมือน query admin |
| [models/order.js](/D:/Project_Main/my_app/models/order.js) | SQL ออร์เดอร์หลัก, สิทธิ์เจ้าของ, บริบทโต๊ะจองหรือ walk-in, สถานะรวม |
| [models/order_detail.js](/D:/Project_Main/my_app/models/order_detail.js) | SQL รายการอาหารต่อออร์เดอร์, ปริมาณ, ราคา snapshot, option snapshot และ food status |
| [models/payment.js](/D:/Project_Main/my_app/models/payment.js) | SQL สลิป/ยอด/การตรวจอนุมัติ; transaction เปลี่ยน payment และ order ด้วยกัน |
| [migrations/20261009_restaurant_features.sql](/D:/Project_Main/my_app/db/migrations/20261009_restaurant_features.sql) | โครงส่วนร้าน/สถานะ/วันหยุด/แจ้งเตือน/ดัชนีจาก schema เดิม |
| [20261010_notification_preference.sql](/D:/Project_Main/my_app/db/migrations/20261010_notification_preference.sql) | ช่องเปิด/ปิดแจ้งเตือนของผู้ใช้ |
| [20261011_walk_in_table_sessions.sql](/D:/Project_Main/my_app/db/migrations/20261011_walk_in_table_sessions.sql) | ตาราง session โต๊ะ walk-in และความสัมพันธ์กับออร์เดอร์ |
| [20261012_menu_description.sql](/D:/Project_Main/my_app/db/migrations/20261012_menu_description.sql) | ช่อง description เดิมของเมนู; ฟอร์มใหม่ไม่ได้ใช้เป็นหัวข้ออาหาร |
| [20261013_customer_admin.sql](/D:/Project_Main/my_app/db/migrations/20261013_customer_admin.sql) | soft delete ลูกค้า |
| [20261014_menu_choice_groups.sql](/D:/Project_Main/my_app/db/migrations/20261014_menu_choice_groups.sql) | JSON กลุ่ม option ของเมนูและ option ที่ลูกค้าเลือกใน order detail |
| [20261015_notification_event_preference.sql](/D:/Project_Main/my_app/db/migrations/20261015_notification_event_preference.sql) | เก็บสี/สถานะ preference **ขณะส่งข้อความ** แยกจาก switch ปัจจุบัน |
| [20261016_menu_category_image.sql](/D:/Project_Main/my_app/db/migrations/20261016_menu_category_image.sql) | หมวดและรูปเมนู |

### ไฟล์รัน, แพลตฟอร์ม, สคริปต์ และทดสอบ

| ไฟล์ | ทำไมมี/ควรตอบอย่างไร |
|---|---|
| [pubspec.yaml](/D:/Project_Main/flutter_application_1/pubspec.yaml), [pubspec.lock](/D:/Project_Main/flutter_application_1/pubspec.lock) | ประกาศแพ็กเกจ Flutter/assets/SDK กับเวอร์ชันแพ็กเกจที่ resolve แล้ว; เปลี่ยน dependency ที่ yaml แล้ว `flutter pub get` อัปเดต lock |
| [analysis_options.yaml](/D:/Project_Main/flutter_application_1/analysis_options.yaml) | กฎ lint สำหรับ Dart/Flutter; ช่วยตรวจรูปแบบ/ความผิดพลาดเชิง static แต่ไม่แทนการทดสอบระบบ |
| [package.json](/D:/Project_Main/my_app/package.json), [package-lock.json](/D:/Project_Main/my_app/package-lock.json) | dependencies/script Node กับเวอร์ชันที่ล็อกแล้ว; `npm install` ทำให้ `node_modules` ถูกสร้าง |
| [README_RUN_TH.md](/D:/Project_Main/my_app/README_RUN_TH.md), [README.md](/D:/Project_Main/flutter_application_1/README.md) | วิธีเปิด backend/DB/app และเอกสาร starter Flutter; ให้ใช้คู่มือรันภาษาไทยเป็นหลัก |
| [.env.example](/D:/Project_Main/my_app/.env.example) | ตัวอย่างชื่อ config DB/secret/port; `.env` จริงมีค่าลับ ไม่ควรโชว์อาจารย์หรือ commit |
| [android/app/build.gradle.kts](/D:/Project_Main/flutter_application_1/android/app/build.gradle.kts), [android/settings.gradle.kts](/D:/Project_Main/flutter_application_1/android/settings.gradle.kts), [android/build.gradle.kts](/D:/Project_Main/flutter_application_1/android/build.gradle.kts) | Android Gradle plugins, SDK/application ID/build type; ฝั่ง Dart UI ยังอยู่ `lib/` |
| [AndroidManifest.xml](/D:/Project_Main/flutter_application_1/android/app/src/main/AndroidManifest.xml), [MainActivity.kt](/D:/Project_Main/flutter_application_1/android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt) | permissions/HTTP development/launcher และ Android entry ที่เชื่อม Flutter engine; ไม่มี UI ร้านเขียนด้วย Kotlin |
| [debug AndroidManifest](/D:/Project_Main/flutter_application_1/android/app/src/debug/AndroidManifest.xml), [profile AndroidManifest](/D:/Project_Main/flutter_application_1/android/app/src/profile/AndroidManifest.xml) | manifest เพิ่มเฉพาะ build mode; แยกจาก main manifest |
| [android/gradle.properties](/D:/Project_Main/flutter_application_1/android/gradle.properties) | ตัวเลือก memory/AndroidX/Gradle build; ไม่ใช่ที่แก้ business logic ของร้าน |
| [ios/Runner/Info.plist](/D:/Project_Main/flutter_application_1/ios/Runner/Info.plist), [macos/Runner/Info.plist](/D:/Project_Main/flutter_application_1/macos/Runner/Info.plist), [web/manifest.json](/D:/Project_Main/flutter_application_1/web/manifest.json) | metadata/สิทธิ์/ชื่อแอปของแต่ละแพลตฟอร์ม; Flutter UI ยังใช้ code ชุดเดียวใน `lib` |
| [web/index.html](/D:/Project_Main/flutter_application_1/web/index.html), [ios/Flutter/AppFrameworkInfo.plist](/D:/Project_Main/flutter_application_1/ios/Flutter/AppFrameworkInfo.plist) | HTML shell ของ Flutter Web และ metadata framework iOS; ไม่ได้วาดหน้าร้านด้วย HTML แยก |
| [create_admin.js](/D:/Project_Main/my_app/scripts/create_admin.js), [create_customer.js](/D:/Project_Main/my_app/create_customer.js), [create_test_user.js](/D:/Project_Main/my_app/create_test_user.js) | helper สร้างบัญชีสำหรับตั้งค่า/พัฒนา; ไม่ใช่ route ที่ลูกค้าเรียกจากแอป |
| [test_db.js](/D:/Project_Main/my_app/test_db.js), [test.http](/D:/Project_Main/my_app/test.http), [test/unit.test.js](/D:/Project_Main/my_app/test/unit.test.js), [test/widget_test.dart](/D:/Project_Main/flutter_application_1/test/widget_test.dart) | ไฟล์ตรวจ DB/ตัวอย่าง HTTP/unit/widget; อธิบายว่าเป็นเครื่องมือพัฒนา อย่าอ้างว่าครอบคลุมทุก flow ของแอป |

---

## 10. ตาราง “ชี้ปุ่มแล้วไล่ให้ถึงฐานข้อมูล”

ชื่อ route ด้านล่างตัด prefix `/api` เพื่ออ่านง่าย. รายละเอียด route/HTTP status ดู [ตาราง API ในคู่มือหลัก](/D:/Project_Main/PROJECT_INTERVIEW_GUIDE_TH.md).

| จุดเริ่มที่ผู้ใช้แตะ | Flutter เปลี่ยนอะไร | HTTP/ฝั่ง Node | ตารางหรือที่เก็บข้อมูล | เหตุผลของเงื่อนไข |
|---|---|---|---|---|
| Login | controller → `_login` → CurrentUserService → หน้า role | `POST /login`, `server.js` + `models/user.js` | `user` | ตรวจรหัสด้วย hash, token, active/role ก่อนเข้าแอป |
| Sign up | validate ฟอร์ม → user ใหม่ → HomeShell | `POST /register` | `user` | ป้องกันชื่อซ้ำ/รหัสสั้น/ข้อมูลขาด |
| เปลี่ยนรูป Profile | picker → base64 → service rebuild | `PUT /users/:id/profile-image` | รูปผู้ใช้ในระบบที่ backend จัดเก็บ | เช็กเจ้าของบัญชีและขนาด/ชนิดรูป |
| เปลี่ยนข้อมูลส่วนตัว | ส่ง fullname/username/phone/email | `PUT /users/:id` | `user` | username ต้องไม่ซ้ำและไม่ให้แก้บัญชีคนอื่น |
| กดแบนเนอร์/ดูรูป Home | GET ค่าแล้วแสดงรูป/title | `GET /restaurant/banner` + `/image` | storage/config ฝั่ง server | fallback asset เมื่อ server/ภาพไม่พร้อม |
| เลือกโต๊ะ walk-in | bottom sheet โต๊ะว่าง → ส่ง tableId ไป Menu | `GET /walk-in/tables` | `table`, `restaurant_table_session`, reservation | ไม่ให้เลือกโต๊ะที่มีคนใช้อยู่ |
| เปลี่ยนวัน เวลา คน | state ใหม่ → ล้างโต๊ะเดิมถ้าไม่เข้าเกณฑ์ | `GET /restaurant/holidays`, `GET /availability` | `restaurant_holiday`, `table`, `reservation` | availability ขึ้นกับทุกค่า; โต๊ะเดิมอาจไม่ว่างแล้ว |
| ยืนยันจอง | สร้าง reservation แล้วเปิด Menu ตามโต๊ะ | `POST /reservations` | `reservation`, `table` | server ตรวจ slot/capacity/ชนกันใน transaction |
| ยกเลิกจอง | โหลด Booking ใหม่ | `POST /reservations/:id/cancel` | `reservation` | ตรวจเจ้าของและล่วงหน้าอย่างน้อย 1 ชั่วโมง |
| ค้นหา/เลือกหมวดเมนู | กรอง list ใน memory, ไม่ส่ง HTTP ทุกตัวอักษร | ก่อนหน้านั้น `GET /menu` | `menu` | ทำให้ UI ตอบสนองเร็ว; backend กรองเมนูหยุดขาย |
| เลือก option/กดหมด | state ของ FoodDetail | ไม่มี HTTP จนส่ง order detail | `menu.option_groups_json` | UI ช่วยเลือก แต่ server ตรวจ option อีกครั้ง |
| เพิ่ม/แก้/ล้างตะกร้า | `CartService` + `notifyListeners` | ยังไม่มี HTTP | RAM ของแอป | preview ก่อนสั่ง; ปิดแอปแล้วหาย |
| ยืนยันออร์เดอร์ | สร้าง order แล้ว order details | `POST /orders`, `POST /order-details` | `order`, `order_detail` | server ผูกโต๊ะ/จองและคิดราคาจากข้อมูลจริง |
| ครัวรับ/ทำเสร็จ | admin optimistic UI + reload | `PATCH /admin/order-items/:id/accept`/`status` | `order_detail`, `order` | อาหารแต่ละจานมีสถานะต่างกัน, QR ต้องรอพร้อม |
| เปิด QR | แสดงยอด/QR/เลข PromptPay | `GET /orders/:id/payment-qr` | `order_detail`, payment settings | server คำนวณยอดและตรวจสถานะก่อนออก payload |
| แนบสลิป | picker → base64 → status รอตรวจ | `POST /orders/:id/payment-slip` | `payment` + รูปสลิป | อัปโหลดเป็นหลักฐาน ไม่ยืนยันเงินโดยอัตโนมัติ |
| ยืนยัน/ปฏิเสธสลิป | reload dashboard/payments | `PATCH /admin/payments/:id/review` | `payment`, `order` | admin ตรวจแล้ว transaction ปรับสองสถานะพร้อมกัน |
| เปิด/ปิด notification | switch → preference | `GET/PATCH /notification-preference` | `user.notification_enabled` | ส่ง push ตามค่าปัจจุบัน; ประวัติสีใช้ค่าตอนข้อความเกิด |
| ส่งเตือนใกล้เวลาจอง | ไม่มีปุ่ม; worker รันฝั่ง server | `notifications.js` + `reservation_reminders.js` | `reservation`, `notification_delivery`, `customer_notification` | 60 นาทีและ 10 นาทีครั้งละหนึ่ง, key ป้องกันซ้ำ |
| แก้เมนู/โต๊ะ/วันหยุด | admin form → reload | `/admin/menu`, `/admin/tables`, `/admin/holidays` | `menu`, `table`, `restaurant_holiday` | ส่งผลต่อข้อมูลที่ลูกค้าจอง/สั่งรอบถัดไป |

**วิธีอธิบาย “ทำไมต้องมีโค้ดชั้นนี้”**: UI บอกผู้ใช้และกันข้อผิดพลาดที่มองเห็นทันที; `ApiService` ซ่อน HTTP ซ้ำ; route ตรวจ token/สิทธิ์/รูปแบบ request; model ทำ SQL และ transaction; DB เก็บข้อมูลถาวร. การเช็กเงื่อนไขซ้ำที่ UI และ server จึงไม่ใช่โค้ดซ้ำโดยเปล่าประโยชน์: UI เพื่อประสบการณ์ใช้, server เพื่อความถูกต้องเมื่อมีหลายเครื่องหรือ request ที่ไม่ได้มาจาก UI.

---

## 11. คำถามแบบชี้จอที่มักต่อยอดไปถึงเหตุผลของโค้ด

1. **“ทำไมแตะรูปอาหารในหน้า Menu จากแถบล่างแล้วสั่งไม่ได้?”** — แท็บนั้นเปิด `FoodMenuPage()` โดยไม่มี reservationId หรือ walkInTableId. ระบบต้องทราบว่ากำลังสั่งให้โต๊ะใดก่อนสร้าง order; จองโต๊ะก่อนหรือเลือก “สั่งอาหารที่ร้าน” จาก Home. โค้ดป้องกันใน `_openFoodDetail` ไม่ใช่ปัญหารูป/เมนู.
2. **“ทำไมปุ่ม + บนการ์ดหาย?”** — `FoodMenuPage` ใช้การ์ดแตะเปิดรายละเอียดเพื่อเลือกรายการย่อยและหมายเหตุก่อนเพิ่ม; UI นี้ไม่มีปุ่ม + ส่วน `FoodCard` ที่ Home ยังมี action แต่แสดงข้อความให้เลือกโต๊ะก่อน.
3. **“ดาว rating อยู่ไหน?”** — field `rating` และข้อมูล mock ยังอยู่ใน model/food_data แต่ UI เมนูจริงไม่วาดดาว. ไม่มีระบบให้คะแนนที่ต้องไปอธิบายเป็น feature.
4. **“ปฏิทินแดง เขียว เทา หมายถึงอะไร?”** — แดง=วันปิดจากอาทิตย์/holiday; เขียว=วันและเวลาตามกฎที่เลือกจองได้; เทา=ยังไม่อยู่ในช่วงจองหรือเลือกไม่ได้. เขียวไม่รับประกันว่าโต๊ะว่าง; availability ตรวจต่อ.
5. **“ทำไมเลือกวันแล้วโต๊ะเดิมหาย?”** — `_loadTables` โหลดข้อมูลวัน/เวลา/จำนวนคนใหม่; ถ้า id โต๊ะที่เลือกไม่อยู่ในผลใหม่จะล้าง selection เพื่อป้องกันส่งจองโต๊ะที่ไม่ว่าง/รองรับคนไม่พอ.
6. **“ประวัติการจองไม่เหมือนแท็บจองหรือ?”** — แท็บ Booking แสดง active ตาม API default; Profile → History ใช้ `view=history` ครบสถานะ. `bookingDate` คือวันกดจอง, `diningDate/diningTime` คือวันเวลามาใช้บริการ.
7. **“เมนูหมดคืออะไร? วัตถุดิบย่อยหมดได้ไหม?”** — `statusmenu_id=2` หยุดเมนูทั้งรายการ; option แต่ละตัวมี `available=false` แยก จึงขายเมนูเดิมได้แต่เลือก option นั้นไม่ได้. server ตรวจตอนสั่งด้วย.
8. **“ทำไมราคาในตะกร้าอาจต่างจากใบชำระ?”** — ตะกร้าเป็น preview ใน RAM จากราคาเมนูที่โหลดมา. Server ตรวจเมนูและ option ปัจจุบันและคำนวณยอดจริง; ราคาใน `order_detail` เป็น snapshot ณ ตอนส่งรายการ.
9. **“กดชำระเงินจากตะกร้าแล้วจ่ายแล้วหรือยัง?”** — ยังไม่จ่าย. ไป `PaymentPage` เพื่อยืนยันสร้างออร์เดอร์; รอครัวทำเสร็จจึงมี PaymentQrPage. ชื่อปุ่มในตะกร้าไม่ตรงกับขั้นตอนจริงและควรแก้ UI.
10. **“รูป QR ที่เห็นมาจากไหน?”** — server สร้าง payload PromptPay จากเบอร์/เลขประจำตัวที่ admin ตั้ง + ยอดจริง; Flutter `QrImageView` วาด QR. ไม่ได้เก็บรูป QR แยกแต่ละออร์เดอร์เป็นไฟล์.
11. **“ส่งสลิปแล้วทำไมยอดขายยังไม่ขึ้น?”** — payment status รอตรวจ; admin ต้องยืนยันก่อน `payment_status_id=1` และออร์เดอร์เป็นชำระแล้ว. ไม่มี bank API ตรวจเงินจริงอัตโนมัติ.
12. **“ทำไมกระดิ่งบางอันส้ม บางอันเทา และกดไม่ได้?”** — `notifications_enabled` เป็น snapshot ตอนส่งแต่ละข้อความ, `IgnorePointer` ไม่ให้ tap. Switch ปัจจุบันมีผลกับข้อความใหม่และ push เท่านั้น.
13. **“แจ้งเตือน 1 ชั่วโมงกับ 10 นาทีทำได้อย่างไร?”** — backend worker ตรวจ reservation เป็นรอบ, ฟังก์ชัน reminder สร้าง event 60/10 นาทีและ unique delivery key กันซ้ำ. ต้องมี backend ทำงานต่อเนื่อง ไม่ใช่ตั้ง timer ไว้ในหน้า Flutter ที่อาจถูกปิด.
14. **“ยอดขายกราฟเป็นยอดจากไหน?”** — query ชำระแล้ว/สลิปผ่าน, รวมรายวันในเดือนแล้ว `_SalesChartPainter` วาดเส้น. การจองไม่ใช่ยอดขายและออร์เดอร์รอชำระไม่ถูกรวม.
15. **“ตัวเลขการจองวันนี้เป็นรายการที่สำเร็จทั้งหมดหรือ?”** — query ปัจจุบันนับรายการตามวันที่รวมสถานะยกเลิก; UI ใช้ชื่อกว้างว่า “การจองวันนี้”. ควรเปลี่ยนคำหรือ query ถ้าต้องการเฉพาะยืนยัน/มาใช้บริการ.
16. **“ทำไมชื่อ ‘เมนูยอดนิยม’ ที่ Home ไม่เหมือนสถิติ?”** — Home โหลดเมนูปกติแล้วเอาสี่รายการแรก; หน้า Stats และ admin จึงเป็นอันดับที่คำนวณจากยอดจริง. อย่าบอกว่า Home เรียงยอดขาย.
17. **“เหตุใดหน้ารายละเอียดการจองจึงขึ้น Pending ทั้งที่ประวัติว่า Confirmed?”** — mapping ใน `ReservationDetailPage` ผิดเมื่อเทียบสถานะ DB, อีกทั้งแสดง `tableId`. เป็น bug ที่ต้องแก้ด้วย formatter/DTO กลาง; อย่าตีความว่า DB เปลี่ยนสถานะเอง.
18. **“หากปิดแอปแล้วข้อมูลใดหาย?”** — `CurrentUserService` และ `CartService` อยู่ใน RAM; ต้อง login ใหม่, ตะกร้าหาย. Reservation/order/history เก็บ DB จึงโหลดกลับได้. ขณะ logout ปัจจุบันยังไม่ล้าง cart singleton โดยตรง.
19. **“ถ้าแอดมินเปลี่ยนชื่อร้าน/รูปเมนู ลูกค้าเห็นอย่างไร?”** — admin บันทึกผ่าน API, Home/Menu โหลดค่าจาก server เมื่อโหลดใหม่. Splash เป็น asset/static text. รูปเมนูที่แอดมินกำหนดเปิดผ่าน endpoint image; เมนูที่เปิดขาย ณ 15 ตุลาคม 2026 มีภาพอาหารตรงชื่อเป็น asset สำรองใน Flutter ด้วย จึงไม่ย้อนแสดงรูปห้องอาหารเมื่อไฟล์จาก server โหลดไม่สำเร็จ.
20. **“แก้ชื่อผู้ใช้ admin ที่หน้าไหน?”** — ใน UI หลังบ้านไฟล์ปัจจุบันมีแก้ **บัญชีลูกค้า** และตั้งค่าร้าน แต่ไม่มีหน้า profile ของ admin เอง. หากอาจารย์ชี้แล้วถาม ให้ตอบตรง ๆ ว่ายังไม่มีฟอร์มแก้บัญชี admin ใน dashboard นี้.

## 12. จุดสาธิต 60 นาทีโดยเปิดหน้าจอและโค้ดสลับกัน

| นาที | โชว์แอป | เปิดไฟล์และเล่าประเด็น |
|---|---|---|
| 0–5 | Splash → Login | `main.dart`, `login_page.dart`, `auth_token.js`: entry/role/token |
| 5–12 | Home/แบนเนอร์/เลือกโต๊ะหน้าร้าน | `home_page.dart`, `table.js`, `server.js`: data จาก API เทียบ asset fallback |
| 12–22 | จองโต๊ะ/ปฏิทิน/วันหยุด/ประวัติ | `reservation_page.dart`, `booking_rules.js`, `reservation.js`: กติกาและ transaction |
| 22–32 | Menu → Detail → Cart | `food_menu_page.dart`, `food_detail_page.dart`, `cart_service.dart`, `menu_options.js`: option หมดและราคา |
| 32–39 | ยืนยัน order/ครัว | `payment_page.dart`, `order.js`, `order_detail.js`, `admin_dashboard_page.dart`: สถานะจานกับออร์เดอร์ |
| 39–46 | QR/สลิป/ยอดขาย | `payment_qr_page.dart`, `promptpay.js`, `payment.js`, `_SalesChartPainter`: เงินเกิดเมื่ออนุมัติ |
| 46–52 | Profile/notifications/reminders | `profile_page.dart`, `notification_inbox_page.dart`, `notifications.js`: preference snapshot/FCM |
| 52–60 | Admin manage + คำถาม | `admin_dashboard_page.dart`, SQL migrations, ข้อจำกัดที่รู้จริง: Firebase placeholder, session RAM, Home popular, status detail |

คำพูดปิดที่เหมาะกับงานปี 4: “ระบบแบ่ง Flutter สำหรับการใช้งาน, Node สำหรับสิทธิ์และกฎธุรกิจ, MySQL สำหรับข้อมูลถาวร. ผมตรวจความถูกต้องของราคา โต๊ะ และสถานะบน server เพราะผู้ใช้หลายเครื่องหรือ request ที่แก้เองข้ามเงื่อนไข UI ได้. จุดที่ยังต้องพัฒนาต่อคือการตั้ง Firebase จริง, session storage, label บางจุด และ mapping สถานะหน้ารายละเอียดจอง.”
