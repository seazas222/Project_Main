import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/table_model.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../widgets/app_buttons.dart';
import 'payment_page.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 30);

  int guests = 2;
  String? selectedTable;

  bool _isCreatingReservation = false;

  final tables = const [
  RestaurantTable(id: 'T001', seats: 2, available: true),
  RestaurantTable(id: 'T002', seats: 2, available: true),
  RestaurantTable(id: 'T003', seats: 4, available: true),
  RestaurantTable(id: 'T004', seats: 4, available: true),
  RestaurantTable(id: 'T005', seats: 6, available: true),
  RestaurantTable(id: 'T006', seats: 6, available: true),
];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ),
      initialDate: selectedDate,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatBookingDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReservation() async {
    if (selectedTable == null) {
      return;
    }

    final user = CurrentUserService.instance.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณา Login ก่อนทำการจอง'),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      // T001 -> 1
      // T002 -> 2
      // T003 -> 3
      // ...
      final tableId = int.parse(
        selectedTable!.replaceFirst('T', ''),
      );

      final bookingDate = _formatBookingDate(
        DateTime.now(),
      );

      final diningDate = _formatDate(
        selectedDate,
      );

      final diningTime = _formatTime(
        selectedTime,
      );

      final reservationId =
          await ApiService.createReservation(
        userId: user.userId,
        tableId: tableId,
        bookingDate: bookingDate,
        diningDate: diningDate,
        diningTime: diningTime,
        guests: guests,
        statusReservationId: 1,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'จองโต๊ะสำเร็จ #$reservationId',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            amount: 10.00,
            reservationTable: selectedTable,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถสร้างรายการจองได้: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';

    final time = selectedTime.format(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reserve a Table'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/restaurant.jpg',
              height: 170,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Choose your date & time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _selector(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: date,
                  onTap: _pickDate,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _selector(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: time,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _selector(
            icon: Icons.people_outline,
            label: 'Guests',
            value: '$guests people',
            onTap: () {
              setState(() {
                guests = guests >= 8 ? 1 : guests + 1;
              });
            },
          ),

          const SizedBox(height: 22),

          const Text(
            'Select a table',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Green = available • Orange = selected • Red = occupied',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (_, index) {
              final table = tables[index];
              final selected =
                  selectedTable == table.id;

              Color background;

              if (!table.available) {
                background = AppColors.danger;
              } else if (selected) {
                background = AppColors.orange;
              } else {
                background =
                    const Color(0xFFE8F7F1);
              }

              return InkWell(
                onTap: table.available
                    ? () {
                        setState(() {
                          selectedTable =
                              table.id;
                        });
                      }
                    : null,
                borderRadius:
                    BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 28,
                        color:
                            table.available &&
                                    !selected
                                ? AppColors.success
                                : Colors.white,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        table.id,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              table.available &&
                                      !selected
                                  ? AppColors.text
                                  : Colors.white,
                        ),
                      ),

                      Text(
                        '${table.seats} persons',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              table.available &&
                                      !selected
                                  ? AppColors.grey
                                  : Colors.white,
                        ),
                      ),

                      Text(
                        table.available
                            ? 'Available'
                            : 'Occupied',
                        style: TextStyle(
                          fontSize: 9,
                          color:
                              table.available &&
                                      !selected
                                  ? AppColors.success
                                  : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          if (selectedTable != null)
            Container(
              padding:
                  const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      '$selectedTable • '
                      '$guests people • $time',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 15),

          PrimaryButton(
            text: _isCreatingReservation
                ? 'Creating Reservation...'
                : 'Confirm Reservation',
            onPressed:
                selectedTable == null ||
                        _isCreatingReservation
                    ? null
                    : _confirmReservation,
          ),
        ],
      ),
    );
  }

  Widget _selector({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(15),
      child: Container(
        padding:
            const EdgeInsets.all(13),
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
            Icon(
              icon,
              color: AppColors.orange,
              size: 21,
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      color:
                          AppColors.grey,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}