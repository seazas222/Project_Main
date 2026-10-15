import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../models/reservation.dart';

import 'food_menu_page.dart';
import 'order_history_page.dart';
import 'reservation_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    this.isActive = true,
  });

  final bool isActive;

  @override
  State<BookingPage> createState() =>
      _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  int _requestId = 0;
  final Set<int> _cancellingIds = <int>{};
  List<Reservation> reservations = [];

  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReservations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (widget.isActive) _loadReservations();
    });
  }

  @override
  void didUpdateWidget(covariant BookingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadReservations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _loadReservations();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadReservations() async {
    final requestId = ++_requestId;
    final user =
        CurrentUserService.instance.user;

    if (user == null) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        isLoading = false;
        errorMessage = 'กรุณาเข้าสู่ระบบก่อน';
      });

      return;
    }

    try {
      final result =
          await ApiService.getReservationsByUserId(
        user.userId,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        reservations = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    if (_cancellingIds.contains(reservationId)) return;
    setState(() => _cancellingIds.add(reservationId));
    try {
      await ApiService.cancelReservation(reservationId);
      if (!mounted) return;
      setState(() {
        reservations.removeWhere((item) => item.reservationId == reservationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกการจองแล้ว ดูรายละเอียดได้ในประวัติการจอง')),
      );
      await _loadReservations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingIds.remove(reservationId));
    }
  }

  String _statusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'ยืนยันแล้ว';
      case 2:
        return 'ยกเลิก';
      case 3:
        return 'มาใช้บริการแล้ว';
      case 4:
        return 'รอยืนยัน';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color _statusColor(int statusId) {
    switch (statusId) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.danger;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.orange;
      default:
        return AppColors.grey;
    }
  }

  Color _statusBackground(int statusId) {
    switch (statusId) {
      case 1:
        return const Color(0xFFE7F7EF);
      case 2:
        return const Color(0xFFFFEBEE);
      case 3:
        return const Color(0xFFE3F2FD);
      case 4:
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF2F2F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReservations,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            children: [
              const Text(
                'การจองของฉัน',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'จัดการการจองโต๊ะและรายการอาหารของคุณ',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                    ),
                  ),
                )
              else if (errorMessage != null)
                _errorView()
              else if (reservations.isEmpty)
                _emptyView()
              else
                ...reservations.map(
                  (reservation) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: _bookingCard(
                      reservation,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(
    Reservation reservation,
  ) {
    final tableNumber =
        'T${(reservation.tableNumber ?? reservation.tableId).toString().padLeft(3, '0')}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(13),
            child: Image.asset(
              'assets/restaurant.jpg',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โต๊ะ $tableNumber',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${reservation.diningDate} • ${reservation.diningTime}',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${reservation.guests} คน',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(
                    reservation
                        .statusReservationId,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                      reservation.statusReservationName ?? _statusText(reservation.statusReservationId),
                  style: TextStyle(
                    color: _statusColor(
                      reservation
                          .statusReservationId,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _action(
            context,
            Icons.restaurant_menu_outlined,
            'สั่งอาหาร',
            'เลือกอาหารสำหรับโต๊ะนี้',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodMenuPage(
                    reservationId:
                        reservation.reservationId,
                    reservationTable:
                        tableNumber,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _action(
            context,
            Icons.payments_outlined,
            'ออร์เดอร์และการชำระเงิน',
            'ดูรายการอาหารและ QR เมื่ออาหารทำเสร็จ',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: reservation.statusReservationId == 2 ||
                    reservation.statusReservationId == 3 ||
                    _cancellingIds.contains(reservation.reservationId)
                ? null
                : () => _cancelReservation(reservation.reservationId),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.danger,
              side: const BorderSide(
                color: AppColors.danger,
              ),
              minimumSize:
                  const Size.fromHeight(48),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _cancellingIds.contains(reservation.reservationId)
                  ? 'กำลังยกเลิก...'
                  : reservation.statusReservationId == 2 ? 'ยกเลิกแล้ว' : 'ยกเลิกการจอง',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 55,
            color: AppColors.grey,
          ),
          const SizedBox(height: 15),
          const Text(
            'ยังไม่มีการจอง',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'รายการจองโต๊ะของคุณจะแสดงที่นี่',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ReservationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('จองโต๊ะ'),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 50,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          const Text(
            'ไม่สามารถโหลดข้อมูลการจองได้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: _loadReservations,
            child: const Text(
              'ลองอีกครั้ง',
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color:
                    AppColors.orangeLight,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}
