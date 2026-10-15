import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/reservation.dart';
import '../services/api_service.dart';

class ReservationDetailPage extends StatefulWidget {
  final int reservationId;

  const ReservationDetailPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailPage> createState() =>
      _ReservationDetailPageState();
}

class _ReservationDetailPageState
    extends State<ReservationDetailPage> {
  late Future<Reservation> _reservationFuture;

  @override
  void initState() {
    super.initState();

    _reservationFuture =
        ApiService.getReservationById(
      widget.reservationId,
    );
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
          'Reservation detail',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: FutureBuilder<Reservation>(
        future: _reservationFuture,

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
            return _errorView();
          }

          final reservation = snapshot.data;

          if (reservation == null) {
            return _errorView();
          }

          return _detailView(reservation);
        },
      ),
    );
  }

  Widget _detailView(
    Reservation reservation,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.table_restaurant_outlined,
                  size: 34,
                  color: AppColors.orange,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Reservation #${reservation.reservationId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _statusBadge(
                reservation.statusReservationId,
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Reservation information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 15),

              _infoRow(
                Icons.table_restaurant_outlined,
                'Table',
                'Table ${reservation.tableId}',
              ),

              _infoRow(
                Icons.calendar_today_outlined,
                'Dining date',
                reservation.diningDate,
              ),

              _infoRow(
                Icons.access_time_outlined,
                'Dining time',
                reservation.diningTime,
              ),

              _infoRow(
                Icons.people_outline,
                'Guests',
                '${reservation.guests} persons',
              ),

              _infoRow(
                Icons.receipt_long_outlined,
                'Booking date',
                reservation.bookingDate,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: AppColors.orange,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),

          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _statusColor(statusId),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
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

  Widget _errorView() {
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
              'ไม่สามารถโหลดข้อมูลการจองได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _reservationFuture =
                      ApiService.getReservationById(
                    widget.reservationId,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'ลองอีกครั้ง',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
