import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import 'welcome_page.dart';
import 'admin_menu_options_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int index = 0;
  bool loading = true;
  String? error;
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> reservations = [];
  List<Map<String, dynamic>> orderItems = [];
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> holidays = [];
  List<Map<String, dynamic>> menus = [];
  List<Map<String, dynamic>> tables = [];
  String? restaurantBannerImage;
  final restaurantBannerTitle = TextEditingController(text: 'ร้านอาหาร');
  final promptPayId = TextEditingController();
  final promptPayIdFocus = FocusNode();
  bool showPromptPayId = false;
  bool savingPromptPayId = false;
  bool uploadingRestaurantBanner = false;
  bool savingRestaurantBannerTitle = false;
  DateTime? selectedHolidayDate;
  final holidayName = TextEditingController();
  final Set<int> _savingReservationStatuses = <int>{};
  final Set<int> _savingOrderItemStatuses = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    holidayName.dispose();
    restaurantBannerTitle.dispose();
    promptPayId.dispose();
    promptPayIdFocus.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> result) =>
      (result['data'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        ApiService.adminGet('/admin/dashboard'),
        ApiService.adminGet('/admin/reservations'),
        ApiService.adminGet('/admin/order-items'),
        ApiService.adminGet('/admin/payments'),
        ApiService.adminGet('/admin/customers'),
        ApiService.adminGet('/admin/holidays'),
        ApiService.adminGet('/admin/menu'),
        ApiService.adminGet('/admin/tables'),
        ApiService.adminGet('/admin/restaurant/banner'),
        ApiService.adminGet('/admin/payment-settings/promptpay'),
      ]);
      if (!mounted) return;
      setState(() {
        dashboard = Map<String, dynamic>.from(results[0]['data'] as Map? ?? {});
        reservations = _rows(results[1]);
        orderItems = _rows(results[2]);
        payments = _rows(results[3]);
        customers = _rows(results[4]);
        holidays = _rows(results[5]);
        menus = _rows(results[6]);
        tables = _rows(results[7]);
        restaurantBannerImage = results[8]['data']?['banner_image']?.toString();
        if (restaurantBannerImage?.isEmpty == true) restaurantBannerImage = null;
        restaurantBannerTitle.text = results[8]['data']?['banner_title']?.toString() ?? 'ร้านอาหาร';
        if (!promptPayIdFocus.hasFocus) {
          promptPayId.text = results[9]['data']?['promptpay_id']?.toString() ?? '';
        }
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (showLoading) error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeReservation(Map<String, dynamic> row, int status) async {
    final id = int.tryParse(row['reservation_id'].toString());
    if (id == null || !_savingReservationStatuses.add(id)) return;
    setState(() {
      for (final reservation in reservations) {
        if (int.tryParse(reservation['reservation_id'].toString()) == id) {
          reservation['statusreservation_id'] = status;
        }
      }
    });
    try {
      await ApiService.adminPatch('/admin/reservations/$id/status', {'statusreservation_id': status});
      await _load(showLoading: false);
    } catch (e) {
      await _load(showLoading: false);
      _show(e.toString());
    } finally {
      _savingReservationStatuses.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeFoodStatus(Map<String, dynamic> row, String status) async {
    final id = int.tryParse(row['orderdetail_id'].toString());
    if (id == null || !_savingOrderItemStatuses.add(id)) return;
    setState(() {
      for (final item in orderItems) {
        if (int.tryParse(item['orderdetail_id'].toString()) == id) {
          item['food_status'] = status;
          if (status != 'รอทำ') item['order_status'] = 'กำลังทำ';
        }
      }
    });
    try {
      await ApiService.adminPatch('/admin/order-items/$id/status', {'food_status': status});
      await _load(showLoading: false);
    } catch (e) {
      await _load(showLoading: false);
      _show(e.toString());
    } finally {
      _savingOrderItemStatuses.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> row) async {
    final id = int.tryParse(row['orderdetail_id'].toString());
    if (id == null || !_savingOrderItemStatuses.add(id)) return;
    setState(() {
      row['food_status'] = 'กำลังทำ';
      row['order_status'] = 'กำลังทำ';
    });
    try {
      await ApiService.adminPatch('/admin/order-items/$id/accept', {});
      await _load(showLoading: false);
    } catch (e) {
      await _load(showLoading: false);
      _show(e.toString());
    } finally {
      _savingOrderItemStatuses.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _reviewPayment(Map<String, dynamic> row, bool approved) async {
    try {
      await ApiService.adminPatch('/admin/payments/${row['payment_id']}/review', {'approved': approved});
      await _load(showLoading: false);
      _show(approved ? 'ยืนยันการชำระเงินแล้ว' : 'ปฏิเสธสลิปแล้ว');
    } catch (e) { _show(e.toString()); }
  }

  Future<void> _addHoliday() async {
    if (selectedHolidayDate == null || holidayName.text.trim().isEmpty) {
      _show('เลือกวันที่และระบุชื่อวันหยุดก่อน');
      return;
    }
    try {
      await ApiService.adminPost('/admin/holidays', {
        'holiday_date': _formatDate(selectedHolidayDate!),
        'holiday_name': holidayName.text.trim(),
      });
      setState(() => selectedHolidayDate = null);
      holidayName.clear();
      await _load(showLoading: false);
    } catch (e) { _show(e.toString()); }
  }

  Future<void> _changeRestaurantBanner() async {
    if (uploadingRestaurantBanner) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 2000,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      _show('รูปหน้าร้านต้องมีขนาดไม่เกิน 5 MB');
      return;
    }
    final name = picked.name.toLowerCase();
    final mime = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
            ? 'webp'
            : 'jpeg';
    setState(() => uploadingRestaurantBanner = true);
    try {
      final result = await ApiService.adminPost('/admin/restaurant/banner', {
        'image_data': 'data:image/$mime;base64,${base64Encode(bytes)}',
      });
      if (!mounted) return;
      setState(() {
        restaurantBannerImage = result['data']?['banner_image']?.toString();
        uploadingRestaurantBanner = false;
      });
      _show('เปลี่ยนรูปหน้าร้านแล้ว');
    } catch (e) {
      if (!mounted) return;
      setState(() => uploadingRestaurantBanner = false);
      _show(e.toString());
    }
  }

  Future<void> _saveRestaurantBannerTitle() async {
    final title = restaurantBannerTitle.text.trim();
    if (title.isEmpty || title.length > 50) {
      _show('ชื่อบนภาพต้องมีความยาว 1–50 ตัวอักษร');
      return;
    }
    if (savingRestaurantBannerTitle) return;
    setState(() => savingRestaurantBannerTitle = true);
    try {
      await ApiService.adminPut('/admin/restaurant/banner/title', {'banner_title': title});
      if (!mounted) return;
      setState(() => savingRestaurantBannerTitle = false);
      _show('บันทึกชื่อบนภาพแล้ว');
    } catch (e) {
      if (!mounted) return;
      setState(() => savingRestaurantBannerTitle = false);
      _show(e.toString());
    }
  }

  Future<void> _savePromptPayId() async {
    final value = promptPayId.text.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^(0\d{9}|\d{13})$').hasMatch(value)) {
      _show('กรอกเบอร์ PromptPay 10 หลักที่ขึ้นต้นด้วย 0 หรือเลขประจำตัว 13 หลัก');
      return;
    }
    if (savingPromptPayId) return;
    setState(() => savingPromptPayId = true);
    try {
      await ApiService.adminPut('/admin/payment-settings/promptpay', {'promptpay_id': value});
      if (!mounted) return;
      promptPayIdFocus.unfocus();
      setState(() {
        promptPayId.text = value;
        savingPromptPayId = false;
      });
      _show('บันทึกบัญชี PromptPay แล้ว QR สำหรับออร์เดอร์ใหม่จะใช้บัญชีนี้');
    } catch (e) {
      if (!mounted) return;
      setState(() => savingPromptPayId = false);
      _show(e.toString());
    }
  }

  Future<void> _toggleCustomer(Map<String, dynamic> row) async {
    final active = row['is_active'].toString() == '1' || row['is_active'] == true;
    try {
      await ApiService.adminPatch('/admin/customers/${row['user_id']}/status', {'is_active': !active});
      await _load(showLoading: false);
    } catch (e) { _show(e.toString()); }
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    final username = TextEditingController(text: customer['username']?.toString() ?? '');
    final fullname = TextEditingController(text: customer['fullname']?.toString() ?? '');
    final phone = TextEditingController(text: customer['phone']?.toString() ?? '');
    final email = TextEditingController(text: customer['email']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขข้อมูลลูกค้า'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: fullname, decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล')),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'เบอร์โทร')),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมล (ไม่บังคับ)')),
          TextField(controller: username, decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('บันทึก')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await ApiService.adminPut('/admin/customers/${customer['user_id']}', {
          'username': username.text.trim(),
          'fullname': fullname.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
        });
        await _load(showLoading: false);
        _show('บันทึกข้อมูลลูกค้าแล้ว');
      } catch (e) { _show(e.toString()); }
    }
    fullname.dispose();
    username.dispose();
    phone.dispose();
    email.dispose();
  }

  Future<void> _resetCustomerPassword(Map<String, dynamic> customer) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? validationError;
    final newPassword = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('ตั้งรหัสผ่านใหม่'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('กำหนดรหัสผ่านใหม่ให้ ${customer['fullname']}'),
          const SizedBox(height: 10),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่')),
          TextField(controller: confirmation, obscureText: true, decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่านใหม่')),
          if (validationError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(validationError!, style: const TextStyle(color: AppColors.danger))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () {
            if (password.text.length < 8) {
              setDialogState(() => validationError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
            } else if (password.text != confirmation.text) {
              setDialogState(() => validationError = 'รหัสผ่านทั้งสองช่องไม่ตรงกัน');
            } else {
              Navigator.pop(dialogContext, password.text);
            }
          }, child: const Text('ตั้งรหัสผ่าน')),
        ],
      )),
    );
    if (newPassword != null) {
      try {
        await ApiService.adminPatch('/admin/customers/${customer['user_id']}/password', {'password': newPassword});
        _show('ตั้งรหัสผ่านใหม่แล้ว แจ้งรหัสผ่านใหม่ให้ลูกค้าด้วย');
      } catch (e) { _show(e.toString()); }
    }
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบบัญชีลูกค้า'),
        content: Text('ยืนยันลบบัญชี ${customer['fullname']}? บัญชีจะเข้าสู่ระบบไม่ได้และข้อมูลส่วนตัวจะถูกลบออกจากบัญชี ประวัติออร์เดอร์และการจองจะเก็บไว้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('กลับ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('ลบบัญชี')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.adminDelete('/admin/customers/${customer['user_id']}');
      await _load(showLoading: false);
      _show('ลบบัญชีลูกค้าแล้ว และเก็บประวัติเดิมไว้');
    } catch (e) { _show(e.toString()); }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickHolidayDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
      initialDate: selectedHolidayDate ?? today,
    );
    if (date != null && mounted) setState(() => selectedHolidayDate = date);
  }

  Future<void> _editMenu(Map<String, dynamic>? menu) async {
    final name = TextEditingController(text: menu?['menu_name']?.toString() ?? '');
    final price = TextEditingController(text: menu?['price']?.toString() ?? '');
    String category = ['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].contains(menu?['category']) ? menu!['category'].toString() : 'อื่นๆ';
    String? uploadedImage = menu?['menu_image']?.toString();
    Uint8List? previewBytes;
    String imageMime = 'jpeg';
    List<Map<String, dynamic>> optionGroups = menu == null
        ? defaultMenuOptionGroups()
        : (menu['option_groups'] as List<dynamic>? ?? [])
            .map((group) => Map<String, dynamic>.from(group as Map))
            .toList();
    int status = int.tryParse(menu?['statusmenu_id']?.toString() ?? '1') ?? 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(menu == null ? 'เพิ่มเมนู' : 'แก้ไขเมนู'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'ชื่อเมนู')),
          TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ราคา')),
          DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'หมวดเมนู'), items: const ['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) {
            if (value == null) return;
            setDialogState(() {
              final wasDrink = category == 'น้ำดื่ม';
              if (value == 'น้ำดื่ม' &&
                  jsonEncode(optionGroups) == jsonEncode(defaultMenuOptionGroups())) {
                optionGroups = [];
              } else if (wasDrink && value != 'น้ำดื่ม' && optionGroups.isEmpty) {
                optionGroups = defaultMenuOptionGroups();
              }
              category = value;
            });
          }),
          if (category == 'ข้าว') const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('ใส่ราคาจานพื้นฐาน ไม่รวมเนื้อ ลูกค้าเลือกผสมเนื้อได้สูงสุด 5 ชนิดและระบบจะบวกราคาแต่ละชนิด', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ),
          const SizedBox(height: 8),
          if (previewBytes != null) Image.memory(previewBytes!, height: 100, fit: BoxFit.cover)
          else if (uploadedImage != null && uploadedImage!.isNotEmpty) Image.network('${ApiService.baseUrl}/menu/${menu?['menu_id']}/image', headers: ApiService.authHeaders, height: 100, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          TextButton.icon(onPressed: () async {
            final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1200);
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            if (bytes.length > 3 * 1024 * 1024) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รูปเมนูต้องมีขนาดไม่เกิน 3 MB'))); return; }
            setDialogState(() { previewBytes = bytes; uploadedImage = null; imageMime = picked.name.toLowerCase().endsWith('.png') ? 'png' : picked.name.toLowerCase().endsWith('.webp') ? 'webp' : 'jpeg'; });
          }, icon: const Icon(Icons.image_outlined), label: const Text('เลือกรูปเมนู')),
          DropdownButton<int>(value: status, items: const [DropdownMenuItem(value: 1, child: Text('พร้อมขาย')), DropdownMenuItem(value: 2, child: Text('หมด / หยุดขาย'))], onChanged: (v) { if (v != null) setDialogState(() => status = v); }),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () async {
              final result = await showDialog<List<Map<String, dynamic>>>(
                context: context,
                builder: (_) => AdminMenuOptionsDialog(initialGroups: optionGroups),
              );
              if (result != null) setDialogState(() => optionGroups = result);
            },
            icon: const Icon(Icons.tune),
            label: Text('จัดการหัวข้อและตัวเลือก (${optionGroups.length})'),
          )),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('บันทึก'))],
      )),
    );
    if (saved == true) {
      try {
        if (category == 'ข้าว' && !optionGroups.any((group) => group['id'] == 'protein' || group['name'] == 'เนื้อ')) {
          optionGroups.add(defaultMenuProteinGroup());
        }
        final body = {'menu_name': name.text.trim(), 'price': double.tryParse(price.text) ?? -1, 'category': category, 'option_groups': optionGroups, 'statusmenu_id': status};
        if (previewBytes != null) {
          body['menu_image'] = await ApiService.uploadMenuImage('data:image/$imageMime;base64,${base64Encode(previewBytes!)}');
        }
        if (menu == null) { await ApiService.adminPost('/admin/menu', body); }
        else { await ApiService.adminPut('/admin/menu/${menu['menu_id']}', body); }
        await _load(showLoading: false);
      } catch (e) { _show(e.toString()); }
    }
    name.dispose();
    price.dispose();
  }

  Future<void> _cancelMenu(Map<String, dynamic> menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('หยุดขายเมนูนี้หรือไม่'),
        content: Text('“${menu['menu_name']}” จะไม่แสดงให้ลูกค้าสั่ง แต่ข้อมูลและประวัติออร์เดอร์เดิมจะยังอยู่'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('กลับ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('หยุดขายเมนู')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.adminPut('/admin/menu/${menu['menu_id']}', {
        'menu_name': menu['menu_name'],
        'price': double.tryParse(menu['price'].toString()) ?? 0,
        'category': menu['category']?.toString() ?? 'อื่นๆ',
        'menu_image': menu['menu_image'],
        'option_groups': menu['option_groups'] ?? <Map<String, dynamic>>[],
        'statusmenu_id': 2,
      });
      await _load(showLoading: false);
      _show('หยุดขายเมนูแล้ว');
    } catch (e) { _show(e.toString()); }
  }

  Future<void> _editTable(Map<String, dynamic>? table) async {
    final number = TextEditingController(text: table?['table_number']?.toString() ?? '');
    final capacity = TextEditingController(text: table?['capacity']?.toString() ?? '4');
    int status = int.tryParse(table?['statustable_id']?.toString() ?? '1') ?? 1;
    final saved = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(table == null ? 'เพิ่มโต๊ะ' : 'แก้ไขโต๊ะ'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: number, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'หมายเลขโต๊ะ')),
        TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนที่นั่ง')),
        DropdownButton<int>(value: status, items: const [DropdownMenuItem(value: 1, child: Text('เปิดใช้งาน')), DropdownMenuItem(value: 2, child: Text('ปิดใช้งาน'))], onChanged: (value) { if (value != null) setDialogState(() => status = value); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('บันทึก'))],
    )));
    if (saved == true) {
      try {
        final body = {'table_number': int.tryParse(number.text) ?? 0, 'capacity': int.tryParse(capacity.text) ?? 0, 'statustable_id': status};
        if (table == null) { await ApiService.adminPost('/admin/tables', body); }
        else { await ApiService.adminPut('/admin/tables/${table['table_id']}', body); }
        await _load(showLoading: false);
      } catch (e) { _show(e.toString()); }
    }
    number.dispose();
    capacity.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['ภาพรวม', 'การจอง', 'ครัว', 'ชำระเงิน', 'จัดการร้าน'];
    final pages = [_dashboard(), _reservations(), _kitchen(), _payments(), _management()];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(titles[index]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () { CurrentUserService.instance.clearUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false); }, icon: const Icon(Icons.logout))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: pages[index]),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'ภาพรวม'),
        NavigationDestination(icon: Icon(Icons.event_note), label: 'จอง'),
        NavigationDestination(icon: Icon(Icons.soup_kitchen_outlined), label: 'ครัว'),
        NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'ชำระ'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'จัดการ'),
      ]),
    );
  }

  Widget _dashboard() {
    final popular = (dashboard['popular_menus'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final sales = (dashboard['daily_sales'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      _metric('ยอดขายเดือนนี้', '฿${dashboard['monthly_sales'] ?? 0}'),
      _metric('การจองวันนี้', '${dashboard['today_reservations'] ?? 0} รายการ'),
      const SizedBox(height: 16),
      const Text('กราฟยอดขายรายวัน • เดือนนี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.fromLTRB(12, 16, 12, 12), child: SizedBox(height: 190, child: _SalesChart(rows: sales)))),
      const SizedBox(height: 12),
      const Text('เมนูยอดนิยมเดือนนี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...popular.map((item) => ListTile(title: Text('${item['menu_name']}'), subtitle: Text('${item['plates']} จาน'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('฿${item['revenue'] ?? 0}'), Text('${item['percentage'] ?? 0}%', style: const TextStyle(color: AppColors.grey, fontSize: 11))]))),
    ]);
  }

  Widget _metric(String label, String value) => Card(child: ListTile(title: Text(label), trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.orange))));

  Widget _reservations() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
    rows: reservations,
    dateField: 'dining_date',
    emptyMessage: 'ยังไม่มีรายการจอง',
    rowBuilder: (row) => Card(child: ListTile(
      title: Text('${row['fullname']} • โต๊ะ ${row['table_number']}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _timeBadge(row['dining_time']?.toString() ?? ''),
          const SizedBox(height: 5),
          Text('${row['guests']} คน${row['phone']?.toString().isNotEmpty == true ? ' • ${row['phone']}' : ''}'),
        ]),
      ),
      trailing: DropdownButton<int>(value: int.tryParse(row['statusreservation_id'].toString()), items: const [DropdownMenuItem(value: 1, child: Text('ยืนยันแล้ว')), DropdownMenuItem(value: 2, child: Text('ยกเลิก')), DropdownMenuItem(value: 3, child: Text('มาใช้บริการแล้ว')), DropdownMenuItem(value: 4, child: Text('รอยืนยัน'))], onChanged: _savingReservationStatuses.contains(int.tryParse(row['reservation_id'].toString())) ? null : (v) { if (v != null) _changeReservation(row, v); }),
    )),
  ));

  List<Widget> _dateSections({
    required List<Map<String, dynamic>> rows,
    required String dateField,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) rowBuilder,
  }) {
    if (rows.isEmpty) return [Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.grey)))))];
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final raw = row[dateField]?.toString() ?? '';
      final day = raw.length >= 10 ? raw.substring(0, 10) : 'ไม่ระบุวันที่';
      groups.putIfAbsent(day, () => []).add(row);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days) ...[
        Container(
          margin: const EdgeInsets.fromLTRB(2, 12, 2, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.calendar_month_outlined, color: AppColors.orange, size: 19),
            const SizedBox(width: 8),
            Expanded(child: Text(day == 'ไม่ระบุวันที่' ? day : 'วันที่ $day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
            Text('${groups[day]!.length} รายการ', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ]),
        ),
        ...groups[day]!.map(rowBuilder),
      ],
    ];
  }

  Widget _timeBadge(String value) {
    final display = RegExp(r'\d{2}:\d{2}').firstMatch(value)?.group(0) ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule, size: 14, color: AppColors.orange),
        const SizedBox(width: 5),
        Text(display.isEmpty ? 'ไม่ระบุเวลา' : display, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange, fontSize: 12)),
      ]),
    );
  }

  Widget _dateBadge(String value) {
    final display = value.length >= 10 ? value.substring(0, 10).replaceAll('-', '/') : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.danger),
        const SizedBox(width: 5),
        Text(display, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger, fontSize: 12)),
      ]),
    );
  }

  String _selectedOptionsText(Map<String, dynamic> row) {
    final raw = row['selected_options'];
    if (raw == null) return '';
    try {
      final selections = raw is String ? jsonDecode(raw) as List<dynamic> : raw as List<dynamic>;
      return selections.map((entry) {
        final item = Map<String, dynamic>.from(entry as Map);
        return '${item['group_name']}: ${item['option_name']}';
      }).join(' • ');
    } catch (_) {
      return '';
    }
  }

  Widget _kitchen() => ListView(padding: const EdgeInsets.all(12), children: _dateSections(
    rows: orderItems,
    dateField: 'order_date',
    emptyMessage: 'ยังไม่มีรายการอาหารในครัว',
    rowBuilder: (row) => Card(child: ListTile(
      title: Text('#${row['order_id']} • ${row['menu_name']} × ${row['quantity']}'),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _timeBadge(row['order_date']?.toString() ?? ''),
        const SizedBox(height: 5),
        Text([
          row['table_number'] == null ? 'ไม่ระบุโต๊ะ' : 'โต๊ะ ${row['table_number']}',
          if (_selectedOptionsText(row).isNotEmpty) _selectedOptionsText(row),
          row['note']?.toString().isNotEmpty == true ? row['note'].toString() : 'ไม่มีหมายเหตุ',
        ].join(' • ')),
        if (row['food_status'] == 'รอทำ' && row['order_status'] != 'ยกเลิก' && row['order_status'] != 'ชำระแล้ว')
          TextButton.icon(
            onPressed: () => _acceptOrder(row),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: Text(_savingOrderItemStatuses.contains(int.tryParse(row['orderdetail_id'].toString())) ? 'กำลังรับเมนู...' : 'รับเมนูนี้'),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: VisualDensity.compact),
          ),
      ]),
      trailing: DropdownButton<String>(value: ['รอทำ', 'กำลังทำ', 'ทำเสร็จแล้ว'].contains(row['food_status']) ? row['food_status'] as String : 'รอทำ', items: const [DropdownMenuItem(value: 'รอทำ', child: Text('รอทำ')), DropdownMenuItem(value: 'กำลังทำ', child: Text('กำลังทำ')), DropdownMenuItem(value: 'ทำเสร็จแล้ว', child: Text('เสร็จแล้ว'))], onChanged: _savingOrderItemStatuses.contains(int.tryParse(row['orderdetail_id'].toString())) ? null : (v) { if (v != null) _changeFoodStatus(row, v); }),
    )),
  ));

  Widget _payments() => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(
      padding: EdgeInsets.all(14),
      child: Text('หน้านี้แสดงสลิปที่ลูกค้าส่งมา หลังสแกน QR PromptPay และโอนเงินแล้ว ตรวจสอบยอดกับสลิปก่อนกดยืนยัน ระบบจะบันทึกยอดขายเมื่อยืนยันการชำระเงิน'),
    )),
    if (payments.isEmpty)
      Card(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.grey),
          const SizedBox(height: 10),
          const Text('ยังไม่มีสลิปให้ตรวจสอบ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('เมื่อลูกค้าส่งหลักฐานการโอน รายการจะแสดงที่นี่', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey)),
          TextButton.icon(onPressed: () => _load(showLoading: false), icon: const Icon(Icons.refresh), label: const Text('โหลดใหม่')),
        ]),
      ))
    else
      ...payments.map((row) => Card(child: ExpansionTile(
        title: Text('ออร์เดอร์ #${row['order_id']} • ฿${row['amount']}'),
        subtitle: Text('${row['fullname']} • ${row['payment_status_name']}'),
        children: [
          if (row['payment_image'] != null) Padding(padding: const EdgeInsets.all(12), child: Image.network('${ApiService.baseUrl.replaceFirst('/api', '')}/api/admin/payments/${row['payment_id']}/slip', headers: ApiService.authHeaders, height: 220, errorBuilder: (_, _, _) => const Text('เปิดสลิปไม่สำเร็จ'))),
          if (row['payment_status_id'].toString() == '3') OverflowBar(children: [TextButton(onPressed: () => _reviewPayment(row, false), child: const Text('ปฏิเสธ')), FilledButton(onPressed: () => _reviewPayment(row, true), child: const Text('ยืนยันชำระแล้ว'))]),
        ],
      )))
  ]);

  Widget _management() => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('จัดการร้านใช้ตั้งวันปิดพิเศษ ดูแลบัญชีลูกค้า ปรับเมนู และจัดการโต๊ะ การเปลี่ยนแปลงจะมีผลกับการจองและการสั่งอาหารในแอป'))),
    Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.qr_code_2, color: AppColors.orange)),
        const SizedBox(width: 10),
        const Expanded(child: Text('QR รับชำระเงิน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      ]),
      const Padding(padding: EdgeInsets.only(left: 48, top: 2), child: Text('ตั้งค่าบัญชี PromptPay ที่ลูกค้าจะสแกนชำระเงิน QR จะสร้างตามยอดของแต่ละออร์เดอร์โดยอัตโนมัติ', style: TextStyle(color: AppColors.grey))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7DDD7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFFFF0E8), shape: BoxShape.circle), child: const Text('1', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Text('บัญชีรับเงิน', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: promptPayId,
            focusNode: promptPayIdFocus,
            keyboardType: TextInputType.number,
            maxLength: 13,
            obscureText: !showPromptPayId,
            decoration: InputDecoration(
              labelText: 'เบอร์โทร PromptPay หรือเลขประจำตัว',
              hintText: 'เบอร์ 10 หลัก หรือเลข 13 หลัก',
              suffixIcon: IconButton(
                tooltip: showPromptPayId ? 'ซ่อนเลขบัญชี' : 'แสดงเลขบัญชี',
                onPressed: () => setState(() => showPromptPayId = !showPromptPayId),
                icon: Icon(showPromptPayId ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7DDD7))),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: savingPromptPayId ? null : _savePromptPayId,
          icon: savingPromptPayId
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(savingPromptPayId ? 'กำลังบันทึก...' : 'บันทึกบัญชี PromptPay'),
        ),
      ),
    ]))),
    Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.title, color: AppColors.orange)),
        const SizedBox(width: 10),
        const Expanded(child: Text('ข้อความบนแบนเนอร์', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      ]),
      const Padding(padding: EdgeInsets.only(left: 48, top: 2), child: Text('แก้ชื่อที่แสดงทับอยู่บนภาพหน้าแรก', style: TextStyle(color: AppColors.grey))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7DDD7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFFFF0E8), shape: BoxShape.circle), child: const Text('1', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Text('ข้อความที่แสดง', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: restaurantBannerTitle,
            maxLength: 50,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'ชื่อร้านหรือข้อความ',
              hintText: 'เช่น ร้านอาหาร บ้านสวน',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7DDD7))),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: savingRestaurantBannerTitle ? null : _saveRestaurantBannerTitle,
          icon: savingRestaurantBannerTitle
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(savingRestaurantBannerTitle ? 'กำลังบันทึก...' : 'บันทึกข้อความ'),
        ),
      ),
    ]))),
    const SizedBox(height: 8),
    Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.image_outlined, color: AppColors.orange)),
        const SizedBox(width: 10),
        const Expanded(child: Text('ภาพแบนเนอร์', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      ]),
      const Padding(padding: EdgeInsets.only(left: 48, top: 2), child: Text('เปลี่ยนภาพพื้นหลังที่แสดงบนหน้าแรก', style: TextStyle(color: AppColors.grey))),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: restaurantBannerImage == null
              ? Image.asset('assets/restaurant.jpg', fit: BoxFit.cover)
              : Image.network(
                  ApiService.restaurantBannerImageUrl(restaurantBannerImage!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset('assets/restaurant.jpg', fit: BoxFit.cover),
                ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: uploadingRestaurantBanner ? null : _changeRestaurantBanner,
          icon: uploadingRestaurantBanner
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.image_outlined),
          label: Text(uploadingRestaurantBanner ? 'กำลังบันทึกรูป...' : 'เลือกรูปแบนเนอร์'),
        ),
      ),
    ]))),
    Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('วันหยุดพิเศษ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('เลือกวันที่ร้านปิด ระบบจะปิดรอบจองทั้งหมดของวันนั้น ลูกค้าจะเลือกวันดังกล่าวในปฏิทินจองไม่ได้', style: TextStyle(color: AppColors.grey)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7DDD7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFFFF0E8), shape: BoxShape.circle), child: const Text('1', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Text('วันที่ร้านปิด', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickHolidayDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(selectedHolidayDate == null ? 'เลือกวันที่ปิดร้าน' : _formatDate(selectedHolidayDate!)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7DDD7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFFFF0E8), shape: BoxShape.circle), child: const Text('2', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Text('ชื่อวันหยุด', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: holidayName,
            decoration: InputDecoration(
              hintText: 'เช่น วันหยุดประจำปี',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7DDD7))),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _addHoliday, icon: const Icon(Icons.add), label: const Text('เพิ่มวันหยุด'))),
      if (holidays.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีวันหยุดพิเศษ', style: TextStyle(color: AppColors.grey))))
      else
        ...holidays.map((row) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFD4D4))),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event_busy_outlined, color: AppColors.danger)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['holiday_name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _dateBadge(row['holiday_date'].toString()),
            ])),
            IconButton(tooltip: 'ลบวันหยุด', icon: const Icon(Icons.delete_outline, color: AppColors.grey), onPressed: () async { try { await ApiService.adminDelete('/admin/holidays/${row['holiday_id']}'); await _load(showLoading: false); } catch (e) { _show(e.toString()); } }),
          ]),
        )),
    ]))),
    Card(child: ExpansionTile(
      key: const PageStorageKey<String>('admin-customers'),
      maintainState: true,
      title: Text('ลูกค้า (${customers.length})'),
      subtitle: const Text('เปิดหรือระงับการเข้าใช้งานบัญชี ประวัติเดิมของลูกค้ายังคงอยู่'),
      children: customers.isEmpty
          ? [const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีบัญชีลูกค้า', style: TextStyle(color: AppColors.grey))))]
          : customers.map((row) {
              final active = row['is_active'].toString() == '1' || row['is_active'] == true;
              final email = row['email']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEDE6E2))),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_outline, color: AppColors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(row['fullname']?.toString().trim().isNotEmpty == true ? row['fullname'].toString() : 'ไม่ระบุชื่อ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text('@${row['username'] ?? '-'}', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    if ((row['phone']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(row['phone'].toString(), style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    ],
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(email, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    ],
                    const SizedBox(height: 7),
                    _menuInfoChip(active ? 'เปิดใช้งาน' : 'ระงับบัญชี', active ? Colors.green : AppColors.danger),
                  ])),
                  const SizedBox(width: 4),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Switch(value: active, onChanged: (_) => _toggleCustomer(row)),
                    PopupMenuButton<String>(
                      tooltip: 'จัดการบัญชีลูกค้า',
                      onSelected: (action) {
                        if (action == 'edit') _editCustomer(row);
                        if (action == 'password') _resetCustomerPassword(row);
                        if (action == 'delete') _deleteCustomer(row);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('แก้ไขข้อมูล'))),
                        PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.lock_reset), title: Text('ตั้งรหัสผ่านใหม่'))),
                        PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppColors.danger), title: Text('ลบบัญชี'))),
                      ],
                    ),
                  ]),
                ]),
              );
            }).toList(),
    )),
    Card(child: ExpansionTile(
      key: const PageStorageKey<String>('admin-menus'),
      maintainState: true,
      title: Text('เมนูอาหารและเครื่องดื่ม (${menus.length})'),
      subtitle: const Text('เพิ่มเมนู แก้ไขชื่อและราคา หรือเปลี่ยนสถานะพร้อมขาย/หมด'),
      children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _editMenu(null), icon: const Icon(Icons.add), label: const Text('เพิ่มเมนู')))),
      if (menus.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีเมนูอาหาร', style: TextStyle(color: AppColors.grey))))
      else
        ...menus.map((row) {
          final unavailable = row['statusmenu_id'].toString() == '2';
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEDE6E2))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row['menu_name'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Wrap(spacing: 6, runSpacing: 5, children: [
                  _menuInfoChip(row['category']?.toString() ?? 'อื่นๆ', AppColors.orange),
                  _menuInfoChip(unavailable ? 'หยุดขาย' : 'พร้อมขาย', unavailable ? AppColors.danger : Colors.green),
                ]),
                const SizedBox(height: 7),
                Text('฿${row['price']}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
              ])),
              const SizedBox(width: 8),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (!unavailable) IconButton(tooltip: 'หยุดขายเมนู', visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger), onPressed: () => _cancelMenu(row)),
                IconButton(tooltip: 'แก้ไขเมนู', visualDensity: VisualDensity.compact, icon: const Icon(Icons.edit_outlined), onPressed: () => _editMenu(row)),
              ]),
            ]),
          );
        }),
    ])),
    Card(child: ExpansionTile(
      key: const PageStorageKey<String>('admin-tables'),
      maintainState: true,
      title: Text('โต๊ะ (${tables.length})'),
      subtitle: const Text('จัดหมายเลขโต๊ะและจำนวนที่นั่ง ปิดรอบโต๊ะที่ลูกค้าเดินเข้ามาใช้บริการเมื่อเสร็จแล้ว'),
      children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _editTable(null), icon: const Icon(Icons.add), label: const Text('เพิ่มโต๊ะ')))),
      if (tables.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('ยังไม่มีโต๊ะ', style: TextStyle(color: AppColors.grey))))
      else
      ...tables.map((row) {
        final occupied = row['is_occupied'] == true || row['is_occupied'].toString() == '1';
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEDE6E2))),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFF0E8), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.table_restaurant_outlined, color: AppColors.orange)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('โต๊ะ ${row['table_number']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 5, children: [
                _menuInfoChip('${row['capacity']} ที่นั่ง', AppColors.grey),
                _menuInfoChip(occupied ? 'มีลูกค้าใช้บริการ' : (row['statustable_name']?.toString() ?? 'ว่าง'), occupied ? AppColors.orange : Colors.green),
              ]),
            ])),
            const SizedBox(width: 4),
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (occupied) IconButton(
                tooltip: 'ปิดรอบโต๊ะ',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () async {
                  try {
                    await ApiService.adminDelete('/admin/tables/${row['table_id']}/walk-in-session');
                    await _load(showLoading: false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปิดรอบโต๊ะแล้ว')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ปิดรอบโต๊ะไม่สำเร็จ: $e')));
                  }
                },
              ),
              IconButton(tooltip: 'แก้ไขโต๊ะ', visualDensity: VisualDensity.compact, icon: const Icon(Icons.edit_outlined), onPressed: () => _editTable(row)),
            ]),
          ]),
        );
      }),
    ])),
  ]);

  Widget _menuInfoChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
  );
}

class _SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _SalesChart({required this.rows});
  @override
  Widget build(BuildContext context) {
    final data = <DateTime, double>{};
    for (final row in rows) {
      final date = DateTime.tryParse(row['day']?.toString() ?? '');
      final amount = double.tryParse(row['sales']?.toString() ?? '') ?? 0;
      if (date != null) data[DateTime(date.year, date.month, date.day)] = amount;
    }
    final now = DateTime.now();
    final days = DateTime(now.year, now.month + 1, 0).day;
    final values = List<double>.generate(days, (i) => data[DateTime(now.year, now.month, i + 1)] ?? 0);
    return Column(children: [
      Expanded(child: CustomPaint(painter: _SalesChartPainter(values), child: const SizedBox.expand())),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1 ${_monthName(now.month)}', style: const TextStyle(fontSize: 10, color: AppColors.grey)), Text('$days ${_monthName(now.month)}', style: const TextStyle(fontSize: 10, color: AppColors.grey))]),
    ]);
  }
  String _monthName(int month) => const ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'][month - 1];
}

class _SalesChartPainter extends CustomPainter {
  final List<double> values;
  _SalesChartPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(8, 8, size.width - 6, size.height - 8);
    final grid = Paint()..color = const Color(0xFFEAE4E0)..strokeWidth = 1;
    final line = Paint()..color = AppColors.orange..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    if (values.isEmpty || values.every((v) => v == 0)) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final denominator = (values.length - 1).clamp(1, 9999);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(chart.left + chart.width * i / denominator, chart.bottom - chart.height * values[i] / maxValue);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, line);
  }
  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) => oldDelegate.values != values;
}
