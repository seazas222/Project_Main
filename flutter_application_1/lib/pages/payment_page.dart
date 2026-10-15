import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/current_user_service.dart';
import '../widgets/app_buttons.dart';
import 'home_shell.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final int? reservationId;
  final String? reservationTable;
  final int? tableId;

  const PaymentPage({
    super.key,
    required this.amount,
    this.reservationId,
    this.reservationTable,
    this.tableId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isSaving = false;

  int _spicyId(String value) {
    switch (value) {
      case 'ไม่เผ็ด':
        return 1;
      case 'เผ็ดน้อย':
        return 2;
      case 'เผ็ดปกติ':
      case 'เผ็ดกลาง':
        return 3;
      case 'เผ็ดมาก':
        return 4;
      default:
        return 1;
    }
  }

  int _servingId(String value) {
    return value == 'กลับบ้าน' ? 2 : 1;
  }

  int _riceId(String value) {
    switch (value) {
      case 'พิเศษ +10':
        return 2;
      case 'พิเศษ +20':
        return 3;
      default:
        return 1;
    }
  }

  int _eggId(String value) {
    switch (value) {
      case 'ไข่ดาว +10':
        return 2;
      case 'ไข่เจียว +15':
        return 3;
      default:
        return 1;
    }
  }

  Future<void> _confirmPayment() async {
    if (_isSaving) return;

    final cart = CartService.instance;
    final user = CurrentUserService.instance.user;

    if (user == null) {
      _showError('กรุณาเข้าสู่ระบบก่อน');
      return;
    }

    if (cart.items.isEmpty) {
      _showError('ยังไม่มีรายการอาหารในตะกร้า');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    int? createdOrderId;
    try {

      final orderId = await ApiService.createOrder(
        reservationId: widget.reservationId,
        tableId: widget.tableId,
      );
      createdOrderId = orderId;

      for (final item in cart.items) {
        final menuId = int.tryParse(item.food.id);

        if (menuId == null) {
          throw Exception(
            'menu_id ของ ${item.food.name} ไม่ถูกต้อง',
          );
        }

        await ApiService.createOrderDetail(
          orderId: orderId,
          menuId: menuId,
          quantity: item.quantity,
          price: item.unitPrice,
          spicyId: _spicyId(item.spicy),
          servingId: _servingId(item.serving),
          riceId: _riceId(item.size),
          eggId: _eggId(item.egg),
          selectedOptions: item.selectedOptions,
          note: item.note.trim().isEmpty
              ? null
              : item.note.trim(),
        );
      }

      if (!mounted) return;

      final table = widget.reservationTable ?? (widget.tableId == null ? '-' : 'โต๊ะหน้าร้าน');
      final amount = cart.subtotal;

      cart.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationPage(
            table: table,
            amount: amount,
            orderId: orderId,
            hasOrder: true,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      if (createdOrderId != null) {
        try {
          await ApiService.cancelOrder(createdOrderId);
        } catch (_) {
          // Keep the original order creation error visible; the order may
          // already have progressed on the restaurant side.
        }
      }

      setState(() {
        _isSaving = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;
    final displayAmount = cart.items.isEmpty
        ? widget.amount
        : cart.subtotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ยืนยันรายการอาหาร'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
        _row(
          'โต๊ะ',
                  widget.reservationTable ?? (widget.tableId == null ? '-' : 'โต๊ะหน้าร้าน'),
                ),
                const Divider(height: 22),
                _row(
                  'ยอดค่าอาหาร',
                  '฿${displayAmount.toStringAsFixed(2)}',
                ),
                const Divider(height: 22),
                _row(
                  'สถานะ',
                  'รอรับออร์เดอร์',
                  valueColor: AppColors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Card(
            child: ListTile(
              leading: Icon(Icons.qr_code_2, color: AppColors.orange),
              title: Text('ชำระหลังอาหารทำเสร็จ'),
              subtitle: Text('ระบบจะแจ้งเตือนและแสดง QR PromptPay พร้อมยอดและรายการอาหาร'),
            ),
          ),

          const SizedBox(height: 28),

          PrimaryButton(
            text: _isSaving
                ? 'กำลังบันทึก...'
                : 'ยืนยันการสั่งอาหาร',
            onPressed: _isSaving ? null : _confirmPayment,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color valueColor = AppColors.text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final String table;
  final double amount;
  final int orderId;
  final bool hasOrder;

  const ConfirmationPage({
    super.key,
    required this.table,
    required this.amount,
    this.orderId = 0,
    this.hasOrder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F7EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 55,
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  hasOrder
                      ? 'รับออร์เดอร์แล้ว!'
                      : 'จองโต๊ะสำเร็จ!',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  hasOrder
                      ? 'ร้านได้รับรายการอาหารแล้ว จะแจ้งเมื่ออาหารทำเสร็จ'
                      : 'โต๊ะของคุณถูกจองเรียบร้อยแล้ว',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _line('โต๊ะ', table),

                      if (hasOrder)
                        _line(
                          'Order ID',
                          '#$orderId',
                        ),

                      _line(
                        'ยอดค่าอาหาร',
                        '฿${amount.toStringAsFixed(2)}',
                      ),

                      _line(
                        'สถานะ',
                        hasOrder ? 'รอรับออร์เดอร์' : 'จองแล้ว',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                PrimaryButton(
                  text: 'กลับหน้าหลัก',
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeShell(),
                    ),
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
