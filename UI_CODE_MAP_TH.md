# แผนที่ UI → โค้ดจริง Restaurant App

เอกสารนี้อ่านคู่กับ PDF ภาพประกอบ: หมายเลข **06.3** หมายถึงภาพหน้าที่ 06 จุดหมายเลข 3. ข้อความในกรอบเป็นโค้ดจริงบางบรรทัดจากไฟล์ ณ 15 ตุลาคม 2026; เปิดไฟล์ตามพาธเพื่ออ่านฟังก์ชันทั้งหมดและเงื่อนไขที่อยู่รอบข้าง

## 01 หน้าเปิดแอป Splash

### 01.1 ภาพพื้นหลัง

- อยู่ที่: [flutter_application_1/lib/pages/splash_page.dart:31](<flutter_application_1/lib/pages/splash_page.dart:31>)
- หน้าที่: Image.asset และ BoxFit.cover; ใช้ asset ในแอป
- โค้ดช่วงบรรทัด 30–38:

```dart
  30 │           children: [
  31 │             Image.asset(
  32 │               'assets/restaurant.jpg',
  33 │               fit: BoxFit.cover,
  34 │             ),
  35 │
  36 │             Container(
  37 │               color: Colors.black.withValues(alpha: .52),
  38 │             ),
```

### 01.2 ชื่อและคำโปรย

- อยู่ที่: [flutter_application_1/lib/pages/splash_page.dart:64](<flutter_application_1/lib/pages/splash_page.dart:64>)
- หน้าที่: ข้อความคงที่ ไม่ใช้ชื่อแบนเนอร์ที่แอดมินแก้
- โค้ดช่วงบรรทัด 64–71:

```dart
  64 │                   const Text(
  65 │                     'ร้านอาหาร',
  66 │                     style: TextStyle(
  67 │                       color: Colors.white,
  68 │                       fontSize: 31,
  69 │                       fontWeight: FontWeight.w600,
  70 │                     ),
  71 │                   ),
```

### 01.3 พื้นที่แตะทั้งหน้า

- อยู่ที่: [flutter_application_1/lib/pages/splash_page.dart:25](<flutter_application_1/lib/pages/splash_page.dart:25>)
- หน้าที่: GestureDetector เรียก pushReplacement ไป Welcome
- โค้ดช่วงบรรทัด 24–32:

```dart
  24 │     return Scaffold(
  25 │       body: GestureDetector(
  26 │         onTap: _goToWelcome,
  27 │
  28 │         child: Stack(
  29 │           fit: StackFit.expand,
  30 │           children: [
  31 │             Image.asset(
  32 │               'assets/restaurant.jpg',
```

## 02 หน้าต้อนรับ Welcome

### 02.1 โลโก้และสี

- อยู่ที่: [flutter_application_1/lib/pages/welcome_page.dart:19](<flutter_application_1/lib/pages/welcome_page.dart:19>)
- หน้าที่: วาดจาก widget และ AppColors ไม่ใช่รูปอัปโหลด
- โค้ดช่วงบรรทัด 18–26:

```dart
  18 │             child: Column(
  19 │               children: [
  20 │                 const SizedBox(height: 35),
  21 │                 Container(
  22 │                   width: 90,
  23 │                   height: 90,
  24 │                   decoration: BoxDecoration(
  25 │                     color: AppColors.orangeLight,
  26 │                     shape: BoxShape.circle,
```

### 02.2 ข้อความ

- อยู่ที่: [flutter_application_1/lib/pages/welcome_page.dart:39](<flutter_application_1/lib/pages/welcome_page.dart:39>)
- หน้าที่: SingleChildScrollView รองรับจอเล็ก
- โค้ดช่วงบรรทัด 38–46:

```dart
  38 │                 const SizedBox(height: 25),
  39 │                 const Text(
  40 │                   'Welcome to',
  41 │                   style: TextStyle(
  42 │                     fontSize: 25,
  43 │                     fontWeight: FontWeight.w400,
  44 │                   ),
  45 │                 ),
  46 │                 const SizedBox(height: 4),
```

### 02.3 Log in

- อยู่ที่: [flutter_application_1/lib/pages/welcome_page.dart:68](<flutter_application_1/lib/pages/welcome_page.dart:68>)
- หน้าที่: Navigator.push ไป LoginPage
- โค้ดช่วงบรรทัด 67–75:

```dart
  67 │                   text: 'Log in',
  68 │                   onPressed: () => Navigator.push(
  69 │                     context,
  70 │                     MaterialPageRoute(
  71 │                       builder: (_) => const LoginPage(),
  72 │                     ),
  73 │                   ),
  74 │                 ),
  75 │                 const SizedBox(height: 13),
```

### 02.4 Sign up

- อยู่ที่: [flutter_application_1/lib/pages/welcome_page.dart:78](<flutter_application_1/lib/pages/welcome_page.dart:78>)
- หน้าที่: Navigator.push ไป SignUpPage
- โค้ดช่วงบรรทัด 77–85:

```dart
  77 │                   text: 'Sign up',
  78 │                   onPressed: () => Navigator.push(
  79 │                     context,
  80 │                     MaterialPageRoute(
  81 │                       builder: (_) => const SignUpPage(),
  82 │                     ),
  83 │                   ),
  84 │                 ),
  85 │                 const SizedBox(height: 55),
```

## 03 เข้าสู่ระบบ Login

### 03.1 ย้อนกลับ

- อยู่ที่: [flutter_application_1/lib/pages/login_page.dart:84](<flutter_application_1/lib/pages/login_page.dart:84>)
- หน้าที่: กลับหน้า Welcome
- โค้ดช่วงบรรทัด 83–91:

```dart
  83 │       appBar: AppBar(
  84 │         backgroundColor: AppColors.cream,
  85 │         leading: IconButton(
  86 │           onPressed: () => Navigator.pop(context),
  87 │           icon: const Icon(Icons.arrow_back),
  88 │         ),
  89 │       ),
  90 │       body: Center(
  91 │         child: SingleChildScrollView(
```

### 03.2 ชื่อผู้ใช้

- อยู่ที่: [flutter_application_1/lib/pages/login_page.dart:19](<flutter_application_1/lib/pages/login_page.dart:19>)
- หน้าที่: TextEditingController เก็บค่าฟอร์ม
- โค้ดช่วงบรรทัด 18–26:

```dart
  18 │ class _LoginPageState extends State<LoginPage> {
  19 │   final username = TextEditingController();
  20 │   final password = TextEditingController();
  21 │
  22 │   bool hide = true;
  23 │   bool loading = false;
  24 │
  25 │   @override
  26 │   void dispose() {
```

### 03.3 รหัส/รูปตา

- อยู่ที่: [flutter_application_1/lib/pages/login_page.dart:134](<flutter_application_1/lib/pages/login_page.dart:134>)
- หน้าที่: obscureText สลับซ่อนหรือแสดง
- โค้ดช่วงบรรทัด 133–141:

```dart
 133 │                     hintText: 'กรุณาระบุรหัสผ่าน',
 134 │                     suffixIcon: IconButton(
 135 │                       onPressed: () {
 136 │                         setState(() {
 137 │                           hide = !hide;
 138 │                         });
 139 │                       },
 140 │                       icon: Icon(
 141 │                         hide
```

### 03.4 ยืนยัน

- อยู่ที่: [flutter_application_1/lib/pages/login_page.dart:32](<flutter_application_1/lib/pages/login_page.dart:32>)
- หน้าที่: POST /login; แยก role ไป Admin หรือ HomeShell
- โค้ดช่วงบรรทัด 32–39:

```dart
  32 │   Future<void> _login() async {
  33 │     if (loading) return;
  34 │     if (username.text.trim().isEmpty || password.text.isEmpty) {
  35 │       ScaffoldMessenger.of(context).showSnackBar(
  36 │         const SnackBar(content: Text('กรุณากรอก Username และ Password')),
  37 │       );
  38 │       return;
  39 │     }
```

### 03.5 สมัครสมาชิก

- อยู่ที่: [flutter_application_1/lib/pages/login_page.dart:166](<flutter_application_1/lib/pages/login_page.dart:166>)
- หน้าที่: เปิด SignUpPage
- โค้ดช่วงบรรทัด 165–173:

```dart
 165 │                     },
 166 │                     child: const Text.rich(
 167 │                       TextSpan(
 168 │                         text: "Don't have an account? ",
 169 │                         style: TextStyle(color: Colors.grey, fontSize: 12),
 170 │                         children: [
 171 │                           TextSpan(
 172 │                             text: 'Sign up',
 173 │                             style: TextStyle(
```

## 04 สมัครสมาชิก Sign up

### 04.1 หัวข้อ

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:136](<flutter_application_1/lib/pages/signup_page.dart:136>)
- หน้าที่: หน้าฟอร์มสำหรับ role ลูกค้า
- โค้ดช่วงบรรทัด 135–143:

```dart
 135 │         leading: IconButton(
 136 │           onPressed: () => Navigator.pop(context),
 137 │           icon: const Icon(Icons.arrow_back),
 138 │         ),
 139 │       ),
 140 │       body: Center(
 141 │         child: SingleChildScrollView(
 142 │           padding: const EdgeInsets.fromLTRB(30, 5, 30, 30),
 143 │           child: ConstrainedBox(
```

### 04.2 Username

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:158](<flutter_application_1/lib/pages/signup_page.dart:158>)
- หน้าที่: อย่างน้อย 3 ตัว; server เช็กชื่อซ้ำ
- โค้ดช่วงบรรทัด 158–164:

```dart
 158 │                 TextField(
 159 │                   controller: username,
 160 │                   keyboardType: TextInputType.text,
 161 │                   decoration: const InputDecoration(
 162 │                     hintText: 'Username',
 163 │                   ),
 164 │                 ),
```

### 04.3 ชื่อจริง

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:168](<flutter_application_1/lib/pages/signup_page.dart:168>)
- หน้าที่: ข้อมูลที่ใช้แสดงในการจอง
- โค้ดช่วงบรรทัด 168–175:

```dart
 168 │                 TextField(
 169 │                   controller: name,
 170 │                   decoration: const InputDecoration(
 171 │                     hintText: 'ชื่อ - นามสกุล',
 172 │                   ),
 173 │                 ),
 174 │
 175 │                 const SizedBox(height: 14),
```

### 04.4 โทร/อีเมล

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:177](<flutter_application_1/lib/pages/signup_page.dart:177>)
- หน้าที่: เบอร์จำกัดตัวเลข 10 หลัก; อีเมลไม่บังคับ
- โค้ดช่วงบรรทัด 177–184:

```dart
 177 │                 TextField(
 178 │                   controller: phone,
 179 │                   keyboardType: TextInputType.number,
 180 │                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
 181 │                   maxLength: 10,
 182 │                   decoration: const InputDecoration(
 183 │                     hintText: 'เบอร์โทรศัพท์',
 184 │                     counterText: '',
```

### 04.5 รหัสสองช่อง

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:200](<flutter_application_1/lib/pages/signup_page.dart:200>)
- หน้าที่: ขั้นต่ำ 8 ตัวและต้องตรงกัน
- โค้ดช่วงบรรทัด 200–207:

```dart
 200 │                 TextField(
 201 │                   controller: password,
 202 │                   obscureText: hidePassword,
 203 │                   decoration: InputDecoration(
 204 │                     hintText: 'รหัสผ่าน',
 205 │                     suffixIcon: IconButton(
 206 │                       onPressed: () {
 207 │                         setState(() {
```

### 04.6 สมัคร

- อยู่ที่: [flutter_application_1/lib/pages/signup_page.dart:81](<flutter_application_1/lib/pages/signup_page.dart:81>)
- หน้าที่: POST /register แล้วเข้า HomeShell
- โค้ดช่วงบรรทัด 81–88:

```dart
  81 │   Future<void> _completeSignUp() async {
  82 │     setState(() {
  83 │       loading = true;
  84 │     });
  85 │
  86 │     try {
  87 │       final result = await ApiService.register(
  88 │         username: username.text.trim(),
```

## 05 หน้าแรก Home

### 05.1 แบนเนอร์

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:617](<flutter_application_1/lib/pages/home_page.dart:617>)
- หน้าที่: GET /restaurant/banner; fallback รูป asset
- โค้ดช่วงบรรทัด 616–624:

```dart
 616 │               bannerImage == null
 617 │                   ? Image.asset('assets/restaurant.jpg', fit: BoxFit.cover)
 618 │                   : Image.network(
 619 │                       ApiService.restaurantBannerImageUrl(bannerImage!),
 620 │                       fit: BoxFit.cover,
 621 │                       errorBuilder: (_, _, _) => Image.asset('assets/restaurant.jpg', fit: BoxFit.cover),
 622 │                     ),
 623 │
 624 │               Container(
```

### 05.2 3 ปุ่มหลัก

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:97](<flutter_application_1/lib/pages/home_page.dart:97>)
- หน้าที่: เปิดจอง/ดูเมนู/เลือกโต๊ะ walk-in
- โค้ดช่วงบรรทัด 97–104:

```dart
  97 │   void _openFoodMenu() {
  98 │     Navigator.push(
  99 │       context,
 100 │       MaterialPageRoute(
 101 │         builder: (_) => FoodMenuPage(
 102 │           initialCategory: selectedCategory,
 103 │           initialSearch: search,
 104 │         ),
```

### 05.3 ถุง

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:230](<flutter_application_1/lib/pages/home_page.dart:230>)
- หน้าที่: badge จาก CartService; Home ยังไม่เปิด Cart โดยตรง
- โค้ดช่วงบรรทัด 229–237:

```dart
 229 │                       animation:
 230 │                           CartService
 231 │                               .instance,
 232 │
 233 │                       builder:
 234 │                           (_, _) {
 235 │                         final count =
 236 │                             CartService
 237 │                                 .instance
```

### 05.4 ค้นหา/หมวด

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:35](<flutter_application_1/lib/pages/home_page.dart:35>)
- หน้าที่: ค้นหาและกรองทั้งหมด/ข้าว/เส้น/น้ำดื่ม/อื่นๆ บนข้อมูลที่โหลด
- โค้ดช่วงบรรทัด 35–42:

```dart
  35 │   Future<void> _openHomeCategoryFilter() async {
  36 │     const categories = ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'];
  37 │     final chosen = await showModalBottomSheet<String>(
  38 │       context: context,
  39 │       showDragHandle: true,
  40 │       builder: (sheetContext) => SafeArea(
  41 │         child: Column(mainAxisSize: MainAxisSize.min, children: [
  42 │           const Padding(
```

### 05.5 การ์ดจอง

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:819](<flutter_application_1/lib/pages/home_page.dart:819>)
- หน้าที่: ทางลัดไปหน้าจองใหม่
- โค้ดช่วงบรรทัด 818–825:

```dart
 818 │     return InkWell(
 819 │       onTap:
 820 │           onTap,
 821 │
 822 │       borderRadius:
 823 │           BorderRadius.circular(
 824 │         18,
 825 │       ),
```

### 05.6 4 เมนู

- อยู่ที่: [flutter_application_1/lib/pages/home_page.dart:526](<flutter_application_1/lib/pages/home_page.dart:526>)
- หน้าที่: เอา 4 รายการแรก; ยังไม่ได้เรียงยอดขายจริง
- โค้ดช่วงบรรทัด 526–532:

```dart
 526 │                         return FoodCard(
 527 │                           food:
 528 │                               food,
 529 │
 530 │                           onTap: () {
 531 │                             _showReservationMessage();
 532 │                           },
```

## 06 รายการอาหาร Food Menu

### 06.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:221](<flutter_application_1/lib/pages/food_menu_page.dart:221>)
- หน้าที่: AppBar รายการอาหาร
- โค้ดช่วงบรรทัด 220–228:

```dart
 220 │   @override
 221 │   Widget build(
 222 │     BuildContext context,
 223 │   ) {
 224 │     final filtered =
 225 │         filteredFoods;
 226 │
 227 │     return Scaffold(
 228 │       backgroundColor:
```

### 06.2 กรองหมวด

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:114](<flutter_application_1/lib/pages/food_menu_page.dart:114>)
- หน้าที่: เปิดตัวเลือกหมวด
- โค้ดช่วงบรรทัด 114–121:

```dart
 114 │   Future<void> _openCategoryPicker() async {
 115 │     const categories = ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'];
 116 │     final category = await showModalBottomSheet<String>(
 117 │       context: context,
 118 │       showDragHandle: true,
 119 │       builder: (sheetContext) => SafeArea(
 120 │         child: Column(
 121 │           mainAxisSize: MainAxisSize.min,
```

### 06.3 ถุง/จำนวน

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:168](<flutter_application_1/lib/pages/food_menu_page.dart:168>)
- หน้าที่: เปิด Cart เมื่อมีโต๊ะและรายการ
- โค้ดช่วงบรรทัด 168–175:

```dart
 168 │   void _openCart() {
 169 │     if (!hasOrderContext) {
 170 │       _showReservationMessage();
 171 │
 172 │       return;
 173 │     }
 174 │
 175 │     if (CartService.instance.items.isEmpty) {
```

### 06.4 บริบทโต๊ะ

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:410](<flutter_application_1/lib/pages/food_menu_page.dart:410>)
- หน้าที่: บอกโต๊ะหรือเลขจองที่ออร์เดอร์จะผูก
- โค้ดช่วงบรรทัด 409–417:

```dart
 409 │                             10,
 410 │                       ),
 411 │
 412 │                       const Text(
 413 │                         'โต๊ะ',
 414 │
 415 │                         style:
 416 │                             TextStyle(
 417 │                           color:
```

### 06.5 ค้นหา

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:89](<flutter_application_1/lib/pages/food_menu_page.dart:89>)
- หน้าที่: กรองชื่อเมนูโดยไม่ยิง HTTP ทุกตัวอักษร
- โค้ดช่วงบรรทัด 89–96:

```dart
  89 │   List<Food> get filteredFoods {
  90 │     final keyword =
  91 │         search.trim().toLowerCase();
  92 │
  93 │     return foods.where((food) {
  94 │       final matchesSearch = keyword.isEmpty || food.name.toLowerCase().contains(keyword);
  95 │       final type = _foodCategory(food);
  96 │       final matchesCategory = selectedCategory == 'ทั้งหมด' || type == selectedCategory;
```

### 06.6 หมวด

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:564](<flutter_application_1/lib/pages/food_menu_page.dart:564>)
- หน้าที่: ทั้งหมด/ข้าว/เส้น/น้ำดื่ม/อื่นๆ; เลือกแล้วกรองในเครื่อง
- โค้ดช่วงบรรทัด 563–571:

```dart
 563 │                 scrollDirection: Axis.horizontal,
 564 │                 children: ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].map((category) {
 565 │                   final selected = selectedCategory == category;
 566 │                   return Padding(
 567 │                     padding: const EdgeInsets.only(right: 8),
 568 │                     child: ChoiceChip(
 569 │                       label: Text(category),
 570 │                       selected: selected,
 571 │                       showCheckmark: false,
```

### 06.7 การ์ดอาหาร

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:832](<flutter_application_1/lib/pages/food_menu_page.dart:832>)
- หน้าที่: การ์ดใช้ FoodCard และรูปเฉพาะเมนู; แตะเปิด FoodDetail
- โค้ดช่วงบรรทัด 831–839:

```dart
 831 │   @override
 832 │   Widget build(
 833 │     BuildContext context,
 834 │   ) {
 835 │     return Material(
 836 │       color:
 837 │           Colors.white,
 838 │
 839 │       borderRadius:
```

## 07 รายละเอียดอาหาร Food Detail

### 07.1 ย้อน/ถุง

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:161](<flutter_application_1/lib/pages/food_detail_page.dart:161>)
- หน้าที่: ถุงเปิดตะกร้าโดยส่งบริบทโต๊ะต่อ
- โค้ดช่วงบรรทัด 160–168:

```dart
 160 │     super.dispose();
 161 │   }
 162 │
 163 │   void _openCart() {
 164 │     Navigator.push(
 165 │       context,
 166 │
 167 │       MaterialPageRoute(
 168 │         builder: (_) => CartPage(
```

### 07.2 รูป

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:280](<flutter_application_1/lib/pages/food_detail_page.dart:280>)
- หน้าที่: network หรือ asset fallback
- โค้ดช่วงบรรทัด 279–287:

```dart
 279 │                   ),
 280 │
 281 │                   child: widget.food.imageUrl != null
 282 │                       ? Image.network(widget.food.imageUrl!, height: 240, fit: BoxFit.cover, errorBuilder: (_, _, _) => Image.asset(widget.food.imageAsset, height: 240, fit: BoxFit.cover))
 283 │                       : Image.asset(
 284 │                     widget.food.imageAsset,
 285 │
 286 │                     height:
 287 │                         240,
```

### 07.3 ราคา

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:317](<flutter_application_1/lib/pages/food_detail_page.dart:317>)
- หน้าที่: เมนูน้ำดื่มใช้คำว่า ราคาเครื่องดื่มพื้นฐาน; อาหารใช้ ราคาจานพื้นฐาน
- โค้ดช่วงบรรทัด 316–324:

```dart
 316 │                   children: [
 317 │                     Text(isDrink ? 'ราคาเครื่องดื่มพื้นฐาน' : 'ราคาจานพื้นฐาน', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
 318 │                     const Spacer(),
 319 │
 320 │                     Text(
 321 │                       '฿${base.toStringAsFixed(0)}',
 322 │
 323 │                       style:
 324 │                           const TextStyle(
```

### 07.4 หัวข้อย่อย

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:99](<flutter_application_1/lib/pages/food_detail_page.dart:99>)
- หน้าที่: required/max_select/available จากเมนูใน DB
- โค้ดช่วงบรรทัด 99–106:

```dart
  99 │   Widget _buildOptionGroup(Map<String, dynamic> group) {
 100 │     final groupId = group['id']?.toString() ?? '';
 101 │     final options = (group['options'] as List<dynamic>? ?? [])
 102 │         .map((option) => Map<String, dynamic>.from(option as Map))
 103 │         .toList();
 104 │     final maxSelect = int.tryParse(group['max_select']?.toString() ?? '1') ?? 1;
 105 │     final selected = _selectedOptionIds[groupId] ?? const <String>[];
 106 │     if (options.isEmpty) return const SizedBox.shrink();
```

### 07.5 หมายเหตุ

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:364](<flutter_application_1/lib/pages/food_detail_page.dart:364>)
- หน้าที่: ข้อความส่งต่อไปครัว
- โค้ดช่วงบรรทัด 363–371:

```dart
 363 │                 const SizedBox(
 364 │                   height: 7,
 365 │                 ),
 366 │
 367 │                 TextField(
 368 │                   controller:
 369 │                       noteController,
 370 │
 371 │                   maxLines:
```

### 07.6 จำนวนและเพิ่ม

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:584](<flutter_application_1/lib/pages/food_detail_page.dart:584>)
- หน้าที่: ตรวจ required; รวมราคา preview ใน CartService
- โค้ดช่วงบรรทัด 583–591:

```dart
 583 │                     text:
 584 │                         'เพิ่มลงตะกร้า • ฿${total.toStringAsFixed(0)}',
 585 │
 586 │                     onPressed:
 587 │                         _addToCart,
 588 │                   ),
 589 │                 ),
 590 │               ],
 591 │             ),
```

## 08 ตะกร้า Cart

### 08.1 ชื่อรายการ

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:51](<flutter_application_1/lib/pages/cart_page.dart:51>)
- หน้าที่: ตะกร้าใน RAM
- โค้ดช่วงบรรทัด 51–58:

```dart
  51 │           appBar: AppBar(
  52 │             title:
  53 │                 const Text(
  54 │               'รายการอาหาร',
  55 │             ),
  56 │
  57 │             actions: [
  58 │               if (cart.items.isNotEmpty)
```

### 08.2 ล้างทั้งหมด

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:65](<flutter_application_1/lib/pages/cart_page.dart:65>)
- หน้าที่: ล้างทันทีเมื่อกด
- โค้ดช่วงบรรทัด 64–72:

```dart
  64 │                       const Text(
  65 │                     'ล้างทั้งหมด',
  66 │
  67 │                     style:
  68 │                         TextStyle(
  69 │                       color:
  70 │                           AppColors
  71 │                               .orange,
  72 │                     ),
```

### 08.3 เลขโต๊ะ

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:118](<flutter_application_1/lib/pages/cart_page.dart:118>)
- หน้าที่: บริบทของการจอง/โต๊ะหน้าร้าน
- โค้ดช่วงบรรทัด 118–125:

```dart
 118 │                       child:
 119 │                           Row(
 120 │                         children: [
 121 │                           const Icon(
 122 │                             Icons
 123 │                                 .table_restaurant_outlined,
 124 │
 125 │                             color:
```

### 08.4 −/+

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:442](<flutter_application_1/lib/pages/cart_page.dart:442>)
- หน้าที่: ปรับจำนวนหรือเอาออกเมื่อเหลือ 1
- โค้ดช่วงบรรทัด 441–449:

```dart
 441 │                                       children: [
 442 │                                         _circle(
 443 │                                           icon:
 444 │                                               Icons
 445 │                                                   .remove,
 446 │
 447 │                                           onTap:
 448 │                                               () {
 449 │                                             cart
```

### 08.5 การ์ดเมนู

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:714](<flutter_application_1/lib/pages/cart_page.dart:714>)
- หน้าที่: แก้ตัวเลือกและหมายเหตุได้
- โค้ดช่วงบรรทัด 714–721:

```dart
 714 │ Future<void> _editCartItem(BuildContext context, CartItem item) async {
 715 │   final groups = item.food.optionGroups;
 716 │   final selected = <String, List<String>>{};
 717 │   for (final choice in item.selectedOptions) {
 718 │     final groupId = choice['group_id']?.toString() ?? '';
 719 │     if (groupId.isNotEmpty) (selected[groupId] ??= []).add(choice['option_id']?.toString() ?? '');
 720 │   }
 721 │   for (final rawGroup in groups) {
```

### 08.6 ยอดรวม

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:548](<flutter_application_1/lib/pages/cart_page.dart:548>)
- หน้าที่: preview ฝั่ง client
- โค้ดช่วงบรรทัด 547–555:

```dart
 547 │                           _summary(
 548 │                             'ยอดรวมสินค้า',
 549 │
 550 │                             '฿${subtotal.toStringAsFixed(0)}',
 551 │                           ),
 552 │
 553 │                           const Divider(
 554 │                             height:
 555 │                                 22,
```

### 08.7 ปุ่มชำระเงิน

- อยู่ที่: [flutter_application_1/lib/pages/cart_page.dart:579](<flutter_application_1/lib/pages/cart_page.dart:579>)
- หน้าที่: ไปยืนยันออร์เดอร์; ยังไม่โอนเงินจริง
- โค้ดช่วงบรรทัด 579–585:

```dart
 579 │                       onPressed:
 580 │                           cart.items.isEmpty
 581 │                               ? null
 582 │                               : () {
 583 │                                   Navigator
 584 │                                       .push(
 585 │                                     context,
```

## 09 ยืนยันรายการอาหาร

### 09.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/payment_page.dart:189](<flutter_application_1/lib/pages/payment_page.dart:189>)
- หน้าที่: แม้ไฟล์ชื่อ PaymentPage หน้านี้คือยืนยันสั่ง
- โค้ดช่วงบรรทัด 188–196:

```dart
 188 │       appBar: AppBar(
 189 │         title: const Text('ยืนยันรายการอาหาร'),
 190 │       ),
 191 │       body: ListView(
 192 │         padding: const EdgeInsets.all(14),
 193 │         children: [
 194 │           Container(
 195 │             padding: const EdgeInsets.all(22),
 196 │             decoration: BoxDecoration(
```

### 09.2 โต๊ะ/ยอด/สถานะ

- อยู่ที่: [flutter_application_1/lib/pages/payment_page.dart:203](<flutter_application_1/lib/pages/payment_page.dart:203>)
- หน้าที่: ยอดจากตะกร้าและสถานะรอรับออร์เดอร์
- โค้ดช่วงบรรทัด 202–210:

```dart
 202 │         _row(
 203 │           'โต๊ะ',
 204 │                   widget.reservationTable ?? (widget.tableId == null ? '-' : 'โต๊ะหน้าร้าน'),
 205 │                 ),
 206 │                 const Divider(height: 22),
 207 │                 _row(
 208 │                   'ยอดค่าอาหาร',
 209 │                   '฿${displayAmount.toStringAsFixed(2)}',
 210 │                 ),
```

### 09.3 คำอธิบาย QR

- อยู่ที่: [flutter_application_1/lib/pages/payment_page.dart:226](<flutter_application_1/lib/pages/payment_page.dart:226>)
- หน้าที่: ชำระหลังครัวทำเสร็จ
- โค้ดช่วงบรรทัด 225–233:

```dart
 225 │               leading: Icon(Icons.qr_code_2, color: AppColors.orange),
 226 │               title: Text('ชำระหลังอาหารทำเสร็จ'),
 227 │               subtitle: Text('ระบบจะแจ้งเตือนและแสดง QR PromptPay พร้อมยอดและรายการอาหาร'),
 228 │             ),
 229 │           ),
 230 │
 231 │           const SizedBox(height: 28),
 232 │
 233 │           PrimaryButton(
```

### 09.4 ยืนยัน

- อยู่ที่: [flutter_application_1/lib/pages/payment_page.dart:73](<flutter_application_1/lib/pages/payment_page.dart:73>)
- หน้าที่: POST /orders แล้ว /order-details; สำเร็จไป ConfirmationPage
- โค้ดช่วงบรรทัด 73–80:

```dart
  73 │   Future<void> _confirmPayment() async {
  74 │     if (_isSaving) return;
  75 │
  76 │     final cart = CartService.instance;
  77 │     final user = CurrentUserService.instance.user;
  78 │
  79 │     if (user == null) {
  80 │       _showError('กรุณาเข้าสู่ระบบก่อน');
```

## 10 จองโต๊ะใหม่ Reservation

### 10.1 ชื่อ/ย้อน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:451](<flutter_application_1/lib/pages/reservation_page.dart:451>)
- หน้าที่: หน้าฟอร์มการจอง
- โค้ดช่วงบรรทัด 450–457:

```dart
 450 │   @override
 451 │   Widget build(
 452 │     BuildContext context,
 453 │   ) {
 454 │     final date =
 455 │         '${selectedDate.day.toString().padLeft(2, '0')}/'
 456 │         '${selectedDate.month.toString().padLeft(2, '0')}/'
 457 │         '${selectedDate.year}';
```

### 10.2 ภาพร้าน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:451](<flutter_application_1/lib/pages/reservation_page.dart:451>)
- หน้าที่: asset ประกอบ
- โค้ดช่วงบรรทัด 450–457:

```dart
 450 │   @override
 451 │   Widget build(
 452 │     BuildContext context,
 453 │   ) {
 454 │     final date =
 455 │         '${selectedDate.day.toString().padLeft(2, '0')}/'
 456 │         '${selectedDate.month.toString().padLeft(2, '0')}/'
 457 │         '${selectedDate.year}';
```

### 10.3 วัน/เวลา

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:197](<flutter_application_1/lib/pages/reservation_page.dart:197>)
- หน้าที่: แตะช่องเวลาเปิดตัวเลือกชั่วโมงและนาที; ไม่ให้พิมพ์; เลือกแล้วโหลดโต๊ะใหม่
- โค้ดช่วงบรรทัด 197–204:

```dart
 197 │   Future<void> _pickTime() async {
 198 │     final now = DateTime.now();
 199 │     final opening = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
 200 │     final lastBooking = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13);
 201 │     final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute)
 202 │         .add(const Duration(minutes: 1));
 203 │     final firstBooking = DateUtils.isSameDay(selectedDate, now) && nextMinute.isAfter(opening)
 204 │         ? nextMinute
```

### 10.4 สีวัน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1283](<flutter_application_1/lib/pages/reservation_page.dart:1283>)
- หน้าที่: วันสีแดงปิด สีเขียวเปิด สีเทายังไม่กำหนด/เลือกไม่ได้
- โค้ดช่วงบรรทัด 1283–1290:

```dart
1283 │   _ReservationDateStatus _statusFor(DateTime date) {
1284 │     final key = _formatDate(date);
1285 │     if (date.weekday == DateTime.sunday || _holidayDates.contains(key)) {
1286 │       return _ReservationDateStatus.closed;
1287 │     }
1288 │     final day = DateUtils.dateOnly(date);
1289 │     final today = DateUtils.dateOnly(DateTime.now());
1290 │     final insideBookingWindow = !day.isBefore(widget.firstDate) &&
```

### 10.5 จำนวนคน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1161](<flutter_application_1/lib/pages/reservation_page.dart:1161>)
- หน้าที่: เพิ่มลดผู้จองในช่วงที่ UI อนุญาต
- โค้ดช่วงบรรทัด 1161–1168:

```dart
1161 │   Widget _guestSelector() => Container(
1162 │         padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
1163 │         decoration: BoxDecoration(
1164 │           color: Colors.white,
1165 │           borderRadius: BorderRadius.circular(15),
1166 │           border: Border.all(color: AppColors.border),
1167 │         ),
1168 │         child: Row(
```

### 10.6 โต๊ะ

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:60](<flutter_application_1/lib/pages/reservation_page.dart:60>)
- หน้าที่: GET availability ตามวัน เวลา และจำนวนคน; เคลียร์โต๊ะเดิมเมื่อเปลี่ยนเวลา
- โค้ดช่วงบรรทัด 60–67:

```dart
  60 │   Future<void> _loadTables() async {
  61 │     final requestId = ++_availabilityRequestId;
  62 │     final requestedTime = selectedTime;
  63 │     final requestedDate = selectedDate;
  64 │     final requestedGuests = guests;
  65 │     try {
  66 │       setState(() {
  67 │         _isLoadingTables = requestedTime != null;
```

### 10.7 ยืนยัน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:333](<flutter_application_1/lib/pages/reservation_page.dart:333>)
- หน้าที่: POST reservations; backend ตรวจช่วงเวลาและโต๊ะซ้ำ
- โค้ดช่วงบรรทัด 333–340:

```dart
 333 │   Future<void> _confirmReservation() async {
 334 │
 335 │     final reservationTime = selectedTime;
 336 │     if (reservationTime == null) {
 337 │       ScaffoldMessenger.of(context).showSnackBar(
 338 │         const SnackBar(content: Text('กรุณาระบุเวลาที่ต้องการจอง')),
 339 │       );
 340 │       return;
```

## 11 ปฏิทินเลือกวัน

### 11.1 เดือน/ปี

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1319](<flutter_application_1/lib/pages/reservation_page.dart:1319>)
- หน้าที่: แสดง พ.ศ. แต่ส่ง API เป็น ค.ศ.
- โค้ดช่วงบรรทัด 1318–1326:

```dart
1318 │   @override
1319 │   Widget build(BuildContext context) {
1320 │     final firstWeekdayOffset = DateTime(_month.year, _month.month, 1).weekday % 7;
1321 │     final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
1322 │     final title = '${_months[_month.month - 1]} ${_month.year + 543}';
1323 │
1324 │     return Dialog(
1325 │       child: ConstrainedBox(
1326 │         constraints: const BoxConstraints(maxWidth: 380),
```

### 11.2 หัววัน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1360](<flutter_application_1/lib/pages/reservation_page.dart:1360>)
- หน้าที่: ตาราง 7 วันต่อสัปดาห์
- โค้ดช่วงบรรทัด 1359–1367:

```dart
1359 │               const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
1360 │             else if (_error != null)
1361 │               SizedBox(
1362 │                 height: 260,
1363 │                 child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
1364 │                   const Icon(Icons.cloud_off_outlined, color: AppColors.grey, size: 32),
1365 │                   const SizedBox(height: 8),
1366 │                   Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey)),
1367 │                   TextButton.icon(onPressed: _loadMonth, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง')),
```

### 11.3 สีแดง

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1283](<flutter_application_1/lib/pages/reservation_page.dart:1283>)
- หน้าที่: วันอาทิตย์/วันหยุดพิเศษ
- โค้ดช่วงบรรทัด 1283–1290:

```dart
1283 │   _ReservationDateStatus _statusFor(DateTime date) {
1284 │     final key = _formatDate(date);
1285 │     if (date.weekday == DateTime.sunday || _holidayDates.contains(key)) {
1286 │       return _ReservationDateStatus.closed;
1287 │     }
1288 │     final day = DateUtils.dateOnly(date);
1289 │     final today = DateUtils.dateOnly(DateTime.now());
1290 │     final insideBookingWindow = !day.isBefore(widget.firstDate) &&
```

### 11.4 สีเขียว

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1283](<flutter_application_1/lib/pages/reservation_page.dart:1283>)
- หน้าที่: อยู่ในช่วงจองและยังเปิด
- โค้ดช่วงบรรทัด 1283–1290:

```dart
1283 │   _ReservationDateStatus _statusFor(DateTime date) {
1284 │     final key = _formatDate(date);
1285 │     if (date.weekday == DateTime.sunday || _holidayDates.contains(key)) {
1286 │       return _ReservationDateStatus.closed;
1287 │     }
1288 │     final day = DateUtils.dateOnly(date);
1289 │     final today = DateUtils.dateOnly(DateTime.now());
1290 │     final insideBookingWindow = !day.isBefore(widget.firstDate) &&
```

### 11.5 สีเทา

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1283](<flutter_application_1/lib/pages/reservation_page.dart:1283>)
- หน้าที่: นอกช่วงหรือเลยเวลาที่เลือกได้
- โค้ดช่วงบรรทัด 1283–1290:

```dart
1283 │   _ReservationDateStatus _statusFor(DateTime date) {
1284 │     final key = _formatDate(date);
1285 │     if (date.weekday == DateTime.sunday || _holidayDates.contains(key)) {
1286 │       return _ReservationDateStatus.closed;
1287 │     }
1288 │     final day = DateUtils.dateOnly(date);
1289 │     final today = DateUtils.dateOnly(DateTime.now());
1290 │     final insideBookingWindow = !day.isBefore(widget.firstDate) &&
```

### 11.6 ตกลง

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:1210](<flutter_application_1/lib/pages/reservation_page.dart:1210>)
- หน้าที่: รับค่ากลับไปหน้าจอง
- โค้ดช่วงบรรทัด 1210–1217:

```dart
1210 │ class _ReservationCalendarDialog extends StatefulWidget {
1211 │   final DateTime initialDate;
1212 │   final DateTime firstDate;
1213 │   final DateTime lastDate;
1214 │
1215 │   const _ReservationCalendarDialog({
1216 │     required this.initialDate,
1217 │     required this.firstDate,
```

## 12 การจองของฉัน Booking

### 12.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:180](<flutter_application_1/lib/pages/booking_page.dart:180>)
- หน้าที่: แท็บปัจจุบันใน HomeShell
- โค้ดช่วงบรรทัด 179–187:

```dart
 179 │   Widget build(BuildContext context) {
 180 │     return Scaffold(
 181 │       backgroundColor: AppColors.background,
 182 │       body: SafeArea(
 183 │         child: RefreshIndicator(
 184 │           onRefresh: _loadReservations,
 185 │           child: ListView(
 186 │             physics:
 187 │                 const AlwaysScrollableScrollPhysics(),
```

### 12.2 การ์ด

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:243](<flutter_application_1/lib/pages/booking_page.dart:243>)
- หน้าที่: รายการ active จาก API; โหลดใหม่ทุก 15 วินาทีและเมื่อกลับเข้าแอป
- โค้ดช่วงบรรทัด 243–250:

```dart
 243 │   Widget _bookingCard(
 244 │     Reservation reservation,
 245 │   ) {
 246 │     final tableNumber =
 247 │         'T${(reservation.tableNumber ?? reservation.tableId).toString().padLeft(3, '0')}';
 248 │
 249 │     return Container(
 250 │       padding: const EdgeInsets.all(13),
```

### 12.3 สถานะ

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:317](<flutter_application_1/lib/pages/booking_page.dart:317>)
- หน้าที่: เลขสถานะจอง 1/4 ที่ยัง active
- โค้ดช่วงบรรทัด 316–324:

```dart
 316 │                 decoration: BoxDecoration(
 317 │                   color: _statusBackground(
 318 │                     reservation
 319 │                         .statusReservationId,
 320 │                   ),
 321 │                   borderRadius:
 322 │                       BorderRadius.circular(20),
 323 │                 ),
 324 │                 child: Text(
```

### 12.4 สั่งอาหาร

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:337](<flutter_application_1/lib/pages/booking_page.dart:337>)
- หน้าที่: FoodMenu พร้อม reservationId
- โค้ดช่วงบรรทัด 336–344:

```dart
 336 │               ),
 337 │             ],
 338 │           ),
 339 │           const SizedBox(height: 14),
 340 │           _action(
 341 │             context,
 342 │             Icons.restaurant_menu_outlined,
 343 │             'สั่งอาหาร',
 344 │             'เลือกอาหารสำหรับโต๊ะนี้',
```

### 12.5 ออร์เดอร์

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:353](<flutter_application_1/lib/pages/booking_page.dart:353>)
- หน้าที่: เปิด OrderHistoryPage
- โค้ดช่วงบรรทัด 352–360:

```dart
 352 │                     reservationTable:
 353 │                         tableNumber,
 354 │                   ),
 355 │                 ),
 356 │               );
 357 │             },
 358 │           ),
 359 │           const SizedBox(height: 10),
 360 │           _action(
```

### 12.6 ยกเลิก

- อยู่ที่: [flutter_application_1/lib/pages/booking_page.dart:109](<flutter_application_1/lib/pages/booking_page.dart:109>)
- หน้าที่: ยกเลิกแล้วหายจากหน้า active แต่ยังอยู่ประวัติ; server กันเมื่อมีออร์เดอร์หรือเริ่มใช้โต๊ะ
- โค้ดช่วงบรรทัด 109–116:

```dart
 109 │   Future<void> _cancelReservation(int reservationId) async {
 110 │     if (_cancellingIds.contains(reservationId)) return;
 111 │     setState(() => _cancellingIds.add(reservationId));
 112 │     try {
 113 │       await ApiService.cancelReservation(reservationId);
 114 │       if (!mounted) return;
 115 │       setState(() {
 116 │         reservations.removeWhere((item) => item.reservationId == reservationId);
```

## 13 ประวัติการจอง

### 13.1 เปิดจาก Profile

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:60](<flutter_application_1/lib/pages/reservation_history_page.dart:60>)
- หน้าที่: GET view=history ทุกสถานะ
- โค้ดช่วงบรรทัด 59–67:

```dart
  59 │         ),
  60 │         title: const Text(
  61 │           'ประวัติการจองโต๊ะ',
  62 │           style: TextStyle(
  63 │             fontSize: 20,
  64 │             fontWeight: FontWeight.w600,
  65 │           ),
  66 │         ),
  67 │       ),
```

### 13.2 เลขจอง/โต๊ะ

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:184](<flutter_application_1/lib/pages/reservation_history_page.dart:184>)
- หน้าที่: ระบุรายการและโต๊ะ
- โค้ดช่วงบรรทัด 184–191:

```dart
 184 │   Widget _reservationCard(
 185 │     BuildContext context,
 186 │     Reservation reservation,
 187 │   ) {
 188 │     return InkWell(
 189 │       onTap: () {
 190 │         Navigator.push(
 191 │           context,
```

### 13.3 วันที่กดจอง

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:267](<flutter_application_1/lib/pages/reservation_history_page.dart:267>)
- หน้าที่: bookingDate ต่างจากวันมา
- โค้ดช่วงบรรทัด 266–274:

```dart
 266 │               'วันและเวลาที่จอง',
 267 │               _dateTime(reservation.bookingDate),
 268 │             ),
 269 │             const SizedBox(height: 8),
 270 │             _detailRow(
 271 │               Icons.access_time_outlined,
 272 │               'วันที่เข้ารับบริการ',
 273 │               _dateOnly(reservation.diningDate),
 274 │             ),
```

### 13.4 วันมา

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:273](<flutter_application_1/lib/pages/reservation_history_page.dart:273>)
- หน้าที่: diningDate/diningTime
- โค้ดช่วงบรรทัด 272–280:

```dart
 272 │               'วันที่เข้ารับบริการ',
 273 │               _dateOnly(reservation.diningDate),
 274 │             ),
 275 │             const SizedBox(height: 8),
 276 │             _detailRow(Icons.access_time_outlined, 'เวลา', reservation.diningTime),
 277 │             const SizedBox(height: 8),
 278 │             _detailRow(
 279 │               Icons.people_outline,
 280 │               'จำนวนผู้จอง',
```

### 13.5 ป้ายสถานะ

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:327](<flutter_application_1/lib/pages/reservation_history_page.dart:327>)
- หน้าที่: map 1/2/3/4 ตาม DB
- โค้ดช่วงบรรทัด 327–334:

```dart
 327 │   Widget _statusBadge(int statusId) {
 328 │     String text;
 329 │
 330 │     switch (statusId) {
 331 │       case 1:
 332 │         text = 'ยืนยันแล้ว';
 333 │         break;
 334 │       case 2:
```

### 13.6 แตะการ์ด

- อยู่ที่: [flutter_application_1/lib/pages/reservation_history_page.dart:184](<flutter_application_1/lib/pages/reservation_history_page.dart:184>)
- หน้าที่: เปิด ReservationDetailPage
- โค้ดช่วงบรรทัด 184–191:

```dart
 184 │   Widget _reservationCard(
 185 │     BuildContext context,
 186 │     Reservation reservation,
 187 │   ) {
 188 │     return InkWell(
 189 │       onTap: () {
 190 │         Navigator.push(
 191 │           context,
```

## 14 รายละเอียดการจอง

### 14.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/reservation_detail_page.dart:40](<flutter_application_1/lib/pages/reservation_detail_page.dart:40>)
- หน้าที่: ยังเป็นภาษาอังกฤษบางส่วน
- โค้ดช่วงบรรทัด 39–47:

```dart
  39 │       appBar: AppBar(
  40 │         backgroundColor: AppColors.background,
  41 │         elevation: 0,
  42 │
  43 │         leading: IconButton(
  44 │           onPressed: () {
  45 │             Navigator.pop(context);
  46 │           },
  47 │           icon: const Icon(Icons.arrow_back),
```

### 14.2 ข้อมูล

- อยู่ที่: [flutter_application_1/lib/pages/reservation_detail_page.dart:26](<flutter_application_1/lib/pages/reservation_detail_page.dart:26>)
- หน้าที่: GET /reservations/:id ใหม่เมื่อเปิด
- โค้ดช่วงบรรทัด 25–32:

```dart
  25 │   void initState() {
  26 │     super.initState();
  27 │
  28 │     _reservationFuture =
  29 │         ApiService.getReservationById(
  30 │       widget.reservationId,
  31 │     );
  32 │   }
```

### 14.3 โต๊ะ/วันจอง

- อยู่ที่: [flutter_application_1/lib/pages/reservation_detail_page.dart:88](<flutter_application_1/lib/pages/reservation_detail_page.dart:88>)
- หน้าที่: ปัจจุบันแสดง tableId ไม่ใช่เลขโต๊ะ
- โค้ดช่วงบรรทัด 88–95:

```dart
  88 │   Widget _detailView(
  89 │     Reservation reservation,
  90 │   ) {
  91 │     return ListView(
  92 │       padding: const EdgeInsets.fromLTRB(
  93 │         20,
  94 │         10,
  95 │         20,
```

### 14.4 วันมา/เวลา/คน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_detail_page.dart:88](<flutter_application_1/lib/pages/reservation_detail_page.dart:88>)
- หน้าที่: มาจาก Reservation model
- โค้ดช่วงบรรทัด 88–95:

```dart
  88 │   Widget _detailView(
  89 │     Reservation reservation,
  90 │   ) {
  91 │     return ListView(
  92 │       padding: const EdgeInsets.fromLTRB(
  93 │         20,
  94 │         10,
  95 │         20,
```

### 14.5 สถานะ

- อยู่ที่: [flutter_application_1/lib/pages/reservation_detail_page.dart:253](<flutter_application_1/lib/pages/reservation_detail_page.dart:253>)
- หน้าที่: mapping ของหน้านี้ผิดจาก DB; ระบุเป็น bug
- โค้ดช่วงบรรทัด 253–259:

```dart
 253 │   Widget _statusBadge(int statusId) {
 254 │     String text;
 255 │
 256 │     switch (statusId) {
 257 │       case 1:
 258 │         text = 'Pending';
 259 │         break;
```

## 15 ประวัติออร์เดอร์

### 15.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/order_history_page.dart:313](<flutter_application_1/lib/pages/order_history_page.dart:313>)
- หน้าที่: โหลด order ของผู้ใช้
- โค้ดช่วงบรรทัด 312–320:

```dart
 312 │   @override
 313 │   Widget build(BuildContext context) => Scaffold(
 314 │         backgroundColor: AppColors.background,
 315 │         appBar: AppBar(title: const Text('ประวัติการสั่งอาหาร')),
 316 │         body: FutureBuilder<List<Map<String, dynamic>>>(
 317 │           future: future,
 318 │           builder: (context, snapshot) {
 319 │             if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
 320 │             if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
```

### 15.2 การ์ด

- อยู่ที่: [flutter_application_1/lib/pages/order_history_page.dart:357](<flutter_application_1/lib/pages/order_history_page.dart:357>)
- หน้าที่: เลขออร์เดอร์ ยอด วัน และสถานะ
- โค้ดช่วงบรรทัด 357–364:

```dart
 357 │   Widget _orderCard(Map<String, dynamic> row) {
 358 │     final status = row['order_status']?.toString() ?? 'รอรับออร์เดอร์';
 359 │     final orderId = int.parse(row['order_id'].toString());
 360 │     final payable = status == 'รอชำระเงิน' || status == 'ชำระเงินไม่ผ่าน';
 361 │     final editable = status == 'รอรับออร์เดอร์';
 362 │     return Card(
 363 │       child: ListTile(
 364 │         title: Text('ออร์เดอร์ #$orderId • ฿${row['total'] ?? 0}'),
```

### 15.3 สถานะ

- อยู่ที่: [flutter_application_1/lib/pages/order_history_page.dart:323](<flutter_application_1/lib/pages/order_history_page.dart:323>)
- หน้าที่: แยกกำลังทำกับขั้นชำระ
- โค้ดช่วงบรรทัด 322–330:

```dart
 322 │             if (rows.isEmpty) return const Center(child: Text('ยังไม่มีประวัติการสั่งอาหาร'));
 323 │             final inProgress = rows.where((row) => ['รอรับออร์เดอร์', 'กำลังทำ'].contains(row['order_status'])).toList();
 324 │             final completed = rows.where((row) => ['รอชำระเงิน', 'รอตรวจสอบการชำระ', 'ชำระเงินไม่ผ่าน', 'ชำระแล้ว'].contains(row['order_status'])).toList();
 325 │             return RefreshIndicator(
 326 │               onRefresh: _refresh,
 327 │               child: ListView(
 328 │                 padding: const EdgeInsets.all(12),
 329 │                 children: [
 330 │                   if (inProgress.isNotEmpty) ...[
```

### 15.4 ปุ่ม QR/เมนู

- อยู่ที่: [flutter_application_1/lib/pages/order_history_page.dart:370](<flutter_application_1/lib/pages/order_history_page.dart:370>)
- หน้าที่: เปิด QR หรือแก้/ยกเลิกตามสถานะ
- โค้ดช่วงบรรทัด 369–377:

```dart
 369 │             IconButton(
 370 │               tooltip: 'ชำระเงิน',
 371 │               icon: const Icon(Icons.qr_code_2, color: AppColors.orange),
 372 │               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentQrPage(orderId: orderId))).then((_) => _refresh()),
 373 │             ),
 374 │           if (editable)
 375 │             PopupMenuButton<String>(
 376 │               tooltip: 'จัดการออร์เดอร์',
 377 │               onSelected: (action) {
```

## 16 QR ชำระเงินและส่งสลิป

### 16.1 ออร์เดอร์

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:57](<flutter_application_1/lib/pages/payment_qr_page.dart:57>)
- หน้าที่: รับ orderId จากประวัติ
- โค้ดช่วงบรรทัด 56–64:

```dart
  56 │     return Scaffold(
  57 │       backgroundColor: AppColors.background,
  58 │       appBar: AppBar(title: Text('ชำระออร์เดอร์ #${widget.orderId}')),
  59 │       body: FutureBuilder<Map<String, dynamic>>(
  60 │         future: qrFuture,
  61 │         builder: (context, snapshot) {
  62 │           if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
  63 │           if (snapshot.hasError) {
  64 │             final message = snapshot.error.toString().replaceFirst('Exception: ', '');
```

### 16.2 ยอดจริง

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:116](<flutter_application_1/lib/pages/payment_qr_page.dart:116>)
- หน้าที่: amount จาก backend
- โค้ดช่วงบรรทัด 115–123:

```dart
 115 │             Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
 116 │               Text('ยอดชำระ ฿${double.parse(data['amount'].toString()).toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
 117 │               const SizedBox(height: 14),
 118 │               QrImageView(data: data['qr_payload'].toString(), size: 230, backgroundColor: Colors.white),
 119 │               const Text('สแกนด้วยแอปธนาคารเพื่อโอนผ่าน PromptPay', textAlign: TextAlign.center),
 120 │               if (data['promptpay_id']?.toString().isNotEmpty == true) ...[
 121 │                 const SizedBox(height: 14),
 122 │                 Container(
 123 │                   width: double.infinity,
```

### 16.3 QR

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:118](<flutter_application_1/lib/pages/payment_qr_page.dart:118>)
- หน้าที่: QrImageView จาก PromptPay payload
- โค้ดช่วงบรรทัด 117–125:

```dart
 117 │               const SizedBox(height: 14),
 118 │               QrImageView(data: data['qr_payload'].toString(), size: 230, backgroundColor: Colors.white),
 119 │               const Text('สแกนด้วยแอปธนาคารเพื่อโอนผ่าน PromptPay', textAlign: TextAlign.center),
 120 │               if (data['promptpay_id']?.toString().isNotEmpty == true) ...[
 121 │                 const SizedBox(height: 14),
 122 │                 Container(
 123 │                   width: double.infinity,
 124 │                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
 125 │                   decoration: BoxDecoration(
```

### 16.4 รายการอาหาร

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:120](<flutter_application_1/lib/pages/payment_qr_page.dart:120>)
- หน้าที่: แสดงเลข PromptPay หรือบัญชีที่แอดมินกำหนดใต้ QR
- โค้ดช่วงบรรทัด 119–127:

```dart
 119 │               const Text('สแกนด้วยแอปธนาคารเพื่อโอนผ่าน PromptPay', textAlign: TextAlign.center),
 120 │               if (data['promptpay_id']?.toString().isNotEmpty == true) ...[
 121 │                 const SizedBox(height: 14),
 122 │                 Container(
 123 │                   width: double.infinity,
 124 │                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
 125 │                   decoration: BoxDecoration(
 126 │                     color: Colors.white,
 127 │                     borderRadius: BorderRadius.circular(12),
```

### 16.5 แนบสลิป

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:144](<flutter_application_1/lib/pages/payment_qr_page.dart:144>)
- หน้าที่: รายการอาหารและเครื่องดื่มพร้อมยอดจาก backend
- โค้ดช่วงบรรทัด 143–151:

```dart
 143 │             Card(child: Column(children: [
 144 │               const ListTile(title: Text('รายการอาหาร', style: TextStyle(fontWeight: FontWeight.bold))),
 145 │               ...items.map((item) => ListTile(title: Text('${item['menu_name']} × ${item['quantity']}'), trailing: Text('฿${(double.parse(item['price'].toString()) * int.parse(item['quantity'].toString())).toStringAsFixed(2)}'))),
 146 │             ])),
 147 │             if (payment != null)
 148 │               Padding(padding: const EdgeInsets.all(12), child: Text('สถานะ: ${payment!['payment_status_name']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
 149 │             const SizedBox(height: 12),
 150 │             FilledButton.icon(
 151 │               onPressed: sending || payment?['payment_status_id'].toString() == '3' || payment?['payment_status_id'].toString() == '1' ? null : _sendSlip,
```

### 16.6 แนบสลิป

- อยู่ที่: [flutter_application_1/lib/pages/payment_qr_page.dart:35](<flutter_application_1/lib/pages/payment_qr_page.dart:35>)
- หน้าที่: เลือกรูปและส่งให้แอดมินตรวจ; QR ไม่ยืนยันว่าจ่ายแล้ว
- โค้ดช่วงบรรทัด 35–42:

```dart
  35 │   Future<void> _sendSlip() async {
  36 │     final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
  37 │     if (image == null) return;
  38 │     setState(() => sending = true);
  39 │     try {
  40 │       final bytes = await image.readAsBytes();
  41 │       final mime = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
  42 │       final payload = 'data:image/$mime;base64,${base64Encode(bytes)}';
```

## 17 โปรไฟล์ Profile

### 17.1 หัวข้อ

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:38](<flutter_application_1/lib/pages/profile_page.dart:38>)
- หน้าที่: หน้าแท็บลูกค้า
- โค้ดช่วงบรรทัด 37–45:

```dart
  37 │       return Scaffold(
  38 │       backgroundColor: AppColors.background,
  39 │       body: SafeArea(
  40 │         child: ListView(
  41 │           padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
  42 │           children: [
  43 │             const Text(
  44 │               'โปรไฟล์',
  45 │               style: TextStyle(
```

### 17.2 ภาพและชื่อ

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:47](<flutter_application_1/lib/pages/profile_page.dart:47>)
- หน้าที่: ฟัง CurrentUserService; เปลี่ยนรูปที่ข้อมูลส่วนตัว
- โค้ดช่วงบรรทัด 46–54:

```dart
  46 │                 fontSize: 27,
  47 │                 fontWeight: FontWeight.w600,
  48 │               ),
  49 │             ),
  50 │
  51 │             const SizedBox(height: 20),
  52 │
  53 │             Container(
  54 │               padding: const EdgeInsets.all(20),
```

### 17.3 ข้อมูลส่วนตัว

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:124](<flutter_application_1/lib/pages/profile_page.dart:124>)
- หน้าที่: เปิดฟอร์มแก้ข้อมูล/รูป
- โค้ดช่วงบรรทัด 123–131:

```dart
 123 │               Icons.person_outline,
 124 │               'ข้อมูลส่วนตัว',
 125 │               onTap: () {
 126 │                 Navigator.push(
 127 │                   context,
 128 │                   MaterialPageRoute(
 129 │                     builder: (_) =>
 130 │                         const PersonalInformationPage(),
 131 │                   ),
```

### 17.4 หน้าประวัติ

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:138](<flutter_application_1/lib/pages/profile_page.dart:138>)
- หน้าที่: ลิงก์ History/Inbox/OrderHistory
- โค้ดช่วงบรรทัด 137–145:

```dart
 137 │               Icons.history,
 138 │               'ประวัติการจอง',
 139 │               onTap: () {
 140 │                 Navigator.push(
 141 │                   context,
 142 │                   MaterialPageRoute(
 143 │                     builder: (_) =>
 144 │                         const ReservationHistoryPage(),
 145 │                   ),
```

### 17.5 สวิตช์

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:236](<flutter_application_1/lib/pages/profile_page.dart:236>)
- หน้าที่: GET/PATCH notification preference
- โค้ดช่วงบรรทัด 236–242:

```dart
 236 │ class _NotificationPreferenceControl extends StatefulWidget {
 237 │   const _NotificationPreferenceControl();
 238 │
 239 │   @override
 240 │   State<_NotificationPreferenceControl> createState() =>
 241 │       _NotificationPreferenceControlState();
 242 │ }
```

### 17.6 ออก

- อยู่ที่: [flutter_application_1/lib/pages/profile_page.dart:173](<flutter_application_1/lib/pages/profile_page.dart:173>)
- หน้าที่: ล้าง user และ navigation stack
- โค้ดช่วงบรรทัด 172–180:

```dart
 172 │             SecondaryButton(
 173 │               text: 'ออกจากระบบ',
 174 │               onPressed: () {
 175 │                 CurrentUserService.instance.clearUser();
 176 │
 177 │                 Navigator.pushAndRemoveUntil(
 178 │                   context,
 179 │                   MaterialPageRoute(
 180 │                     builder: (_) => const WelcomePage(),
```

## 18 แก้ข้อมูลส่วนตัว

### 18.1 หัวข้อ

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:188](<flutter_application_1/lib/pages/personal_information_page.dart:188>)
- หน้าที่: รับ user ปัจจุบัน
- โค้ดช่วงบรรทัด 188–195:

```dart
 188 │         title: const Text(
 189 │           'ข้อมูลส่วนตัว',
 190 │           style: TextStyle(
 191 │             fontSize: 20,
 192 │             fontWeight: FontWeight.w600,
 193 │           ),
 194 │         ),
 195 │       ),
```

### 18.2 รูปและดินสอ

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:60](<flutter_application_1/lib/pages/personal_information_page.dart:60>)
- หน้าที่: gallery จำกัด 3MB แล้ว PUT image
- โค้ดช่วงบรรทัด 60–67:

```dart
  60 │   Future<void> _changeProfileImage() async {
  61 │     try {
  62 │       final image = await ImagePicker().pickImage(
  63 │         source: ImageSource.gallery,
  64 │         imageQuality: 82,
  65 │         maxWidth: 1200,
  66 │       );
  67 │       if (image == null || !mounted) return;
```

### 18.3 ชื่อ

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:288](<flutter_application_1/lib/pages/personal_information_page.dart:288>)
- หน้าที่: ห้ามว่าง
- โค้ดช่วงบรรทัด 288–295:

```dart
 288 │                   _textField(
 289 │                     controller: _fullnameController,
 290 │                     icon: Icons.badge_outlined,
 291 │                     label: 'ชื่อ-นามสกุล',
 292 │                     validator: (value) {
 293 │                       if (value == null ||
 294 │                           value.trim().isEmpty) {
 295 │                         return 'กรุณากรอกชื่อ';
```

### 18.4 username

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:305](<flutter_application_1/lib/pages/personal_information_page.dart:305>)
- หน้าที่: 3–50 ตัว อักษร/เลข/._-
- โค้ดช่วงบรรทัด 304–312:

```dart
 304 │                   _textField(
 305 │                     controller: _usernameController,
 306 │                     icon: Icons.person_outline,
 307 │                     label: 'ชื่อผู้ใช้',
 308 │                     validator: (value) {
 309 │                       final username = value?.trim() ?? '';
 310 │                       if (!RegExp(r'^[A-Za-z0-9_.-]{3,50}$').hasMatch(username)) return 'ใช้ a-z, 0-9, _, ., - ความยาว 3–50 ตัว';
 311 │                       return null;
 312 │                     },
```

### 18.5 ติดต่อ

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:318](<flutter_application_1/lib/pages/personal_information_page.dart:318>)
- หน้าที่: ฟอร์มส่ง backend
- โค้ดช่วงบรรทัด 317–324:

```dart
 317 │                   _textField(
 318 │                     controller: _phoneController,
 319 │                     icon: Icons.phone_outlined,
 320 │                     label: 'เบอร์โทรศัพท์',
 321 │                     keyboardType: TextInputType.phone,
 322 │                   ),
 323 │
 324 │                   const SizedBox(height: 12),
```

### 18.6 บันทึก

- อยู่ที่: [flutter_application_1/lib/pages/personal_information_page.dart:340](<flutter_application_1/lib/pages/personal_information_page.dart:340>)
- หน้าที่: อัปเดต CurrentUserService
- โค้ดช่วงบรรทัด 339–347:

```dart
 339 │                     child: ElevatedButton(
 340 │                       onPressed: _isSaving ? null : _save,
 341 │
 342 │                       style: ElevatedButton.styleFrom(
 343 │                         backgroundColor: AppColors.orange,
 344 │                         foregroundColor: Colors.white,
 345 │
 346 │                         shape: RoundedRectangleBorder(
 347 │                           borderRadius:
```

## 19 กล่องการแจ้งเตือน

### 19.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/notification_inbox_page.dart:29](<flutter_application_1/lib/pages/notification_inbox_page.dart:29>)
- หน้าที่: GET ประวัติแจ้งเตือน
- โค้ดช่วงบรรทัด 28–36:

```dart
  28 │   @override
  29 │   Widget build(BuildContext context) => Scaffold(
  30 │     backgroundColor: AppColors.background,
  31 │     appBar: AppBar(title: const Text('การแจ้งเตือน')),
  32 │     body: FutureBuilder<List<Map<String, dynamic>>>(
  33 │       future: future,
  34 │       builder: (context, snapshot) {
  35 │         if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
  36 │         if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
```

### 19.2 กระดิ่ง

- อยู่ที่: [flutter_application_1/lib/pages/notification_inbox_page.dart:54](<flutter_application_1/lib/pages/notification_inbox_page.dart:54>)
- หน้าที่: สีส้ม/เทาตามค่า ณ เวลาส่ง; IgnorePointer กดไม่ได้
- โค้ดช่วงบรรทัด 53–61:

```dart
  53 │                       padding: const EdgeInsets.only(top: 2),
  54 │                       child: IgnorePointer(
  55 │                         child: Icon(
  56 │                           enabledWhenSent ? Icons.notifications_active : Icons.notifications_none,
  57 │                           color: enabledWhenSent ? AppColors.orange : AppColors.grey,
  58 │                         ),
  59 │                       ),
  60 │                     ),
  61 │                   ),
```

### 19.3 หัวข้อ/รายละเอียด

- อยู่ที่: [flutter_application_1/lib/pages/notification_inbox_page.dart:64](<flutter_application_1/lib/pages/notification_inbox_page.dart:64>)
- หน้าที่: ข้อความที่ร้านส่ง
- โค้ดช่วงบรรทัด 63–71:

```dart
  63 │                   Expanded(
  64 │                     child: Column(
  65 │                       crossAxisAlignment: CrossAxisAlignment.start,
  66 │                       children: [
  67 │                         Text('${row['title'] ?? 'แจ้งเตือน'}'),
  68 │                         Text('${row['body'] ?? row['message'] ?? ''}'),
  69 │                         Text(
  70 │                           '${row['sent_at'] ?? row['created_at'] ?? ''}',
  71 │                           style: const TextStyle(color: AppColors.grey, fontSize: 12),
```

### 19.4 เวลา

- อยู่ที่: [flutter_application_1/lib/pages/notification_inbox_page.dart:74](<flutter_application_1/lib/pages/notification_inbox_page.dart:74>)
- หน้าที่: sent_at หรือ created_at
- โค้ดช่วงบรรทัด 73–81:

```dart
  73 │                       ],
  74 │                     ),
  75 │                   ),
  76 │                 ],
  77 │               ),
  78 │             );
  79 │           },
  80 │         ));
  81 │       },
```

## 20 สถิติเมนูยอดนิยม

### 20.1 ชื่อหน้า

- อยู่ที่: [flutter_application_1/lib/pages/restaurant_stats_page.dart:24](<flutter_application_1/lib/pages/restaurant_stats_page.dart:24>)
- หน้าที่: month=YYYY-MM ปัจจุบัน
- โค้ดช่วงบรรทัด 23–31:

```dart
  23 │     backgroundColor: AppColors.background,
  24 │     appBar: AppBar(title: const Text('เมนูยอดนิยมประจำเดือน')),
  25 │     body: FutureBuilder<List<Map<String, dynamic>>>(
  26 │       future: future,
  27 │       builder: (context, snapshot) {
  28 │         if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
  29 │         if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
  30 │         final rows = snapshot.data!;
  31 │         if (rows.isEmpty) return const Center(child: Text('เดือนนี้ยังไม่มีออร์เดอร์ที่ชำระเงินแล้ว'));
```

### 20.2 อันดับ

- อยู่ที่: [flutter_application_1/lib/pages/restaurant_stats_page.dart:40](<flutter_application_1/lib/pages/restaurant_stats_page.dart:40>)
- หน้าที่: CircleAvatar 1,2,3...
- โค้ดช่วงบรรทัด 39–47:

```dart
  39 │               leading: CircleAvatar(backgroundColor: AppColors.orangeLight, child: Text('${index + 1}')),
  40 │               title: Text('${row['menu_name'] ?? row['name'] ?? 'เมนู'}'),
  41 │               subtitle: Text('จำนวน ${row['plates'] ?? row['quantity'] ?? row['total_quantity'] ?? 0} จาน'),
  42 │               trailing: Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
  43 │             ));
  44 │           },
  45 │         );
  46 │       },
  47 │     ),
```

### 20.3 จำนวนจาน

- อยู่ที่: [flutter_application_1/lib/pages/restaurant_stats_page.dart:41](<flutter_application_1/lib/pages/restaurant_stats_page.dart:41>)
- หน้าที่: plates จาก API
- โค้ดช่วงบรรทัด 40–48:

```dart
  40 │               title: Text('${row['menu_name'] ?? row['name'] ?? 'เมนู'}'),
  41 │               subtitle: Text('จำนวน ${row['plates'] ?? row['quantity'] ?? row['total_quantity'] ?? 0} จาน'),
  42 │               trailing: Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
  43 │             ));
  44 │           },
  45 │         );
  46 │       },
  47 │     ),
  48 │   );
```

### 20.4 เปอร์เซ็นต์

- อยู่ที่: [flutter_application_1/lib/pages/restaurant_stats_page.dart:42](<flutter_application_1/lib/pages/restaurant_stats_page.dart:42>)
- หน้าที่: ส่วนแบ่งยอดเมนู
- โค้ดช่วงบรรทัด 41–49:

```dart
  41 │               subtitle: Text('จำนวน ${row['plates'] ?? row['quantity'] ?? row['total_quantity'] ?? 0} จาน'),
  42 │               trailing: Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
  43 │             ));
  44 │           },
  45 │         );
  46 │       },
  47 │     ),
  48 │   );
  49 │ }
```

### 20.5 แหล่งข้อมูล

- อยู่ที่: [my_app/server.js:2112](<my_app/server.js:2112>)
- หน้าที่: นับ order ที่ชำระแล้ว
- โค้ดช่วงบรรทัด 2112–2119:

```javascript
2112 │ app.get('/api/stats/popular', requireAuth, async (req, res) => {
2113 │     try {
2114 │         const month = String(req.query.month || '');
2115 │         if (!/^\d{4}-\d{2}$/.test(month)) return res.status(400).json({ isError: true, message: 'ระบุเดือนในรูปแบบ YYYY-MM' });
2116 │         const [rows] = await pool.query(
2117 │             `SELECT m.menu_id, m.menu_name, SUM(od.quantity) AS plates,
2118 │                     ROUND(100 * SUM(od.quantity) / NULLIF((SELECT SUM(od2.quantity)
2119 │                       FROM order_detail od2 JOIN \`order\` o2 ON o2.order_id = od2.order_id
```

## 21 แอดมิน: ภาพรวม

### 21.1 ชื่อแท็บ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:515](<flutter_application_1/lib/pages/admin_dashboard_page.dart:515>)
- หน้าที่: index 0 ภาพรวม
- โค้ดช่วงบรรทัด 514–522:

```dart
 514 │       actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('บันทึก'))],
 515 │     )));
 516 │     if (saved == true) {
 517 │       try {
 518 │         final body = {'table_number': int.tryParse(number.text) ?? 0, 'capacity': int.tryParse(capacity.text) ?? 0, 'statustable_id': status};
 519 │         if (table == null) { await ApiService.adminPost('/admin/tables', body); }
 520 │         else { await ApiService.adminPut('/admin/tables/${table['table_id']}', body); }
 521 │         await _load(showLoading: false);
 522 │       } catch (e) { _show(e.toString()); }
```

### 21.2 ยอดขายเดือน

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:536](<flutter_application_1/lib/pages/admin_dashboard_page.dart:536>)
- หน้าที่: ยอด payment ที่อนุมัติ
- โค้ดช่วงบรรทัด 535–543:

```dart
 535 │     final titles = ['ภาพรวม', 'การจอง', 'ครัว', 'ชำระเงิน', 'จัดการร้าน'];
 536 │     final pages = [_dashboard(), _reservations(), _kitchen(), _payments(), _management()];
 537 │     return Scaffold(
 538 │       backgroundColor: AppColors.background,
 539 │       appBar: AppBar(title: Text(titles[index]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () { CurrentUserService.instance.clearUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false); }, icon: const Icon(Icons.logout))]),
 540 │       body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: pages[index]),
 541 │       bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
 542 │         NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
 543 │         NavigationDestination(icon: Icon(Icons.event_note), label: 'จอง'),
```

### 21.3 จองวันนี้

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:537](<flutter_application_1/lib/pages/admin_dashboard_page.dart:537>)
- หน้าที่: query ปัจจุบันนับทุกสถานะ
- โค้ดช่วงบรรทัด 536–544:

```dart
 536 │     final pages = [_dashboard(), _reservations(), _kitchen(), _payments(), _management()];
 537 │     return Scaffold(
 538 │       backgroundColor: AppColors.background,
 539 │       appBar: AppBar(title: Text(titles[index]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () { CurrentUserService.instance.clearUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false); }, icon: const Icon(Icons.logout))]),
 540 │       body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: pages[index]),
 541 │       bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
 542 │         NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
 543 │         NavigationDestination(icon: Icon(Icons.event_note), label: 'จอง'),
 544 │         NavigationDestination(icon: Icon(Icons.soup_kitchen_outlined), label: 'ครัว'),
```

### 21.4 กราฟ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:1041](<flutter_application_1/lib/pages/admin_dashboard_page.dart:1041>)
- หน้าที่: CustomPainter จาก daily_sales
- โค้ดช่วงบรรทัด 1040–1048:

```dart
1040 │                   } catch (e) {
1041 │                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ปิดรอบโต๊ะไม่สำเร็จ: $e')));
1042 │                   }
1043 │                 },
1044 │               ),
1045 │               IconButton(tooltip: 'แก้ไขโต๊ะ', visualDensity: VisualDensity.compact, icon: const Icon(Icons.edit_outlined), onPressed: () => _editTable(row)),
1046 │             ]),
1047 │           ]),
1048 │         );
```

### 21.5 เมนูยอดนิยม

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:543](<flutter_application_1/lib/pages/admin_dashboard_page.dart:543>)
- หน้าที่: จำนวนจาน ยอดต่อเมนู เปอร์เซ็นต์
- โค้ดช่วงบรรทัด 542–549:

```dart
 542 │         NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
 543 │         NavigationDestination(icon: Icon(Icons.event_note), label: 'จอง'),
 544 │         NavigationDestination(icon: Icon(Icons.soup_kitchen_outlined), label: 'ครัว'),
 545 │         NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'ชำระ'),
 546 │         NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'จัดการ'),
 547 │       ]),
 548 │     );
 549 │   }
```

### 21.6 แถบ 5 แท็บ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:522](<flutter_application_1/lib/pages/admin_dashboard_page.dart:522>)
- หน้าที่: ภาพรวม/จอง/ครัว/ชำระ/จัดการ
- โค้ดช่วงบรรทัด 521–529:

```dart
 521 │         await _load(showLoading: false);
 522 │       } catch (e) { _show(e.toString()); }
 523 │     }
 524 │     number.dispose();
 525 │     capacity.dispose();
 526 │   }
 527 │
 528 │   void _show(String message) {
 529 │     if (!mounted) return;
```

## 22 แอดมิน: การจอง

### 22.1 ชื่อ/รีเฟรช

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:534](<flutter_application_1/lib/pages/admin_dashboard_page.dart:534>)
- หน้าที่: โหลดข้อมูลใหม่ทุกกลุ่ม
- โค้ดช่วงบรรทัด 533–541:

```dart
 533 │   @override
 534 │   Widget build(BuildContext context) {
 535 │     final titles = ['ภาพรวม', 'การจอง', 'ครัว', 'ชำระเงิน', 'จัดการร้าน'];
 536 │     final pages = [_dashboard(), _reservations(), _kitchen(), _payments(), _management()];
 537 │     return Scaffold(
 538 │       backgroundColor: AppColors.background,
 539 │       appBar: AppBar(title: Text(titles[index]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () { CurrentUserService.instance.clearUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false); }, icon: const Icon(Icons.logout))]),
 540 │       body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: pages[index]),
 541 │       bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
```

### 22.2 หัวข้อวัน

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:587](<flutter_application_1/lib/pages/admin_dashboard_page.dart:587>)
- หน้าที่: group ตาม dining_date ใหม่ก่อน
- โค้ดช่วงบรรทัด 587–594:

```dart
 587 │   List<Widget> _dateSections({
 588 │     required List<Map<String, dynamic>> rows,
 589 │     required String dateField,
 590 │     required String emptyMessage,
 591 │     required Widget Function(Map<String, dynamic>) rowBuilder,
 592 │   }) {
 593 │     if (rows.isEmpty) return [Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.grey)))))];
 594 │     final groups = <String, List<Map<String, dynamic>>>{};
```

### 22.3 การ์ด

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:569](<flutter_application_1/lib/pages/admin_dashboard_page.dart:569>)
- หน้าที่: ชื่อและเลขโต๊ะ
- โค้ดช่วงบรรทัด 569–576:

```dart
 569 │   Widget _reservations() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
 570 │     rows: reservations,
 571 │     dateField: 'dining_date',
 572 │     emptyMessage: 'ยังไม่มีรายการจอง',
 573 │     rowBuilder: (row) => Card(child: ListTile(
 574 │       title: Text('${row['fullname']} • โต๊ะ ${row['table_number']}'),
 575 │       subtitle: Padding(
 576 │         padding: const EdgeInsets.only(top: 6),
```

### 22.4 เวลา/คน/โทร

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:619](<flutter_application_1/lib/pages/admin_dashboard_page.dart:619>)
- หน้าที่: time badge ชัดเจน
- โค้ดช่วงบรรทัด 619–626:

```dart
 619 │   Widget _timeBadge(String value) {
 620 │     final display = RegExp(r'\d{2}:\d{2}').firstMatch(value)?.group(0) ?? '';
 621 │     return Container(
 622 │       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
 623 │       decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(8)),
 624 │       child: Row(mainAxisSize: MainAxisSize.min, children: [
 625 │         const Icon(Icons.schedule, size: 14, color: AppColors.orange),
 626 │         const SizedBox(width: 5),
```

### 22.5 Dropdown

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:106](<flutter_application_1/lib/pages/admin_dashboard_page.dart:106>)
- หน้าที่: PATCH สถานะจอง 1–4
- โค้ดช่วงบรรทัด 106–113:

```dart
 106 │   Future<void> _changeReservation(Map<String, dynamic> row, int status) async {
 107 │     final id = int.tryParse(row['reservation_id'].toString());
 108 │     if (id == null || !_savingReservationStatuses.add(id)) return;
 109 │     setState(() {
 110 │       for (final reservation in reservations) {
 111 │         if (int.tryParse(reservation['reservation_id'].toString()) == id) {
 112 │           reservation['statusreservation_id'] = status;
 113 │         }
```

### 22.6 NavigationBar

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:540](<flutter_application_1/lib/pages/admin_dashboard_page.dart:540>)
- หน้าที่: เลือก index ของหลังบ้าน
- โค้ดช่วงบรรทัด 539–547:

```dart
 539 │       appBar: AppBar(title: Text(titles[index]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () { CurrentUserService.instance.clearUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false); }, icon: const Icon(Icons.logout))]),
 540 │       body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: pages[index]),
 541 │       bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
 542 │         NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
 543 │         NavigationDestination(icon: Icon(Icons.event_note), label: 'จอง'),
 544 │         NavigationDestination(icon: Icon(Icons.soup_kitchen_outlined), label: 'ครัว'),
 545 │         NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'ชำระ'),
 546 │         NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'จัดการ'),
 547 │       ]),
```

## 23 แอดมิน: ครัว

### 23.1 ชื่อแท็บ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:659](<flutter_application_1/lib/pages/admin_dashboard_page.dart:659>)
- หน้าที่: ข้อมูล order detail รายจาน
- โค้ดช่วงบรรทัด 659–666:

```dart
 659 │   Widget _kitchen() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
 660 │     rows: orderItems,
 661 │     dateField: 'order_date',
 662 │     emptyMessage: 'ยังไม่มีรายการอาหารในครัว',
 663 │     rowBuilder: (row) => Card(child: ListTile(
 664 │       title: Text('#${row['order_id']} • ${row['menu_name']} × ${row['quantity']}'),
 665 │       subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
 666 │         _timeBadge(row['order_date']?.toString() ?? ''),
```

### 23.2 หัวข้อวัน

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:587](<flutter_application_1/lib/pages/admin_dashboard_page.dart:587>)
- หน้าที่: group ตาม order_date
- โค้ดช่วงบรรทัด 587–594:

```dart
 587 │   List<Widget> _dateSections({
 588 │     required List<Map<String, dynamic>> rows,
 589 │     required String dateField,
 590 │     required String emptyMessage,
 591 │     required Widget Function(Map<String, dynamic>) rowBuilder,
 592 │   }) {
 593 │     if (rows.isEmpty) return [Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.grey)))))];
 594 │     final groups = <String, List<Map<String, dynamic>>>{};
```

### 23.3 Order และเมนู

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:659](<flutter_application_1/lib/pages/admin_dashboard_page.dart:659>)
- หน้าที่: จำนวนต่อจาน
- โค้ดช่วงบรรทัด 659–666:

```dart
 659 │   Widget _kitchen() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
 660 │     rows: orderItems,
 661 │     dateField: 'order_date',
 662 │     emptyMessage: 'ยังไม่มีรายการอาหารในครัว',
 663 │     rowBuilder: (row) => Card(child: ListTile(
 664 │       title: Text('#${row['order_id']} • ${row['menu_name']} × ${row['quantity']}'),
 665 │       subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
 666 │         _timeBadge(row['order_date']?.toString() ?? ''),
```

### 23.4 ข้อมูลครัว

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:659](<flutter_application_1/lib/pages/admin_dashboard_page.dart:659>)
- หน้าที่: decode selected_options JSON
- โค้ดช่วงบรรทัด 659–666:

```dart
 659 │   Widget _kitchen() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
 660 │     rows: orderItems,
 661 │     dateField: 'order_date',
 662 │     emptyMessage: 'ยังไม่มีรายการอาหารในครัว',
 663 │     rowBuilder: (row) => Card(child: ListTile(
 664 │       title: Text('#${row['order_id']} • ${row['menu_name']} × ${row['quantity']}'),
 665 │       subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
 666 │         _timeBadge(row['order_date']?.toString() ?? ''),
```

### 23.5 รับรายการ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:151](<flutter_application_1/lib/pages/admin_dashboard_page.dart:151>)
- หน้าที่: PATCH accept เมื่อรอทำ
- โค้ดช่วงบรรทัด 151–158:

```dart
 151 │   Future<void> _acceptOrder(Map<String, dynamic> row) async {
 152 │     final id = int.tryParse(row['orderdetail_id'].toString());
 153 │     if (id == null || !_savingOrderItemStatuses.add(id)) return;
 154 │     setState(() {
 155 │       row['food_status'] = 'กำลังทำ';
 156 │       row['order_status'] = 'กำลังทำ';
 157 │     });
 158 │     try {
```

### 23.6 เปลี่ยนสถานะ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:128](<flutter_application_1/lib/pages/admin_dashboard_page.dart:128>)
- หน้าที่: PATCH food_status
- โค้ดช่วงบรรทัด 128–135:

```dart
 128 │   Future<void> _changeFoodStatus(Map<String, dynamic> row, String status) async {
 129 │     final id = int.tryParse(row['orderdetail_id'].toString());
 130 │     if (id == null || !_savingOrderItemStatuses.add(id)) return;
 131 │     setState(() {
 132 │       for (final item in orderItems) {
 133 │         if (int.tryParse(item['orderdetail_id'].toString()) == id) {
 134 │           item['food_status'] = status;
 135 │           if (status != 'รอทำ') item['order_status'] = 'กำลังทำ';
```

## 24 แอดมิน: ตรวจชำระเงิน

### 24.1 ชื่อแท็บ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:685](<flutter_application_1/lib/pages/admin_dashboard_page.dart:685>)
- หน้าที่: เฉพาะแอดมิน
- โค้ดช่วงบรรทัด 685–692:

```dart
 685 │   Widget _payments() => ListView(padding: const EdgeInsets.all(12), children: [
 686 │     const Card(child: Padding(
 687 │       padding: EdgeInsets.all(14),
 688 │       child: Text('หน้านี้แสดงสลิปที่ลูกค้าส่งมา หลังสแกน QR PromptPay และโอนเงินแล้ว ตรวจสอบยอดกับสลิปก่อนกดยืนยัน ระบบจะบันทึกยอดขายเมื่อยืนยันการชำระเงิน'),
 689 │     )),
 690 │     if (payments.isEmpty)
 691 │       Card(child: Padding(
 692 │         padding: const EdgeInsets.all(24),
```

### 24.2 คำแนะนำ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:685](<flutter_application_1/lib/pages/admin_dashboard_page.dart:685>)
- หน้าที่: โอนจริงต้องตรวจด้วยคน
- โค้ดช่วงบรรทัด 685–692:

```dart
 685 │   Widget _payments() => ListView(padding: const EdgeInsets.all(12), children: [
 686 │     const Card(child: Padding(
 687 │       padding: EdgeInsets.all(14),
 688 │       child: Text('หน้านี้แสดงสลิปที่ลูกค้าส่งมา หลังสแกน QR PromptPay และโอนเงินแล้ว ตรวจสอบยอดกับสลิปก่อนกดยืนยัน ระบบจะบันทึกยอดขายเมื่อยืนยันการชำระเงิน'),
 689 │     )),
 690 │     if (payments.isEmpty)
 691 │       Card(child: Padding(
 692 │         padding: const EdgeInsets.all(24),
```

### 24.3 payment card

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:696](<flutter_application_1/lib/pages/admin_dashboard_page.dart:696>)
- หน้าที่: ชื่อ/ยอด/สถานะ
- โค้ดช่วงบรรทัด 695–703:

```dart
 695 │           const SizedBox(height: 10),
 696 │           const Text('ยังไม่มีสลิปให้ตรวจสอบ', style: TextStyle(fontWeight: FontWeight.bold)),
 697 │           const SizedBox(height: 6),
 698 │           const Text('เมื่อลูกค้าส่งหลักฐานการโอน รายการจะแสดงที่นี่', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey)),
 699 │           TextButton.icon(onPressed: () => _load(showLoading: false), icon: const Icon(Icons.refresh), label: const Text('โหลดใหม่')),
 700 │         ]),
 701 │       ))
 702 │     else
 703 │       ...payments.map((row) => Card(child: ExpansionTile(
```

### 24.4 รูปสลิป

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:702](<flutter_application_1/lib/pages/admin_dashboard_page.dart:702>)
- หน้าที่: GET endpoint ป้องกันด้วย auth header
- โค้ดช่วงบรรทัด 701–709:

```dart
 701 │       ))
 702 │     else
 703 │       ...payments.map((row) => Card(child: ExpansionTile(
 704 │         title: Text('ออร์เดอร์ #${row['order_id']} • ฿${row['amount']}'),
 705 │         subtitle: Text('${row['fullname']} • ${row['payment_status_name']}'),
 706 │         children: [
 707 │           if (row['payment_image'] != null) Padding(padding: const EdgeInsets.all(12), child: Image.network('${ApiService.baseUrl.replaceFirst('/api', '')}/api/admin/payments/${row['payment_id']}/slip', headers: ApiService.authHeaders, height: 220, errorBuilder: (_, _, _) => const Text('เปิดสลิปไม่สำเร็จ'))),
 708 │           if (row['payment_status_id'].toString() == '3') OverflowBar(children: [TextButton(onPressed: () => _reviewPayment(row, false), child: const Text('ปฏิเสธ')), FilledButton(onPressed: () => _reviewPayment(row, true), child: const Text('ยืนยันชำระแล้ว'))]),
 709 │         ],
```

### 24.5 ผลตรวจ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:170](<flutter_application_1/lib/pages/admin_dashboard_page.dart:170>)
- หน้าที่: PATCH review true/false; ยอดขายขึ้นเมื่ออนุมัติ
- โค้ดช่วงบรรทัด 170–176:

```dart
 170 │   Future<void> _reviewPayment(Map<String, dynamic> row, bool approved) async {
 171 │     try {
 172 │       await ApiService.adminPatch('/admin/payments/${row['payment_id']}/review', {'approved': approved});
 173 │       await _load(showLoading: false);
 174 │       _show(approved ? 'ยืนยันการชำระเงินแล้ว' : 'ปฏิเสธสลิปแล้ว');
 175 │     } catch (e) { _show(e.toString()); }
 176 │   }
```

## 25 แอดมิน: จัดการร้าน

### 25.1 จัดการร้าน

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:713](<flutter_application_1/lib/pages/admin_dashboard_page.dart:713>)
- หน้าที่: จัดการ PromptPay แบนเนอร์ วันหยุด ลูกค้า เมนู และโต๊ะ
- โค้ดช่วงบรรทัด 713–720:

```dart
 713 │   Widget _management() => ListView(padding: const EdgeInsets.all(12), children: [
 714 │     const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('จัดการร้านใช้ตั้งวันปิดพิเศษ ดูแลบัญชีลูกค้า ปรับเมนู และจัดการโต๊ะ การเปลี่ยนแปลงจะมีผลกับการจองและการสั่งอาหารในแอป'))),
 715 │     Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 716 │       Row(children: [
 717 │         Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.qr_code_2, color: AppColors.orange)),
 718 │         const SizedBox(width: 10),
 719 │         const Expanded(child: Text('QR รับชำระเงิน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
 720 │       ]),
```

### 25.2 วันหยุดพิเศษ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:848](<flutter_application_1/lib/pages/admin_dashboard_page.dart:848>)
- หน้าที่: เลือกวัน กรอกชื่อ เพิ่ม/ลบ
- โค้ดช่วงบรรทัด 847–855:

```dart
 847 │     Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 848 │       const Text('วันหยุดพิเศษ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
 849 │       const SizedBox(height: 4),
 850 │       const Text('เลือกวันที่ร้านปิด ระบบจะปิดรอบจองทั้งหมดของวันนั้น ลูกค้าจะเลือกวันดังกล่าวในปฏิทินจองไม่ได้', style: TextStyle(color: AppColors.grey)),
 851 │       const SizedBox(height: 12),
 852 │       Container(
 853 │         padding: const EdgeInsets.all(12),
 854 │         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7DDD7))),
 855 │         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
```

### 25.3 ลูกค้า

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:916](<flutter_application_1/lib/pages/admin_dashboard_page.dart:916>)
- หน้าที่: เปิดปิด แก้ข้อมูล/รหัส/ลบ
- โค้ดช่วงบรรทัด 915–923:

```dart
 915 │       maintainState: true,
 916 │       title: Text('ลูกค้า (${customers.length})'),
 917 │       subtitle: const Text('เปิดหรือระงับการเข้าใช้งานบัญชี ประวัติเดิมของลูกค้ายังคงอยู่'),
 918 │       children: customers.isEmpty
 919 │           ? [const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีบัญชีลูกค้า', style: TextStyle(color: AppColors.grey))))]
 920 │           : customers.map((row) {
 921 │               final active = row['is_active'].toString() == '1' || row['is_active'] == true;
 922 │               final email = row['email']?.toString() ?? '';
 923 │               return Container(
```

### 25.4 เมนูอาหาร

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:972](<flutter_application_1/lib/pages/admin_dashboard_page.dart:972>)
- หน้าที่: เพิ่ม/แก้ชื่อ ราคา หมวด รูป สถานะ และตัวเลือก; มีหมวดน้ำดื่ม
- โค้ดช่วงบรรทัด 971–979:

```dart
 971 │       children: [
 972 │       Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _editMenu(null), icon: const Icon(Icons.add), label: const Text('เพิ่มเมนู')))),
 973 │       if (menus.isEmpty)
 974 │         const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีเมนูอาหาร', style: TextStyle(color: AppColors.grey))))
 975 │       else
 976 │         ...menus.map((row) {
 977 │           final unavailable = row['statusmenu_id'].toString() == '2';
 978 │           return Container(
 979 │             margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
```

### 25.5 โต๊ะ

- อยู่ที่: [flutter_application_1/lib/pages/admin_dashboard_page.dart:1017](<flutter_application_1/lib/pages/admin_dashboard_page.dart:1017>)
- หน้าที่: เพิ่ม/แก้และปิดรอบ walk-in
- โค้ดช่วงบรรทัด 1016–1024:

```dart
1016 │           padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
1017 │           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEDE6E2))),
1018 │           child: Row(children: [
1019 │             Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.table_restaurant_outlined, color: AppColors.orange)),
1020 │             const SizedBox(width: 12),
1021 │             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
1022 │               Text('โต๊ะ ${row['table_number']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
1023 │               const SizedBox(height: 7),
1024 │               Wrap(spacing: 6, runSpacing: 5, children: [
```

## 26 แอดมิน: หัวข้อและตัวเลือกอาหาร

### 26.1 ชื่อ dialog

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:122](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:122>)
- หน้าที่: เปิดจากฟอร์มเมนู
- โค้ดช่วงบรรทัด 121–129:

```dart
 121 │               ]),
 122 │             ),
 123 │             const Padding(
 124 │               padding: EdgeInsets.symmetric(horizontal: 20),
 125 │               child: Align(alignment: Alignment.centerLeft, child: Text('เพิ่ม ลบ หรือแก้ชื่อหัวข้อและตัวเลือกย่อยได้ เช่น เพิ่มน้ำซุป หรือปรับระดับความเผ็ด', style: TextStyle(color: AppColors.grey))),
 126 │             ),
 127 │             Align(
 128 │               alignment: Alignment.centerRight,
 129 │               child: Padding(
```

### 26.2 หัวข้อ

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:151](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:151>)
- หน้าที่: required และ max_select
- โค้ดช่วงบรรทัด 150–158:

```dart
 150 │                             key: PageStorageKey('menu-option-group-${group['id']}'),
 151 │                             title: Text(group['name'].toString()),
 152 │                             subtitle: Text('${group['required'] == true ? 'ต้องเลือก' : 'ไม่บังคับ'} • เลือกได้สูงสุด ${group['max_select']}'),
 153 │                             trailing: PopupMenuButton<String>(
 154 │                               onSelected: (action) async {
 155 │                                 if (action == 'edit') {
 156 │                                   final updated = await _editGroup(group);
 157 │                                   if (updated != null && mounted) setState(() { group..['name'] = updated['name']..['required'] = updated['required']..['max_select'] = updated['max_select']; });
 158 │                                 } else if (action == 'delete' && mounted) {
```

### 26.3 ตัวเลือกย่อย

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:170](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:170>)
- หน้าที่: ชื่อ/ราคาเพิ่ม/หมด
- โค้ดช่วงบรรทัด 169–177:

```dart
 169 │                                 dense: true,
 170 │                                 title: Text(option['name'].toString()),
 171 │                                 subtitle: Text('${option['available'] == false || option['sold_out'] == true ? 'หมด • ' : ''}ราคาเพิ่ม ฿${option['extra_price']}'),
 172 │                                 trailing: Row(mainAxisSize: MainAxisSize.min, children: [
 173 │                                   IconButton(tooltip: 'แก้ไขตัวเลือก', icon: const Icon(Icons.edit_outlined), onPressed: () async {
 174 │                                     final updated = await _editOption(option);
 175 │                                     if (updated != null && mounted) setState(() { option..['name'] = updated['name']..['extra_price'] = updated['extra_price']..['available'] = updated['available']; });
 176 │                                   }),
 177 │                                   IconButton(tooltip: 'ลบตัวเลือก', icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => options.remove(option))),
```

### 26.4 เพิ่มตัวเลือก

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:183](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:183>)
- หน้าที่: เพิ่มในกลุ่มเดียวกัน
- โค้ดช่วงบรรทัด 182–190:

```dart
 182 │                                 if (option != null && mounted) setState(() => options.add(option));
 183 │                               }, icon: const Icon(Icons.add), label: const Text('เพิ่มตัวเลือกย่อย')),
 184 │                             ],
 185 │                           ),
 186 │                         );
 187 │                       }).toList(),
 188 │                     ),
 189 │             ),
 190 │             Padding(
```

### 26.5 กลุ่มอื่น

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:145](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:145>)
- หน้าที่: เช่น วิธีรับอาหาร
- โค้ดช่วงบรรทัด 144–152:

```dart
 144 │                   : ListView(
 145 │                       padding: const EdgeInsets.symmetric(horizontal: 12),
 146 │                       children: groups.map((group) {
 147 │                         final options = group['options'] as List<Map<String, dynamic>>;
 148 │                         return Card(
 149 │                           child: ExpansionTile(
 150 │                             key: PageStorageKey('menu-option-group-${group['id']}'),
 151 │                             title: Text(group['name'].toString()),
 152 │                             subtitle: Text('${group['required'] == true ? 'ต้องเลือก' : 'ไม่บังคับ'} • เลือกได้สูงสุด ${group['max_select']}'),
```

### 26.6 บันทึก

- อยู่ที่: [flutter_application_1/lib/pages/admin_menu_options_dialog.dart:202](<flutter_application_1/lib/pages/admin_menu_options_dialog.dart:202>)
- หน้าที่: ส่ง JSON option_groups กลับฟอร์มเมนู
- โค้ดช่วงบรรทัด 201–208:

```dart
 201 │                   Navigator.pop(context, groups);
 202 │                 }, child: const Text('บันทึกตัวเลือก')),
 203 │               ]),
 204 │             ),
 205 │           ]),
 206 │         ),
 207 │       );
 208 │ }
```

## 27 ตัวเลือกเวลาจองแบบชั่วโมง–นาที

### 27.1 เปิดตัวเลือก

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:197](<flutter_application_1/lib/pages/reservation_page.dart:197>)
- หน้าที่: showDialog + StatefulBuilder; ช่องหน้าแรก onTap จึงพิมพ์ไม่ได้
- โค้ดช่วงบรรทัด 197–204:

```dart
 197 │   Future<void> _pickTime() async {
 198 │     final now = DateTime.now();
 199 │     final opening = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
 200 │     final lastBooking = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13);
 201 │     final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute)
 202 │         .add(const Duration(minutes: 1));
 203 │     final firstBooking = DateUtils.isSameDay(selectedDate, now) && nextMinute.isAfter(opening)
 204 │         ? nextMinute
```

### 27.2 กรอบเวลาร้าน

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:199](<flutter_application_1/lib/pages/reservation_page.dart:199>)
- หน้าที่: เริ่ม 09:00 สิ้นสุด 13:00 และวันนี้ห้ามย้อนหลัง
- โค้ดช่วงบรรทัด 198–206:

```dart
 198 │     final now = DateTime.now();
 199 │     final opening = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
 200 │     final lastBooking = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13);
 201 │     final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute)
 202 │         .add(const Duration(minutes: 1));
 203 │     final firstBooking = DateUtils.isSameDay(selectedDate, now) && nextMinute.isAfter(opening)
 204 │         ? nextMinute
 205 │         : opening;
 206 │     if (firstBooking.isAfter(lastBooking)) {
```

### 27.3 ชั่วโมง

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:221](<flutter_application_1/lib/pages/reservation_page.dart:221>)
- หน้าที่: สร้างรายการชั่วโมงที่มีนาทีให้เลือกจริง
- โค้ดช่วงบรรทัด 221–228:

```dart
 221 │     final hours = [for (var hour = 9; hour <= 13; hour++)
 222 │       if (availableMinutes(hour).isNotEmpty) hour];
 223 │     final previous = selectedTime == null
 224 │         ? null
 225 │         : DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
 226 │             selectedTime!.hour, selectedTime!.minute);
 227 │     final initial = previous != null && !previous.isBefore(firstBooking) &&
 228 │             !previous.isAfter(lastBooking)
```

### 27.4 นาที

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:212](<flutter_application_1/lib/pages/reservation_page.dart:212>)
- หน้าที่: เลือกนาทีได้ทุกนาทีในชั่วโมงที่เปิด ไม่ใช่รอบละ 1 ชั่วโมง
- โค้ดช่วงบรรทัด 211–219:

```dart
 211 │     }
 212 │
 213 │     List<int> availableMinutes(int hour) {
 214 │       if (hour < firstBooking.hour) return [];
 215 │       final firstMinute = hour == firstBooking.hour ? firstBooking.minute : 0;
 216 │       final lastMinute = hour == 13 ? 0 : 59;
 217 │       if (firstMinute > lastMinute) return [];
 218 │       return List.generate(lastMinute - firstMinute + 1, (index) => firstMinute + index);
 219 │     }
```

### 27.5 ยืนยันเวลา

- อยู่ที่: [flutter_application_1/lib/pages/reservation_page.dart:303](<flutter_application_1/lib/pages/reservation_page.dart:303>)
- หน้าที่: ส่งค่า HH:mm เข้า _onTimeChanged แล้วโหลด availability ใหม่
- โค้ดช่วงบรรทัด 302–310:

```dart
 302 │     if (!mounted || picked == null) return;
 303 │     final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
 304 │     _onTimeChanged(value);
 305 │   }
 306 │
 307 │   String _formatDate(
 308 │     DateTime date,
 309 │   ) {
 310 │     return '${date.year.toString().padLeft(4, '0')}-'
```

## 28 หมวดน้ำดื่มและราคาสินค้า

### 28.1 เลือกหมวด

- อยู่ที่: [flutter_application_1/lib/pages/food_menu_page.dart:564](<flutter_application_1/lib/pages/food_menu_page.dart:564>)
- หน้าที่: Chip น้ำดื่มและตัวกรองใน bottom sheet
- โค้ดช่วงบรรทัด 563–571:

```dart
 563 │                 scrollDirection: Axis.horizontal,
 564 │                 children: ['ทั้งหมด', 'ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].map((category) {
 565 │                   final selected = selectedCategory == category;
 566 │                   return Padding(
 567 │                     padding: const EdgeInsets.only(right: 8),
 568 │                     child: ChoiceChip(
 569 │                       label: Text(category),
 570 │                       selected: selected,
 571 │                       showCheckmark: false,
```

### 28.2 ข้อมูลเมนู

- อยู่ที่: [flutter_application_1/lib/models/food.dart:91](<flutter_application_1/lib/models/food.dart:91>)
- หน้าที่: Food.fromJson ยอมรับ category น้ำดื่มจาก API
- โค้ดช่วงบรรทัด 90–98:

```dart
  90 │           0.0,
  91 │       category: const ['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].contains(json['category']?.toString()) ? json['category'].toString() : (name.contains('ข้าว') ? 'ข้าว' : (name.contains('เส้น') || name.contains('ก๋วยเตี๋ยว') || name.contains('เกาเหลา') ? 'เส้น' : 'อื่นๆ')),
  92 │       imageAsset: imageAsset,
  93 │       imageUrl: json['menu_image'] == null || json['menu_image'].toString().isEmpty
  94 │           ? null
  95 │           : '${ApiService.baseUrl}/menu/$id/image?v=${Uri.encodeComponent(json['menu_image'].toString())}',
  96 │       description: json['description']?.toString() ?? '',
  97 │       optionGroups: (json['option_groups'] as List<dynamic>? ?? [])
  98 │           .map((group) => Map<String, dynamic>.from(group as Map))
```

### 28.3 รายละเอียด

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:154](<flutter_application_1/lib/pages/food_detail_page.dart:154>)
- หน้าที่: isDrink ตรวจ category เท่ากับ น้ำดื่ม
- โค้ดช่วงบรรทัด 154–161:

```dart
 154 │   bool get isDrink => widget.food.category == 'น้ำดื่ม';
 155 │
 156 │   @override
 157 │   void dispose() {
 158 │     noteController.dispose();
 159 │
 160 │     super.dispose();
 161 │   }
```

### 28.4 ราคาพื้นฐาน

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:317](<flutter_application_1/lib/pages/food_detail_page.dart:317>)
- หน้าที่: ใช้คำว่า ราคาเครื่องดื่มพื้นฐาน
- โค้ดช่วงบรรทัด 316–324:

```dart
 316 │                   children: [
 317 │                     Text(isDrink ? 'ราคาเครื่องดื่มพื้นฐาน' : 'ราคาจานพื้นฐาน', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
 318 │                     const Spacer(),
 319 │
 320 │                     Text(
 321 │                       '฿${base.toStringAsFixed(0)}',
 322 │
 323 │                       style:
 324 │                           const TextStyle(
```

### 28.5 สรุปราคา

- อยู่ที่: [flutter_application_1/lib/pages/food_detail_page.dart:429](<flutter_application_1/lib/pages/food_detail_page.dart:429>)
- หน้าที่: สลับคำว่า ราคาเครื่องดื่ม กับ ราคาอาหาร ตามหมวด
- โค้ดช่วงบรรทัด 428–436:

```dart
 428 │                       _priceRow(
 429 │                         isDrink ? 'ราคาเครื่องดื่ม' : 'ราคาอาหาร',
 430 │
 431 │                         '฿${base.toStringAsFixed(0)}',
 432 │                       ),
 433 │
 434 │                       if (extras >
 435 │                           0)
 436 │                         _priceRow(
```
