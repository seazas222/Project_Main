import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/app_buttons.dart';

import 'payment_page.dart';

class CartPage extends StatelessWidget {

  final int? reservationId;

  final String reservationTable;
  final int? tableId;

  const CartPage({
    super.key,

    this.reservationId,

    required this.reservationTable,
    this.tableId,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation:
          CartService.instance,

      builder: (
        context,
        _,
      ) {
        final cart =
            CartService.instance;

        final subtotal =
            cart.subtotal;

        final total =
            subtotal;

        return Scaffold(
          backgroundColor:
              AppColors.background,

          appBar: AppBar(
            title:
                const Text(
              'รายการอาหาร',
            ),

            actions: [
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed:
                      cart.clear,

                  child:
                      const Text(
                    'ล้างทั้งหมด',

                    style:
                        TextStyle(
                      color:
                          AppColors
                              .orange,
                    ),
                  ),
                ),
            ],
          ),

          body: cart.items.isEmpty
              ? const _EmptyCart()
              : ListView(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),

                  children: [

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        15,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),

                        border:
                            Border.all(
                          color:
                              AppColors
                                  .border,
                        ),
                      ),

                      child:
                          Row(
                        children: [
                          const Icon(
                            Icons
                                .table_restaurant_outlined,

                            color:
                                AppColors
                                    .orange,

                            size:
                                22,
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          const Text(
                            'โต๊ะ',

                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .grey,

                              fontSize:
                                  12,
                            ),
                          ),

                          const SizedBox(
                            width:
                                5,
                          ),

                          Text(
                            reservationTable,

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w700,

                              fontSize:
                                  14,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            reservationId == null ? 'สั่งที่ร้าน' : 'การจอง #$reservationId',

                            style:
                                const TextStyle(
                              color:
                                  AppColors
                                      .grey,

                              fontSize:
                                  10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    ...cart.items.map(
                      (item) =>
                          Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom:
                              12,
                        ),

                        child:
                            Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            10,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          child:
                              Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),

                                child:
                                    Image.asset(
                                  item.food
                                      .imageAsset,

                                  width:
                                      78,

                                  height:
                                      78,

                                  fit:
                                      BoxFit.cover,
                                ),
                              ),

                              const SizedBox(
                                width:
                                    12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      item.food
                                          .name,

                                      maxLines:
                                          2,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            13,

                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),

                                    TextButton.icon(
                                      onPressed: () => _editCartItem(context, item),
                                      icon: const Icon(Icons.edit_outlined, size: 15),
                                      label: const Text('แก้ไขรายการ'),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                    ),

                                    const SizedBox(
                                      height:
                                          5,
                                    ),

                                    Text(
                                      item.selectedOptions.isNotEmpty
                                          ? item.selectedOptions.map((option) => option['option_name']?.toString() ?? '').where((name) => name.isNotEmpty).join(' • ')
                                          : '${item.spicy} • ${item.size} • ${item.egg}',

                                      maxLines:
                                          2,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        color:
                                            AppColors
                                                .grey,

                                        fontSize:
                                            10,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          3,
                                    ),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .restaurant_outlined,

                                          size:
                                              13,

                                          color:
                                              AppColors
                                                  .orange,
                                        ),

                                        const SizedBox(
                                          width:
                                              4,
                                        ),

                                        Text(
                                          item
                                              .serving,

                                          style:
                                              const TextStyle(
                                            color:
                                                AppColors
                                                    .orange,

                                            fontSize:
                                                10,

                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (item
                                        .note
                                        .trim()
                                        .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top:
                                              4,
                                        ),

                                        child:
                                            Text(
                                          'หมายเหตุ: '
                                          '${item.note}',

                                          maxLines:
                                              2,

                                          overflow:
                                              TextOverflow
                                                  .ellipsis,

                                          style:
                                              const TextStyle(
                                            color:
                                                AppColors
                                                    .grey,

                                            fontSize:
                                                10,

                                            fontStyle:
                                                FontStyle
                                                    .italic,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(
                                      height:
                                          6,
                                    ),

                                    Text(
                                      '฿${item.unitPrice.toStringAsFixed(0)} / ${item.food.category == 'น้ำดื่ม' ? 'หน่วย' : 'จาน'}',

                                      style:
                                          const TextStyle(
                                        color:
                                            AppColors
                                                .orange,

                                        fontWeight:
                                            FontWeight
                                                .w600,

                                        fontSize:
                                            12,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          7,
                                    ),

                                    Row(
                                      children: [
                                        _circle(
                                          icon:
                                              Icons
                                                  .remove,

                                          onTap:
                                              () {
                                            cart
                                                .decrement(
                                              item,
                                            );
                                          },
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                10,
                                          ),

                                          child:
                                              Text(
                                            '${item.quantity}',

                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                        ),

                                        _circle(
                                          icon:
                                              Icons
                                                  .add,

                                          onTap:
                                              () {
                                            cart
                                                .increment(
                                              item,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width:
                                    8,
                              ),

                              Text(
                                '฿${item.total.toStringAsFixed(0)}',

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,

                                  fontSize:
                                      14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),

                      child:
                          Column(
                        children: [
                          _summary(
                            'ยอดรวมสินค้า',

                            '฿${subtotal.toStringAsFixed(0)}',
                          ),

                          const Divider(
                            height:
                                22,
                          ),

                          _summary(
                            'ยอดรวมทั้งหมด',

                            '฿${total.toStringAsFixed(0)}',

                            bold:
                                true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    PrimaryButton(
                      text:
                          'ชำระเงิน • ฿${total.toStringAsFixed(0)}',

                      onPressed:
                          cart.items.isEmpty
                              ? null
                              : () {
                                  Navigator
                                      .push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              PaymentPage(
                                        amount:
                                            total,

                                        reservationId:
                                            reservationId,

                                        reservationTable:
                                            reservationTable,
                                        tableId:
                                            tableId,
                                      ),
                                    ),
                                  );
                                },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

Widget _summary(
  String label,
  String value, {
  bool bold = false,
}) {
  return Row(
    mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,

    children: [
      Text(
        label,

        style:
            TextStyle(
          fontSize:
              bold ? 16 : 13,

          fontWeight:
              bold
                  ? FontWeight.w600
                  : FontWeight.w400,
        ),
      ),

      Text(
        value,

        style:
            TextStyle(
          fontSize:
              bold ? 18 : 13,

          fontWeight:
              bold
                  ? FontWeight.w700
                  : FontWeight.w500,

          color:
              bold
                  ? AppColors
                      .orange
                  : AppColors
                      .text,
        ),
      ),
    ],
  );
}

Widget _circle({
  required IconData icon,

  required VoidCallback onTap,
}) {
  return InkWell(
    onTap:
        onTap,

    borderRadius:
        BorderRadius
            .circular(
      15,
    ),

    child:
        Container(
      width:
          28,

      height:
          28,

      decoration:
          const BoxDecoration(
        color:
            AppColors
                .orangeLight,

        shape:
            BoxShape
                .circle,
      ),

      child:
          Icon(
        icon,

        size:
            15,

        color:
            AppColors
                .orange,
      ),
    ),
  );
}

Future<void> _editCartItem(BuildContext context, CartItem item) async {
  final groups = item.food.optionGroups;
  final selected = <String, List<String>>{};
  for (final choice in item.selectedOptions) {
    final groupId = choice['group_id']?.toString() ?? '';
    if (groupId.isNotEmpty) (selected[groupId] ??= []).add(choice['option_id']?.toString() ?? '');
  }
  for (final rawGroup in groups) {
    final group = Map<String, dynamic>.from(rawGroup);
    final groupId = group['id']?.toString() ?? '';
    if ((selected[groupId] ?? []).isNotEmpty || group['required'] == false) continue;
    for (final rawOption in group['options'] as List<dynamic>? ?? []) {
      final option = Map<String, dynamic>.from(rawOption as Map);
      if (option['available'] != false && option['sold_out'] != true) {
        selected[groupId] = [option['id'].toString()];
        break;
      }
    }
  }
  final note = TextEditingController(text: item.note);
  await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
    title: Text('แก้ไข ${item.food.name}'),
    content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      ...groups.map((rawGroup) {
        final group = Map<String, dynamic>.from(rawGroup);
        final groupId = group['id']?.toString() ?? '';
        final options = (group['options'] as List<dynamic>? ?? []).map((raw) => Map<String, dynamic>.from(raw as Map)).toList();
        final maxSelect = int.tryParse(group['max_select']?.toString() ?? '1') ?? 1;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(group['name']?.toString() ?? 'ตัวเลือก', style: const TextStyle(fontWeight: FontWeight.w600)),
          Wrap(spacing: 6, children: options.map((option) {
            final optionId = option['id']?.toString() ?? '';
            final available = option['available'] != false && option['sold_out'] != true;
            final chosen = (selected[groupId] ?? []).contains(optionId);
            final extra = double.tryParse(option['extra_price']?.toString() ?? '') ?? 0;
            return ChoiceChip(label: Text('${option['name']}${available ? '' : ' • หมด'}${extra > 0 ? ' +฿${extra.toStringAsFixed(0)}' : ''}'), selected: chosen, onSelected: !available ? null : (_) => setDialogState(() {
              if (maxSelect == 1) {
                selected[groupId] = [optionId];
              } else if (chosen) {
                selected[groupId] = (selected[groupId] ?? []).where((id) => id != optionId).toList();
              } else if ((selected[groupId] ?? []).length < maxSelect) {
                selected[groupId] = [...(selected[groupId] ?? []), optionId];
              }
            }));
          }).toList()),
        ]));
      }),
      TextField(controller: note, maxLength: 500, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
      FilledButton(onPressed: () {
        final snapshot = <Map<String, dynamic>>[];
        double extraPrice = 0;
        for (final rawGroup in groups) {
          final group = Map<String, dynamic>.from(rawGroup);
          final groupId = group['id']?.toString() ?? '';
          final chosen = selected[groupId] ?? [];
          if (group['required'] != false && chosen.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กรุณาเลือก${group['name']}')));
            return;
          }
          final availableChosen = (group['options'] as List<dynamic>? ?? []).where((raw) {
            final option = Map<String, dynamic>.from(raw as Map);
            return chosen.contains(option['id']?.toString()) && option['available'] != false && option['sold_out'] != true;
          }).length;
          if (group['required'] != false && availableChosen == 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ตัวเลือกในหัวข้อ${group['name']}หมดแล้ว กรุณาเลือกใหม่')));
            return;
          }
          for (final rawOption in group['options'] as List<dynamic>? ?? []) {
            final option = Map<String, dynamic>.from(rawOption as Map);
            if (!chosen.contains(option['id']?.toString())) continue;
            if (option['available'] == false || option['sold_out'] == true) continue;
            final price = double.tryParse(option['extra_price']?.toString() ?? '') ?? 0;
            extraPrice += price;
            snapshot.add({'group_id': groupId, 'group_name': group['name']?.toString() ?? '', 'option_id': option['id']?.toString() ?? '', 'option_name': option['name']?.toString() ?? '', 'extra_price': price});
          }
        }
        CartService.instance.replaceItem(item, CartItem(food: item.food, quantity: item.quantity, spicy: item.spicy, size: item.size, egg: item.egg, serving: item.serving, note: note.text.trim(), extraPrice: extraPrice, selectedOptions: snapshot));
        Navigator.pop(dialogContext);
      }, child: const Text('บันทึก')),
    ],
  )));
  note.dispose();
}

class _EmptyCart
    extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width:
                80,

            height:
                80,

            decoration:
                const BoxDecoration(
              color:
                  AppColors
                      .orangeLight,

              shape:
                  BoxShape
                      .circle,
            ),

            child:
                const Icon(
              Icons
                  .shopping_bag_outlined,

              color:
                  AppColors
                      .orange,

              size:
                  38,
            ),
          ),

          const SizedBox(
            height:
                14,
          ),

          const Text(
            'ยังไม่มีรายการอาหาร',

            style:
                TextStyle(
              fontSize:
                  18,

              fontWeight:
                  FontWeight
                      .w600,
            ),
          ),

          const SizedBox(
            height:
                5,
          ),

          const Text(
            'กรุณาเพิ่มเมนูอาหารก่อน',

            style:
                TextStyle(
              color:
                  AppColors
                      .grey,
            ),
          ),
        ],
      ),
    );
  }
}
