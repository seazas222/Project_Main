import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/reservation.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import 'reservation_detail_page.dart';

class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({super.key});

  @override
  State<ReservationHistoryPage> createState() =>
      _ReservationHistoryPageState();
}

class _ReservationHistoryPageState
    extends State<ReservationHistoryPage> {
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    final user = CurrentUserService.instance.user;

    if (user == null) {
      _reservationsFuture = Future.value([]);
      return;
    }

    _reservationsFuture =
        ApiService.getReservationsByUserId(user.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadReservations();
    });

    await _reservationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Booking history',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Reservation>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.orange,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ไม่สามารถโหลดประวัติการจองได้',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return RefreshIndicator(
              color: AppColors.orange,
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.event_busy_outlined,
                    size: 65,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: Text(
                      'ยังไม่มีประวัติการจอง',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      'เมื่อคุณทำการจอง รายการจะแสดงที่นี่',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                30,
              ),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation =
                    reservations[index];

                return _reservationCard(
                  context,
                  reservation,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _reservationCard(
    BuildContext context,
    Reservation reservation,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservationDetailPage(
              reservationId:
                  reservation.reservationId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_outlined,
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
                        'Reservation #${reservation.reservationId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Table ${reservation.tableId}',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(
                  reservation.statusReservationId,
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _detailRow(
              Icons.calendar_today_outlined,
              'Date',
              reservation.diningDate,
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.access_time_outlined,
              'Time',
              reservation.diningTime,
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.people_outline,
              'Guests',
              '${reservation.guests} persons',
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.orange,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(int statusId) {
    String text;

    switch (statusId) {
      case 1:
        text = 'Pending';
        break;
      case 2:
        text = 'Confirmed';
        break;
      case 3:
        text = 'Cancelled';
        break;
      case 4:
        text = 'Completed';
        break;
      default:
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _statusColor(statusId),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(int statusId) {
    switch (statusId) {
      case 1:
        return const Color(0xFFFFF3CD);
      case 2:
        return const Color(0xFFE7F7EF);
      case 3:
        return const Color(0xFFFDECEC);
      case 4:
        return const Color(0xFFE8EEF9);
      default:
        return const Color(0xFFEDEDED);
    }
  }
}