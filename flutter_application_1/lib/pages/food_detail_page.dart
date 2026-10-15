import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/food.dart';
import '../services/cart_service.dart';
import '../widgets/app_buttons.dart';

import 'cart_page.dart';

class FoodDetailPage extends StatefulWidget {

  final Food food;

  final int? reservationId;

  final String reservationTable;
  final int? tableId;

  const FoodDetailPage({
    super.key,

    required this.food,

    this.reservationId,

    required this.reservationTable,
    this.tableId,
  });

  @override
  State<FoodDetailPage> createState() =>
      _FoodDetailPageState();
}

class _FoodDetailPageState
    extends State<FoodDetailPage> {

  int quantity = 1;

  String spicy = 'ไม่เผ็ด';

  String size = 'ธรรมดา';

  String egg = 'ไม่เพิ่ม';

  String serving = 'ทานที่ร้าน';

  final Map<String, List<String>> _selectedOptionIds = <String, List<String>>{};

  final TextEditingController noteController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final group in widget.food.optionGroups) {
      final groupId = group['id']?.toString() ?? '';
      final options = group['options'] as List<dynamic>? ?? [];
      if (groupId.isNotEmpty && options.isNotEmpty && group['required'] != false) {
        for (final rawOption in options) {
          final option = Map<String, dynamic>.from(rawOption as Map);
          if (option['available'] != false && option['sold_out'] != true) {
            _selectedOptionIds[groupId] = [option['id'].toString()];
            break;
          }
        }
      }
    }
  }

  double get extras {
    return _selectedOptionSnapshot.fold<double>(
      0,
      (total, option) => total + (double.tryParse(option['extra_price'].toString()) ?? 0),
    );
  }

  List<Map<String, dynamic>> get _selectedOptionSnapshot {
    final selected = <Map<String, dynamic>>[];
    for (final group in widget.food.optionGroups) {
      final groupId = group['id']?.toString() ?? '';
      final selectedIds = _selectedOptionIds[groupId] ?? const <String>[];
      for (final rawOption in group['options'] as List<dynamic>? ?? []) {
        final option = Map<String, dynamic>.from(rawOption as Map);
        if (selectedIds.contains(option['id']?.toString())) {
          selected.add({
            'group_id': groupId,
            'group_name': group['name']?.toString() ?? '',
            'option_id': option['id']?.toString() ?? '',
            'option_name': option['name']?.toString() ?? '',
            'extra_price': double.tryParse(option['extra_price']?.toString() ?? '') ?? 0,
          });
        }
      }
    }
    return selected;
  }

  Widget _buildOptionGroup(Map<String, dynamic> group) {
    final groupId = group['id']?.toString() ?? '';
    final options = (group['options'] as List<dynamic>? ?? [])
        .map((option) => Map<String, dynamic>.from(option as Map))
        .toList();
    final maxSelect = int.tryParse(group['max_select']?.toString() ?? '1') ?? 1;
    final selected = _selectedOptionIds[groupId] ?? const <String>[];
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(group['name']?.toString() ?? 'ตัวเลือก', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 5),
        Wrap(spacing: 7, runSpacing: 2, children: options.map((option) {
          final optionId = option['id']?.toString() ?? '';
          final available = option['available'] != false && option['sold_out'] != true;
          final price = double.tryParse(option['extra_price']?.toString() ?? '') ?? 0;
          final label = '${option['name']}${price > 0 ? ' +฿${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}' : ''}${available ? '' : ' • หมด'}';
          final isSelected = selected.contains(optionId);
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: available ? (_) => setState(() {
              if (maxSelect == 1) {
                _selectedOptionIds[groupId] = [optionId];
              } else if (isSelected) {
                _selectedOptionIds[groupId] = selected.where((id) => id != optionId).toList();
              } else if (selected.length < maxSelect) {
                _selectedOptionIds[groupId] = [...selected, optionId];
              }
            }) : null,
          );
        }).toList()),
      ]),
    );
  }

  double get base {
    return double.tryParse(
          widget.food.price
              .replaceAll('฿', '')
              .replaceAll(',', '')
              .trim(),
        ) ??
        0;
  }

  double get unitPrice {
    return base + extras;
  }

  double get total {
    return unitPrice * quantity;
  }

  bool get isDrink => widget.food.category == 'น้ำดื่ม';

  @override
  void dispose() {
    noteController.dispose();

    super.dispose();
  }

  void _openCart() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CartPage(
          reservationId: widget.reservationId,

          reservationTable:
              widget.reservationTable,
          tableId: widget.tableId,
        ),
      ),
    );
  }

  void _addToCart() {

    for (final group in widget.food.optionGroups) {
      final groupId = group['id']?.toString() ?? '';
      final chosen = _selectedOptionIds[groupId] ?? const <String>[];
      if (group['required'] != false && chosen.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กรุณาเลือก${group['name']} (ตัวเลือกอาจหมดแล้ว)')));
        return;
      }
    }

    final note =
        noteController.text.trim();

    for (int i = 0;
        i < quantity;
        i++) {
      CartService.instance.add(
        widget.food,

        spicy: spicy,

        size: size,

        egg: egg,

        serving: serving,

        extraPrice: extras,

        selectedOptions: _selectedOptionSnapshot,

        note: note,
      );
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${widget.food.name} เพิ่มลงตะกร้าแล้ว',
        ),

        duration:
            const Duration(
          milliseconds: 900,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        title: Text(
          isDrink ? 'รายละเอียดเครื่องดื่ม' : 'รายละเอียดอาหาร',
        ),

        actions: [
          IconButton(
            onPressed:
                _openCart,

            icon:
                const Icon(
              Icons
                  .shopping_bag_outlined,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child:
                ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),

              children: [

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  child: widget.food.imageUrl != null
                      ? Image.network(widget.food.imageUrl!, height: 240, fit: BoxFit.cover, errorBuilder: (_, _, _) => Image.asset(widget.food.imageAsset, height: 240, fit: BoxFit.cover))
                      : Image.asset(
                    widget.food.imageAsset,

                    height:
                        240,

                    fit:
                        BoxFit.cover,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  widget.food.name,

                  style:
                      const TextStyle(
                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Row(
                  children: [
                    Text(isDrink ? 'ราคาเครื่องดื่มพื้นฐาน' : 'ราคาจานพื้นฐาน', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    const Spacer(),

                    Text(
                      '฿${base.toStringAsFixed(0)}',

                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .orange,

                        fontWeight:
                            FontWeight
                                .w700,

                        fontSize:
                            18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                const SizedBox(
                  height: 20,
                ),

                ...widget.food.optionGroups.map(_buildOptionGroup),

                const Text(
                  'หมายเหตุ',

                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w500,

                    fontSize:
                        13,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                TextField(
                  controller:
                      noteController,

                  maxLines:
                      2,

                  decoration:
                      InputDecoration(
                    hintText:
                        isDrink ? 'เช่น หวานน้อย ไม่ใส่น้ำแข็ง' : 'เช่น ไม่ใส่ผัก',

                    filled:
                        true,

                    fillColor:
                        AppColors
                            .background,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),

                      borderSide:
                          BorderSide
                              .none,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .all(
                    15,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .background,

                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),

                  child:
                      Column(
                    children: [
                      _priceRow(
                        isDrink ? 'ราคาเครื่องดื่ม' : 'ราคาอาหาร',

                        '฿${base.toStringAsFixed(0)}',
                      ),

                      if (extras >
                          0)
                        _priceRow(
                          'ราคาเพิ่มเติม',

                          '฿${extras.toStringAsFixed(0)}',
                        ),

                      _priceRow(
                        isDrink ? 'ราคาต่อหน่วย' : 'ราคาต่อจาน',

                        '฿${unitPrice.toStringAsFixed(0)}',
                      ),

                      _priceRow(
                        'จำนวน',

                        isDrink ? '$quantity หน่วย' : '$quantity จาน',
                      ),

                      const Divider(),

                      _priceRow(
                        'รวมทั้งหมด',

                        '฿${total.toStringAsFixed(0)}',

                        isTotal:
                            true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              15,
            ),

            decoration:
                const BoxDecoration(
              color:
                  Colors.white,

              boxShadow: [
                BoxShadow(
                  color:
                      Color(
                    0x15000000,
                  ),

                  blurRadius:
                      8,

                  offset:
                      Offset(
                    0,
                    -2,
                  ),
                ),
              ],
            ),

            child:
                Row(
              children: [

                Container(
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .background,

                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),

                  child:
                      Row(
                    children: [
                      IconButton(
                        onPressed:
                            () {
                          if (quantity >
                              1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },

                        icon:
                            const Icon(
                          Icons.remove,

                          size:
                              18,
                        ),
                      ),

                      Text(
                        '$quantity',

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            () {
                          setState(() {
                            quantity++;
                          });
                        },

                        icon:
                            const Icon(
                          Icons.add,

                          size:
                              18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      PrimaryButton(
                    text:
                        'เพิ่มลงตะกร้า • ฿${total.toStringAsFixed(0)}',

                    onPressed:
                        _addToCart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool isTotal =
        false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),

      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          Text(
            label,

            style:
                TextStyle(
              color:
                  isTotal
                      ? AppColors.text
                      : AppColors.grey,

              fontWeight:
                  isTotal
                      ? FontWeight.w700
                      : FontWeight.w400,
            ),
          ),

          Text(
            value,

            style:
                TextStyle(
              color:
                  isTotal
                      ? AppColors.orange
                      : AppColors.text,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
