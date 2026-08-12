import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../models/reservation.dart';

import 'reservation_page.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<Reservation> reservations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final user = CurrentUserService.instance.user;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'กรุณาเข้าสู่ระบบก่อน';
      });
      return;
    }

    try {
      final result = await ApiService.getReservationsByUserId(
        user.userId,
      );

      if (!mounted) return;

      setState(() {
        reservations = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  String _statusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'Confirmed';
      case 2:
        return 'Pending';
      case 3:
        return 'Cancelled';
      case 4:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int statusId) {
    switch (statusId) {
      case 1:
        return AppColors.success;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.danger;
      case 4:
        return Colors.blue;
      default:
        return AppColors.grey;
    }
  }

  Color _statusBackground(int statusId) {
    switch (statusId) {
      case 1:
        return const Color(0xFFE7F7EF);
      case 2:
        return const Color(0xFFFFF3E0);
      case 3:
        return const Color(0xFFFFEBEE);
      case 4:
        return const Color(0xFFE3F2FD);
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            children: [
              const Text(
                'My Booking',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Manage your reservation and order',
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
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                _errorView()
              else if (reservations.isEmpty)
                _emptyView()
              else
                ...reservations.map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: _bookingCard(reservation),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(Reservation reservation) {
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
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/restaurant.jpg',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table T${reservation.tableId.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
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
                      '${reservation.guests} persons',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(
                    reservation.statusReservationId,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(
                    reservation.statusReservationId,
                  ),
                  style: TextStyle(
                    color: _statusColor(
                      reservation.statusReservationId,
                    ),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _action(
            context,
            Icons.receipt_long_outlined,
            'Your Order',
            'Review food you pre-ordered',
            () {},
          ),

          const SizedBox(height: 10),

          _action(
            context,
            Icons.payments_outlined,
            'Payment',
            'View payment details',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentPage(
                    amount: 10.00,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _action(
            context,
            Icons.edit_calendar_outlined,
            'Modify reservation',
            'Change date, time or table',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReservationPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(
                color: AppColors.danger,
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Cancel Booking'),
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
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 55,
            color: AppColors.grey,
          ),

          SizedBox(height: 15),

          Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Your reservations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
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
            child: const Text('ลองอีกครั้ง'),
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
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(13),
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
                      fontWeight: FontWeight.w500,
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

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}