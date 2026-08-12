import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/cart_service.dart';
import '../widgets/app_buttons.dart';
import 'home_shell.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String? reservationTable;

  const PaymentPage({
    super.key,
    required this.amount,
    this.reservationTable,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = 'PromptPay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _row(
                  'Reservation table',
                  widget.reservationTable ?? 'T004',
                ),
                const Divider(height: 22),
                _row(
                  'Amount',
                  '฿${widget.amount.toStringAsFixed(2)}',
                ),
                const Divider(height: 22),
                _row(
                  'Status',
                  'Pending',
                  valueColor: AppColors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _method(
            icon: Icons.qr_code_2,
            title: 'PromptPay',
            subtitle: 'Scan QR to pay',
            value: 'PromptPay',
          ),
          const SizedBox(height: 10),
          _method(
            icon: Icons.payments_outlined,
            title: 'Cash at restaurant',
            subtitle: 'Pay when you arrive',
            value: 'Cash',
          ),
          const SizedBox(height: 25),
          PrimaryButton(
            text: 'Confirm Payment',
            onPressed: () {
              CartService.instance.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmationPage(
                    table: widget.reservationTable ?? 'T004',
                    amount: widget.amount,
                  ),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _method({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = method == value;
    return InkWell(
      onTap: () => setState(() => method = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.orange
                : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 30),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? AppColors.orange
                  : Colors.grey,
            ),
          ],
        ),
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
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final String table;
  final double amount;

  const ConfirmationPage({
    super.key,
    required this.table,
    required this.amount,
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
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your table has been reserved successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                      _line('Table', table),
                      _line(
                        'Amount',
                        '฿${amount.toStringAsFixed(2)}',
                      ),
                      _line('Status', 'Paid'),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  text: 'Back to Home',
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

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

