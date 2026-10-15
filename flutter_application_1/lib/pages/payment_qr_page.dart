import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

class PaymentQrPage extends StatefulWidget {
  final int orderId;
  const PaymentQrPage({super.key, required this.orderId});

  @override
  State<PaymentQrPage> createState() => _PaymentQrPageState();
}

class _PaymentQrPageState extends State<PaymentQrPage> {
  late Future<Map<String, dynamic>> qrFuture;
  Map<String, dynamic>? payment;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    qrFuture = ApiService.getPaymentQr(widget.orderId);
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    try {
      final result = await ApiService.getPaymentStatus(widget.orderId);
      if (mounted) setState(() => payment = result);
    } catch (_) {}
  }

  Future<void> _sendSlip() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => sending = true);
    try {
      final bytes = await image.readAsBytes();
      final mime = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final payload = 'data:image/$mime;base64,${base64Encode(bytes)}';
      await ApiService.submitPaymentSlip(widget.orderId, payload);
      await _loadPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งสลิปแล้ว รอผู้ดูแลตรวจสอบ')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('ชำระออร์เดอร์ #${widget.orderId}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: qrFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            final message = snapshot.error.toString().replaceFirst('Exception: ', '');
            final missingPromptPay = message.contains('PROMPTPAY_ID');
            final paymentStatus = payment?['payment_status_id']?.toString();
            final waitingReview = paymentStatus == '3';
            final alreadyPaid = paymentStatus == '1' || message.contains('ชำระเงินแล้ว');
            final title = alreadyPaid
                ? 'ยืนยันการชำระเงินแล้ว'
                : waitingReview
                    ? 'ร้านกำลังตรวจสอบสลิป'
                    : missingPromptPay
                        ? 'ร้านยังตั้งค่ารับ PromptPay ไม่ครบ'
                        : 'ยังสร้าง QR ชำระเงินไม่ได้';
            return ListView(padding: const EdgeInsets.all(20), children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(children: [
                  Icon(alreadyPaid ? Icons.check_circle_outline : waitingReview ? Icons.receipt_long_outlined : missingPromptPay ? Icons.storefront_outlined : Icons.hourglass_top_rounded, size: 48, color: AppColors.orange),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!alreadyPaid) ...[
                    const SizedBox(height: 8),
                    Text(
                      waitingReview
                          ? 'ได้รับสลิปแล้ว ไม่ต้องส่งซ้ำ กรุณารอร้านตรวจสอบ'
                          : missingPromptPay
                              ? 'แจ้งผู้ดูแลร้านให้ตั้งค่าบัญชี PromptPay ในหน้าจัดการร้าน เป็นเบอร์โทร 10 หลักหรือเลขประจำตัว 13 หลัก'
                              : message,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (alreadyPaid) const Padding(padding: EdgeInsets.only(top: 8), child: Text('ออร์เดอร์นี้ชำระเงินเรียบร้อยแล้ว', textAlign: TextAlign.center)),
                ]),
              )),
              if (!waitingReview && !alreadyPaid) ...[
                const SizedBox(height: 12),
                const Card(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('วิธีชำระ: รอให้อาหารทุกเมนูทำเสร็จ → สแกน QR ด้วยแอปธนาคาร → โอนตามยอด → กลับมาหน้านี้เพื่อแนบสลิป → รอร้านตรวจสอบและยืนยัน', textAlign: TextAlign.center),
                )),
              ],
              if (!waitingReview && !alreadyPaid)
                OutlinedButton.icon(
                  onPressed: () => setState(() { qrFuture = ApiService.getPaymentQr(widget.orderId); _loadPayment(); }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองโหลด QR อีกครั้ง'),
                ),
            ]);
          }
          final data = snapshot.data!;
          final items = (data['items'] as List<dynamic>? ?? []).map((row) => Map<String, dynamic>.from(row)).toList();
          return ListView(padding: const EdgeInsets.all(18), children: [
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              Text('ยอดชำระ ฿${double.parse(data['amount'].toString()).toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              QrImageView(data: data['qr_payload'].toString(), size: 230, backgroundColor: Colors.white),
              const Text('สแกนด้วยแอปธนาคารเพื่อโอนผ่าน PromptPay', textAlign: TextAlign.center),
              if (data['promptpay_id']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7DDD7)),
                  ),
                  child: Column(children: [
                    const Text('PromptPay สำหรับโอนเงิน', style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      data['promptpay_id'].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ],
            ]))),
            const SizedBox(height: 12),
            Card(child: Column(children: [
              const ListTile(title: Text('รายการอาหาร', style: TextStyle(fontWeight: FontWeight.bold))),
              ...items.map((item) => ListTile(title: Text('${item['menu_name']} × ${item['quantity']}'), trailing: Text('฿${(double.parse(item['price'].toString()) * int.parse(item['quantity'].toString())).toStringAsFixed(2)}'))),
            ])),
            if (payment != null)
              Padding(padding: const EdgeInsets.all(12), child: Text('สถานะ: ${payment!['payment_status_name']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: sending || payment?['payment_status_id'].toString() == '3' || payment?['payment_status_id'].toString() == '1' ? null : _sendSlip,
              icon: const Icon(Icons.upload_file),
              label: Text(sending ? 'กำลังส่งสลิป...' : 'แนบสลิปการโอน'),
            ),
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('ร้านจะตรวจสอบสลิปก่อนยืนยันการชำระเงิน', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey))),
          ]);
        },
      ),
    );
  }
}
