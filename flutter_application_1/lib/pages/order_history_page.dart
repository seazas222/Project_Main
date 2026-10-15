import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../core/app_theme.dart';
import '../models/food.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import 'payment_qr_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final user = CurrentUserService.instance.user;
    if (user == null) return Future.error('กรุณาเข้าสู่ระบบ');
    return ApiService.getOrdersByUserId(user.userId);
  }

  Future<void> _refresh() async {
    final refreshed = _load();
    if (mounted) setState(() { future = refreshed; });
    try { await refreshed; } catch (_) { /* FutureBuilder renders the error. */ }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final orderId = int.parse(order['order_id'].toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยกเลิกออร์เดอร์?'),
        content: Text('ยกเลิกออร์เดอร์ #$orderId ใช่หรือไม่? ยกเลิกได้ก่อนร้านรับออร์เดอร์เท่านั้น'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('กลับ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('ยกเลิกออร์เดอร์')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.cancelOrder(orderId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยกเลิกออร์เดอร์แล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _editOrder(int orderId) async {
    try {
      var details = await ApiService.getOrderDetails(orderId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('แก้ไขออร์เดอร์ #$orderId'),
            content: SizedBox(
              width: 480,
              height: 360,
              child: details.isEmpty
                  ? const Center(child: Text('ไม่พบรายการอาหาร'))
                  : ListView.separated(
                      itemCount: details.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = details[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${item['menu_name']} × ${item['quantity']}'),
                          subtitle: Text(_itemDescription(item)),
                          trailing: item['food_status'] == 'รอทำ'
                              ? IconButton(
                                  tooltip: 'เปลี่ยนรายละเอียดอาหาร',
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.orange),
                                  onPressed: () async {
                                    final saved = await _editOrderItem(orderId, item);
                                    if (saved == true) {
                                      try {
                                        final updated = await ApiService.getOrderDetails(orderId);
                                        if (mounted) setDialogState(() => details = updated);
                                      } catch (_) {}
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ปิด'))],
          ),
        ),
      );
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<bool?> _editOrderItem(int orderId, Map<String, dynamic> item) async {
    final menus = await ApiService.getMenus();
    if (!mounted) return null;
    final currentId = int.tryParse(item['menu_id'].toString()) ?? 0;
    if (!menus.any((menu) => int.tryParse(menu.id) == currentId)) {
      menus.add(Food.fromJson({
        'menu_id': currentId,
        'menu_name': item['menu_name'],
        'price': item['menu_price'] ?? item['price'],
      }));
    }

    final quantityController = TextEditingController(text: item['quantity'].toString());
    final noteController = TextEditingController(text: item['note']?.toString() ?? '');
    var menuId = currentId;
    final selectedOptionIds = <String, List<String>>{};
    try {
      final raw = item['selected_options'];
      final savedOptions = raw is String ? jsonDecode(raw) as List<dynamic> : raw as List<dynamic>? ?? const [];
      for (final entry in savedOptions) {
        final option = Map<String, dynamic>.from(entry as Map);
        final groupId = option['group_id']?.toString() ?? '';
        final optionId = option['option_id']?.toString() ?? '';
        if (groupId.isNotEmpty && optionId.isNotEmpty) {
          selectedOptionIds.putIfAbsent(groupId, () => []).add(optionId);
        }
      }
    } catch (_) {}
    void initializeRequiredOptions(Food food) {
      for (final group in food.optionGroups) {
        final groupId = group['id']?.toString() ?? '';
        final options = group['options'] as List<dynamic>? ?? [];
        if (groupId.isEmpty || options.isEmpty || selectedOptionIds.containsKey(groupId)) continue;
        if (group['required'] == true) {
          selectedOptionIds[groupId] = [(options.first as Map)['id'].toString()];
        }
      }
    }
    Food currentMenu() => menus.firstWhere((menu) => int.tryParse(menu.id) == menuId);
    initializeRequiredOptions(currentMenu());

    List<Widget> buildOptionGroups(void Function(void Function()) setDialogState) {
      final food = currentMenu();
      if (food.optionGroups.isEmpty) return [const Text('เมนูนี้ไม่มีตัวเลือกเพิ่มเติม')];
      return food.optionGroups.map((group) {
        final groupId = group['id']?.toString() ?? '';
        final options = (group['options'] as List<dynamic>? ?? [])
            .map((option) => Map<String, dynamic>.from(option as Map)).toList();
        final maxSelect = int.tryParse(group['max_select']?.toString() ?? '1') ?? 1;
        final selected = selectedOptionIds[groupId] ?? const <String>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group['name']?.toString() ?? 'ตัวเลือก', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Wrap(spacing: 7, runSpacing: 4, children: options.map((option) {
              final optionId = option['id']?.toString() ?? '';
              final isSelected = selected.contains(optionId);
              final extra = double.tryParse(option['extra_price']?.toString() ?? '') ?? 0;
              return ChoiceChip(
                label: Text('${option['name']}${extra > 0 ? ' +฿${extra.toStringAsFixed(extra % 1 == 0 ? 0 : 2)}' : ''}'),
                selected: isSelected,
                onSelected: (_) => setDialogState(() {
                  if (maxSelect == 1) {
                    selectedOptionIds[groupId] = [optionId];
                  } else if (isSelected) {
                    selectedOptionIds[groupId] = selected.where((id) => id != optionId).toList();
                  } else if (selected.length < maxSelect) {
                    selectedOptionIds[groupId] = [...selected, optionId];
                  }
                }),
              );
            }).toList()),
          ]),
        );
      }).toList();
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เปลี่ยนรายละเอียดอาหาร'),
          content: SizedBox(
            width: 440,
            height: 460,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _editSection('เมนูและจำนวน', Icons.restaurant_menu, [
                  DropdownButtonFormField<int>(
                    initialValue: menuId,
                    decoration: const InputDecoration(labelText: 'เมนู'),
                    items: menus.map((menu) => DropdownMenuItem(value: int.parse(menu.id), child: Text(menu.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        menuId = value;
                        selectedOptionIds.clear();
                        initializeRequiredOptions(currentMenu());
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'จำนวน'),
                  ),
                ]),
                _editSection('ตัวเลือกอาหาร', Icons.tune, buildOptionGroups(setDialogState)),
                _editSection('หมายเหตุถึงครัว', Icons.sticky_note_2_outlined, [
                  TextField(controller: noteController, maxLength: 500, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น ไม่ใส่ผัก')),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('กลับ')),
            FilledButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity < 1 || quantity > 99) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('จำนวนต้องอยู่ระหว่าง 1–99')));
                  return;
                }
                try {
                  await ApiService.updateOrderDetail(
                    orderId: orderId,
                    detailId: int.parse(item['orderdetail_id'].toString()),
                    menuId: menuId,
                    quantity: quantity,
                    selectedOptions: selectedOptionIds.entries.expand<Map<String, dynamic>>((entry) => entry.value.map((optionId) => <String, dynamic>{
                      'group_id': entry.key,
                      'option_id': optionId,
                    })).toList(),
                    note: noteController.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
    noteController.dispose();
    return saved;
  }

  Widget _editSection(String title, IconData icon, List<Widget> children) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 18, color: AppColors.orange), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  String _itemDescription(Map<String, dynamic> item) {
    final rawSelections = item['selected_options'];
    if (rawSelections != null) {
      try {
        final selections = rawSelections is String ? jsonDecode(rawSelections) as List<dynamic> : rawSelections as List<dynamic>;
        final labels = selections.map((entry) {
          final value = Map<String, dynamic>.from(entry as Map);
          final group = value['group_name']?.toString() ?? '';
          final option = value['option_name']?.toString() ?? '';
          return group.isEmpty ? option : '$group: $option';
        }).where((label) => label.isNotEmpty).toList();
        if (labels.isNotEmpty) return [...labels, if (item['note']?.toString().trim().isNotEmpty == true) 'หมายเหตุ: ${item['note']}'].join(' • ');
      } catch (_) {}
    }
    const spicy = {1: 'ไม่เผ็ด', 2: 'เผ็ดน้อย', 3: 'เผ็ดกลาง', 4: 'เผ็ดมาก'};
    const serving = {1: 'ทานที่ร้าน', 2: 'กลับบ้าน'};
    const rice = {1: 'ธรรมดา', 2: 'พิเศษ', 3: 'พิเศษ'};
    const egg = {1: 'ไม่เพิ่มไข่', 2: 'ไข่ดาว', 3: 'ไข่เจียว'};
    int value(String key) => int.tryParse(item[key]?.toString() ?? '') ?? 1;
    final note = item['note']?.toString().trim() ?? '';
    return [spicy[value('spicy_id')], rice[value('rice_id')], egg[value('egg_id')], serving[value('serving_id')], if (note.isNotEmpty) 'หมายเหตุ: $note'].whereType<String>().join(' • ');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('ประวัติการสั่งอาหาร')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final rows = snapshot.data!;
            if (rows.isEmpty) return const Center(child: Text('ยังไม่มีประวัติการสั่งอาหาร'));
            final inProgress = rows.where((row) => ['รอรับออร์เดอร์', 'กำลังทำ'].contains(row['order_status'])).toList();
            final completed = rows.where((row) => ['รอชำระเงิน', 'รอตรวจสอบการชำระ', 'ชำระเงินไม่ผ่าน', 'ชำระแล้ว'].contains(row['order_status'])).toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (inProgress.isNotEmpty) ...[
                    _sectionHeader('ออร์เดอร์ที่กำลังดำเนินการ', inProgress.length, Icons.restaurant_outlined),
                    ...inProgress.map(_orderCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    _sectionHeader('ประวัติออร์เดอร์ที่ทำเสร็จแล้ว', completed.length, Icons.receipt_long_outlined),
                    ...completed.map(_orderCard),
                  ],
                  if (inProgress.isEmpty && completed.isEmpty)
                    const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: Text('ยังไม่มีออร์เดอร์ที่กำลังดำเนินการหรือทำเสร็จแล้ว'))),
                ],
              ),
            );
          },
        ),
      );

  Widget _sectionHeader(String title, int count, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        child: Row(children: [
          Icon(icon, color: AppColors.orange, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          Text('$count รายการ', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        ]),
      );

  Widget _orderCard(Map<String, dynamic> row) {
    final status = row['order_status']?.toString() ?? 'รอรับออร์เดอร์';
    final orderId = int.parse(row['order_id'].toString());
    final payable = status == 'รอชำระเงิน' || status == 'ชำระเงินไม่ผ่าน';
    final editable = status == 'รอรับออร์เดอร์';
    return Card(
      child: ListTile(
        title: Text('ออร์เดอร์ #$orderId • ฿${row['total'] ?? 0}'),
        subtitle: Text('${row['order_date']}\nสถานะ: $status'),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (payable)
            IconButton(
              tooltip: 'ชำระเงิน',
              icon: const Icon(Icons.qr_code_2, color: AppColors.orange),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentQrPage(orderId: orderId))).then((_) => _refresh()),
            ),
          if (editable)
            PopupMenuButton<String>(
              tooltip: 'จัดการออร์เดอร์',
              onSelected: (action) {
                if (action == 'edit') _editOrder(orderId);
                if (action == 'cancel') _cancelOrder(row);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('แก้ไขรายละเอียดอาหาร')),
                PopupMenuItem(value: 'cancel', child: Text('ยกเลิกออร์เดอร์')),
              ],
            ),
        ]),
      ),
    );
  }
}
