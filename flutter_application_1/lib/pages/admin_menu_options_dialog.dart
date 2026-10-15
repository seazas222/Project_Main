import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AdminMenuOptionsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialGroups;

  const AdminMenuOptionsDialog({super.key, required this.initialGroups});

  @override
  State<AdminMenuOptionsDialog> createState() => _AdminMenuOptionsDialogState();
}

class _AdminMenuOptionsDialogState extends State<AdminMenuOptionsDialog> {
  late final List<Map<String, dynamic>> groups;

  @override
  void initState() {
    super.initState();
    groups = widget.initialGroups.map((group) => {
      ...group,
      'options': (group['options'] as List<dynamic>? ?? [])
          .map((option) => Map<String, dynamic>.from(option as Map))
          .toList(),
    }).toList();
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<Map<String, dynamic>?> _editGroup([Map<String, dynamic>? current]) async {
    final name = TextEditingController(text: current?['name']?.toString() ?? '');
    bool required = current?['required'] != false;
    int maxSelect = int.tryParse(current?['max_select']?.toString() ?? '1') ?? 1;
    String? error;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(current == null ? 'เพิ่มหัวข้อเลือก' : 'แก้ไขหัวข้อ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'ชื่อหัวข้อ', hintText: 'เช่น น้ำซุป, ระดับความเผ็ด')),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: required, title: const Text('ต้องเลือกหัวข้อนี้'), onChanged: (value) => setDialogState(() => required = value ?? true)),
          DropdownButtonFormField<int>(
            initialValue: maxSelect,
            decoration: const InputDecoration(labelText: 'เลือกได้สูงสุด'),
            items: [1, 2, 3, 4, 5].map((value) => DropdownMenuItem(value: value, child: Text('$value รายการ'))).toList(),
            onChanged: (value) { if (value != null) setDialogState(() => maxSelect = value); },
          ),
          if (error != null) Align(alignment: Alignment.centerLeft, child: Text(error!, style: const TextStyle(color: AppColors.danger))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('กลับ')),
          FilledButton(onPressed: () {
            if (name.text.trim().isEmpty) {
              setDialogState(() => error = 'กรุณาระบุชื่อหัวข้อ');
              return;
            }
            Navigator.pop(dialogContext, {
              'id': current?['id'] ?? _id('group'),
              'name': name.text.trim(),
              'required': required,
              'max_select': maxSelect,
              'options': current?['options'] ?? <Map<String, dynamic>>[],
            });
          }, child: const Text('บันทึก')),
        ],
      )),
    );
    name.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _editOption([Map<String, dynamic>? current]) async {
    final name = TextEditingController(text: current?['name']?.toString() ?? '');
    final price = TextEditingController(text: current?['extra_price']?.toString() ?? '0');
    bool available = current?['available'] != false && current?['sold_out'] != true;
    String? error;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(current == null ? 'เพิ่มตัวเลือก' : 'แก้ไขตัวเลือก'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'ชื่อย่อย', hintText: 'เช่น เผ็ดน้อย, น้ำซุปใส')),
          TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'ราคาเพิ่ม', prefixText: '฿')),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: available, title: const Text('มีวัตถุดิบ / พร้อมขาย'), subtitle: Text(available ? 'ลูกค้าเลือกตัวเลือกนี้ได้' : 'แสดงว่าหมดและปิดการเลือก'), onChanged: (value) => setDialogState(() => available = value)),
          if (error != null) Align(alignment: Alignment.centerLeft, child: Text(error!, style: const TextStyle(color: AppColors.danger))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('กลับ')),
          FilledButton(onPressed: () {
            final parsedPrice = double.tryParse(price.text.trim());
            if (name.text.trim().isEmpty || parsedPrice == null || parsedPrice < 0) {
              setDialogState(() => error = 'กรอกชื่อตัวเลือกและราคาให้ถูกต้อง');
              return;
            }
            Navigator.pop(dialogContext, {
              'id': current?['id'] ?? _id('option'),
              'name': name.text.trim(),
              'extra_price': parsedPrice,
              'available': available,
            });
          }, child: const Text('บันทึก')),
        ],
      )),
    );
    name.dispose();
    price.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: SizedBox(
          width: 560,
          height: 640,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(children: [
                const Expanded(child: Text('หัวข้อและตัวเลือกของเมนู', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft, child: Text('เพิ่ม ลบ หรือแก้ชื่อหัวข้อและตัวเลือกย่อยได้ เช่น เพิ่มน้ำซุป หรือปรับระดับความเผ็ด', style: TextStyle(color: AppColors.grey))),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: TextButton.icon(
                  onPressed: () async {
                    final group = await _editGroup();
                    if (group != null && mounted) setState(() => groups.add(group));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มหัวข้อ'),
                ),
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? const Center(child: Text('ยังไม่มีหัวข้อให้ลูกค้าเลือก'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: groups.map((group) {
                        final options = group['options'] as List<Map<String, dynamic>>;
                        return Card(
                          child: ExpansionTile(
                            key: PageStorageKey('menu-option-group-${group['id']}'),
                            title: Text(group['name'].toString()),
                            subtitle: Text('${group['required'] == true ? 'ต้องเลือก' : 'ไม่บังคับ'} • เลือกได้สูงสุด ${group['max_select']}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  final updated = await _editGroup(group);
                                  if (updated != null && mounted) setState(() { group..['name'] = updated['name']..['required'] = updated['required']..['max_select'] = updated['max_select']; });
                                } else if (action == 'delete' && mounted) {
                                  setState(() => groups.remove(group));
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('แก้ไขหัวข้อ')),
                                PopupMenuItem(value: 'delete', child: Text('ลบหัวข้อ')),
                              ],
                            ),
                            children: [
                              ...options.map((option) => ListTile(
                                dense: true,
                                title: Text(option['name'].toString()),
                                subtitle: Text('${option['available'] == false || option['sold_out'] == true ? 'หมด • ' : ''}ราคาเพิ่ม ฿${option['extra_price']}'),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(tooltip: 'แก้ไขตัวเลือก', icon: const Icon(Icons.edit_outlined), onPressed: () async {
                                    final updated = await _editOption(option);
                                    if (updated != null && mounted) setState(() { option..['name'] = updated['name']..['extra_price'] = updated['extra_price']..['available'] = updated['available']; });
                                  }),
                                  IconButton(tooltip: 'ลบตัวเลือก', icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => options.remove(option))),
                                ]),
                              )),
                              TextButton.icon(onPressed: () async {
                                final option = await _editOption();
                                if (option != null && mounted) setState(() => options.add(option));
                              }, icon: const Icon(Icons.add), label: const Text('เพิ่มตัวเลือกย่อย')),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {
                  final invalid = groups.any((group) => group['required'] != false && (group['options'] as List).isEmpty);
                  if (invalid) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('หัวข้อที่บังคับเลือกต้องมีตัวเลือกอย่างน้อย 1 รายการ')));
                    return;
                  }
                  Navigator.pop(context, groups);
                }, child: const Text('บันทึกตัวเลือก')),
              ]),
            ),
          ]),
        ),
      );
}

List<Map<String, dynamic>> defaultMenuOptionGroups() => [
      {
        'id': 'spicy', 'name': 'ระดับความเผ็ด', 'required': true, 'max_select': 1,
        'options': [
          {'id': 'spicy-1', 'name': 'ไม่เผ็ด', 'extra_price': 0},
          {'id': 'spicy-2', 'name': 'เผ็ดกลาง', 'extra_price': 0},
          {'id': 'spicy-3', 'name': 'เผ็ดมาก', 'extra_price': 0},
        ],
      },
      {
        'id': 'size', 'name': 'เลือกขนาด', 'required': true, 'max_select': 1,
        'options': [
          {'id': 'size-1', 'name': 'ธรรมดา', 'extra_price': 0},
          {'id': 'size-2', 'name': 'พิเศษ', 'extra_price': 10},
          {'id': 'size-3', 'name': 'พิเศษมาก', 'extra_price': 20},
        ],
      },
      {
        'id': 'egg', 'name': 'ไข่', 'required': true, 'max_select': 1,
        'options': [
          {'id': 'egg-1', 'name': 'ไม่เพิ่ม', 'extra_price': 0},
          {'id': 'egg-2', 'name': 'ไข่ดาว', 'extra_price': 10},
          {'id': 'egg-3', 'name': 'ไข่เจียว', 'extra_price': 15},
        ],
      },
      {
        'id': 'serving', 'name': 'รูปแบบการรับอาหาร', 'required': true, 'max_select': 1,
        'options': [
          {'id': 'serving-1', 'name': 'ทานที่ร้าน', 'extra_price': 0},
          {'id': 'serving-2', 'name': 'กลับบ้าน', 'extra_price': 0},
        ],
      },
    ];

Map<String, dynamic> defaultMenuProteinGroup() => {
      'id': 'protein',
      'name': 'เนื้อ',
      'required': true,
      'max_select': 5,
      'options': [
        {'id': 'protein-pork', 'name': 'หมู', 'extra_price': 20, 'available': true},
        {'id': 'protein-minced-pork', 'name': 'หมูสับ', 'extra_price': 20, 'available': true},
        {'id': 'protein-chicken', 'name': 'ไก่', 'extra_price': 20, 'available': true},
        {'id': 'protein-crispy-pork', 'name': 'หมูกรอบ', 'extra_price': 35, 'available': true},
        {'id': 'protein-shrimp', 'name': 'กุ้ง', 'extra_price': 35, 'available': true},
        {'id': 'protein-seafood', 'name': 'ทะเล', 'extra_price': 40, 'available': true},
      ],
    };
