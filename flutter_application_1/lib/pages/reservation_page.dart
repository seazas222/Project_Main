import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/table_model.dart';
import '../services/api_service.dart';
import '../services/current_user_service.dart';
import '../widgets/app_buttons.dart';
import 'food_menu_page.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() =>
      _ReservationPageState();
}

class _ReservationPageState
    extends State<ReservationPage> {

  late DateTime selectedDate;
  TimeOfDay? selectedTime;
  String? _timeError;
  int _availabilityRequestId = 0;

  int guests = 2;

  RestaurantTable? selectedTable;

  List<RestaurantTable> tables = [];

  bool _isLoadingTables = false;

  bool _isCreatingReservation = false;

  String? _tableError;
  Set<String> _holidayDates = <String>{};
  Map<String, String> _holidayNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    final initialSlot = _initialReservationStart();
    selectedDate = DateUtils.dateOnly(initialSlot);
    _loadTables();
  }

  DateTime _initialReservationStart() {
    final now = DateTime.now();
    for (var offset = 0; offset <= 2; offset++) {
      final date = DateUtils.dateOnly(now.add(Duration(days: offset)));
      if (date.weekday == DateTime.sunday) continue;
      final hour = offset == 0 ? (now.hour + 1 < 9 ? 9 : now.hour + 1) : 9;
      if (hour <= 13) return DateTime(date.year, date.month, date.day, hour);
    }
    final fallback = DateUtils.dateOnly(now.add(const Duration(days: 1)));
    return DateTime(fallback.year, fallback.month, fallback.day, 9);
  }

  Future<void> _loadTables() async {
    final requestId = ++_availabilityRequestId;
    final requestedTime = selectedTime;
    final requestedDate = selectedDate;
    final requestedGuests = guests;
    try {
      setState(() {
        _isLoadingTables = requestedTime != null;
        _tableError = null;
        if (requestedTime == null) tables = [];
      });

      final today = DateUtils.dateOnly(DateTime.now());
      final holidayRows = await ApiService.getHolidays(
        from: _formatDate(today),
        to: _formatDate(today.add(const Duration(days: 2))),
      );
      final names = <String, String>{};
      for (final holiday in holidayRows) {
        final rawDate = holiday['holiday_date']?.toString() ?? '';
        if (rawDate.length >= 10) {
          names[rawDate.substring(0, 10)] = holiday['holiday_name']?.toString() ?? 'วันหยุดพิเศษ';
        }
      }
      if (mounted && requestId == _availabilityRequestId) {
        setState(() {
          _holidayNames = names;
          _holidayDates = names.keys.toSet();
        });
      }

      if (requestedTime == null || requestId != _availabilityRequestId) return;

      final result = await ApiService.getAvailability(
        date: _formatDate(requestedDate),
        time: _formatTime(requestedTime),
        guests: requestedGuests,
      );

      if (!mounted || requestId != _availabilityRequestId) return;

      setState(() {
        tables = result.map(RestaurantTable.fromJson).toList();
        if (selectedTable != null && !tables.any((table) => table.id == selectedTable!.id)) {
          selectedTable = null;
        }
        _isLoadingTables = false;
      });
    } catch (e) {
      if (!mounted || requestId != _availabilityRequestId) return;

      setState(() {
        _isLoadingTables = false;

        _tableError = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = today.add(const Duration(days: 2));
    bool isSelectable(DateTime date) {
      final isToday = DateUtils.isSameDay(date, today);
      return date.weekday != DateTime.sunday &&
          !_holidayDates.contains(_formatDate(date)) &&
          (!isToday || DateTime.now().hour < 13);
    }

    final availableDates = List.generate(3, (offset) => today.add(Duration(days: offset)))
        .where(isSelectable)
        .toList();
    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีวันที่เปิดจองในช่วง 2 วันนี้')),
      );
      return;
    }
    final initialDate = isSelectable(selectedDate) ? selectedDate : availableDates.first;
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) => _ReservationCalendarDialog(
        initialDate: initialDate,
        firstDate: today,
        lastDate: lastDate,
      ),
    );

    if (date == null) return;

    setState(() {
      selectedDate = date;
      selectedTable = null;
    });
    _onTimeChanged(
      selectedTime == null ? '' : _formatTime(selectedTime!).substring(0, 5),
      loadHolidays: true,
    );
  }

  void _onTimeChanged(String value, {bool loadHolidays = false}) {
    TimeOfDay? parsed;
    String? error;
    if (value.length == 5) {
      final hour = int.tryParse(value.substring(0, 2));
      final minute = int.tryParse(value.substring(3, 5));
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        error = 'กรุณาระบุเวลาให้ถูกต้อง';
      } else if (hour < 9 || hour > 13 || (hour == 13 && minute > 0)) {
        error = 'รับจองเวลา 09:00–13:00 (ใช้โต๊ะได้ 1 ชั่วโมง)';
      } else {
        final now = DateTime.now();
        final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
        if (!start.isAfter(now)) {
          error = 'กรุณาเลือกเวลาที่ยังไม่ผ่านไป';
        } else {
          parsed = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    setState(() {
      selectedTime = parsed;
      _timeError = error;
      selectedTable = null;
      tables = [];
      _tableError = null;
      _isLoadingTables = parsed != null;
    });
    ++_availabilityRequestId;
    if (parsed != null || loadHolidays) _loadTables();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final opening = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
    final lastBooking = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13);
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 1));
    final firstBooking = DateUtils.isSameDay(selectedDate, now) && nextMinute.isAfter(opening)
        ? nextMinute
        : opening;
    if (firstBooking.isAfter(lastBooking)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('วันนี้หมดเวลารับจองแล้ว กรุณาเลือกวันอื่น')),
      );
      return;
    }

    List<int> availableMinutes(int hour) {
      if (hour < firstBooking.hour) return [];
      final firstMinute = hour == firstBooking.hour ? firstBooking.minute : 0;
      final lastMinute = hour == 13 ? 0 : 59;
      if (firstMinute > lastMinute) return [];
      return List.generate(lastMinute - firstMinute + 1, (index) => firstMinute + index);
    }

    final hours = [for (var hour = 9; hour <= 13; hour++)
      if (availableMinutes(hour).isNotEmpty) hour];
    final previous = selectedTime == null
        ? null
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
            selectedTime!.hour, selectedTime!.minute);
    final initial = previous != null && !previous.isBefore(firstBooking) &&
            !previous.isAfter(lastBooking)
        ? previous
        : firstBooking;
    var chosenHour = initial.hour;
    var chosenMinute = initial.minute;

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เลือกเวลาจอง'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เลือกได้เฉพาะเวลา 09:00–13:00',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: chosenHour,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'ชั่วโมง'),
                      items: hours.map((hour) => DropdownMenuItem(
                        value: hour,
                        child: Text(hour.toString().padLeft(2, '0')),
                      )).toList(),
                      onChanged: (hour) {
                        if (hour == null) return;
                        setDialogState(() {
                          chosenHour = hour;
                          if (!availableMinutes(hour).contains(chosenMinute)) {
                            chosenMinute = availableMinutes(hour).first;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(chosenHour),
                      initialValue: chosenMinute,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'นาที'),
                      items: availableMinutes(chosenHour).map((minute) => DropdownMenuItem(
                        value: minute,
                        child: Text(minute.toString().padLeft(2, '0')),
                      )).toList(),
                      onChanged: (minute) {
                        if (minute != null) setDialogState(() => chosenMinute = minute);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext, TimeOfDay(hour: chosenHour, minute: chosenMinute)),
              child: const Text('เลือกเวลานี้'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _onTimeChanged(value);
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(
    TimeOfDay time,
  ) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatBookingDate(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReservation() async {

    final reservationTime = selectedTime;
    if (reservationTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุเวลาที่ต้องการจอง')),
      );
      return;
    }

    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกโต๊ะก่อน',
          ),
        ),
      );

      return;
    }

    final user =
        CurrentUserService.instance.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเข้าสู่ระบบก่อนทำการจอง',
          ),
        ),
      );

      return;
    }

    if (_isCreatingReservation) {
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {

      final tableId =
          selectedTable!.id;

      final bookingDate =
          _formatBookingDate(
        DateTime.now(),
      );

      final diningDate =
          _formatDate(
        selectedDate,
      );

      final diningTime =
          _formatTime(
        reservationTime,
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

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FoodMenuPage(
            reservationId: reservationId,
            reservationTable: selectedTable!.displayNumber,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถสร้างรายการจองได้\n'
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),

          backgroundColor:
              AppColors.danger,
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
  Widget build(
    BuildContext context,
  ) {
    final date =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';

    final time = selectedTime == null ? '-- : --' : _formatTime(selectedTime!).substring(0, 5);

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title:
            const Text(
          'จองโต๊ะ',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),

        children: [

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            child:
                Image.asset(
              'assets/restaurant.jpg',

              height: 145,

              fit:
                  BoxFit.cover,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'เลือกวันและเวลา',

            style:
                TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [

              Expanded(
                child:
                    _selector(
                  icon: Icons
                      .calendar_month_outlined,

                  label:
                      'วันที่',

                  value:
                      date,

                  onTap:
                      _pickDate,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _timeInput(),
              ),
            ],
          ),

          if (_timeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4),
              child: Text(_timeError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
            ),

          const Padding(
            padding: EdgeInsets.only(top: 5, left: 4),
            child: Text('กดเลือกเวลา • รับจอง 09:00–13:00', style: TextStyle(color: AppColors.grey, fontSize: 11)),
          ),

          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Wrap(spacing: 12, runSpacing: 5, children: [
              _DateStatusLegend(color: Color(0xFFDC4C57), label: 'ร้านปิด'),
              _DateStatusLegend(color: Color(0xFF23865B), label: 'ร้านเปิด'),
              _DateStatusLegend(color: Color(0xFF858B91), label: 'ยังไม่กำหนด'),
            ]),
          ),

          if (_holidayNames.containsKey(_formatDate(selectedDate))) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('ร้านหยุด: ${_holidayNames[_formatDate(selectedDate)]} กรุณาเลือกวันอื่น'),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          _guestSelector(),

          const SizedBox(
            height: 22,
          ),

          const Text(
            'เลือกโต๊ะ',

            style:
                TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'สีเขียว = ว่าง • '
            'สีส้ม = เลือกแล้ว • '
            'สีแดง = ไม่ว่าง',

            style:
                TextStyle(
              color:
                  AppColors.grey,

              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (_isLoadingTables)
            const Padding(
              padding:
                  EdgeInsets.all(
                40,
              ),

              child:
                  Center(
                child:
                    CircularProgressIndicator(
                  color:
                      AppColors.orange,
                ),
              ),
            ),

          if (!_isLoadingTables &&
              _tableError != null)
            Container(
              padding:
                  const EdgeInsets.all(
                18,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child:
                  Column(
                children: [
                  const Icon(
                    Icons
                        .error_outline,

                    color:
                        AppColors.danger,

                    size: 40,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'ไม่สามารถโหลดข้อมูลโต๊ะได้',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _tableError!,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color:
                          AppColors.grey,

                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  OutlinedButton(
                    onPressed:
                        _loadTables,

                    child:
                        const Text(
                      'ลองใหม่',
                    ),
                  ),
                ],
              ),
            ),

          if (!_isLoadingTables && selectedTime == null &&
              _tableError == null)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('กรุณาระบุเวลาก่อนเลือกโต๊ะ', style: TextStyle(color: AppColors.grey))),
            ),

          if (!_isLoadingTables && selectedTime != null &&
              _tableError == null &&
              tables.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.all(
                40,
              ),

              child:
                  Center(
                child:
                    Text(
                  'ไม่พบข้อมูลโต๊ะ',

                  style:
                      TextStyle(
                    color:
                        AppColors.grey,
                  ),
                ),
              ),
            ),

          if (!_isLoadingTables &&
              _tableError == null &&
              tables.isNotEmpty)
            GridView.builder(
              shrinkWrap:
                  true,

              physics:
                  const NeverScrollableScrollPhysics(),

              itemCount:
                  tables.length,

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    3,

                crossAxisSpacing:
                    10,

                mainAxisSpacing:
                    10,

                childAspectRatio:
                    1.1,
              ),

              itemBuilder:
                  (_, index) {
                final table =
                    tables[index];

                final selected =
                    selectedTable?.id ==
                        table.id;

                Color background;

                if (!table.available) {
                  background =
                      AppColors.danger;
                } else if (selected) {
                  background =
                      AppColors.orange;
                } else {
                  background =
                      const Color(
                    0xFFE8F7F1,
                  );
                }

                return InkWell(
                  onTap:
                      table.available
                          ? () {
                              setState(() {
                                selectedTable =
                                    table;
                              });
                            }
                          : null,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  child:
                      Container(
                    decoration:
                        BoxDecoration(
                      color:
                          background,

                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),

                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .table_restaurant,

                          size:
                              28,

                          color:
                              table.available &&
                                      !selected
                                  ? AppColors
                                      .success
                                  : Colors
                                      .white,
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          table
                              .displayNumber,

                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,

                            color:
                                table.available &&
                                        !selected
                                    ? AppColors
                                        .text
                                    : Colors
                                        .white,
                          ),
                        ),

                        Text(
                          '${table.capacity} คน',

                          style:
                              TextStyle(
                            fontSize:
                                10,

                            color:
                                table.available &&
                                        !selected
                                    ? AppColors
                                        .grey
                                    : Colors
                                        .white,
                          ),
                        ),

                        Text(
                          table
                              .statusName,

                          style:
                              TextStyle(
                            fontSize:
                                9,

                            color:
                                table.available &&
                                        !selected
                                    ? AppColors
                                        .success
                                    : Colors
                                        .white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(
            height: 20,
          ),

          if (selectedTable != null)
            Container(
              padding:
                  const EdgeInsets.all(
                15,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child:
                  Row(
                children: [
                  const Icon(
                    Icons.check_circle,

                    color:
                        AppColors.success,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        Text(
                      '${selectedTable!.displayNumber} • '
                      '$guests คน • '
                      '$time',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 15,
          ),

          PrimaryButton(
            text:
                _isCreatingReservation
                    ? 'กำลังจองโต๊ะ...'
                    : 'ยืนยันการจอง',

            onPressed:
                selectedTable == null ||
                        selectedTime == null ||
                        _isCreatingReservation ||
                        _holidayDates.contains(_formatDate(selectedDate))
                    ? null
                    : _confirmReservation,
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _timeInput() {
    return Semantics(
      button: true,
      label: 'เลือกเวลาจอง',
      child: InkWell(
        onTap: _pickTime,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.orange, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เวลา', style: TextStyle(color: AppColors.grey, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      selectedTime == null
                          ? '-- : --'
                          : _formatTime(selectedTime!).substring(0, 5),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.orange),
            ],
          ),
        ),
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
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(
        15,
      ),

      child:
          Container(
        padding:
            const EdgeInsets.all(
          13,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border:
              Border.all(
            color:
                AppColors.border,
          ),
        ),

        child:
            Row(
          children: [
            Icon(
              icon,

              color:
                  AppColors.orange,

              size:
                  21,
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    label,

                    style:
                        const TextStyle(
                      color:
                          AppColors.grey,

                      fontSize:
                          10,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    value,

                    maxLines:
                        1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontSize:
                          12,
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

  Widget _guestSelector() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_outline, color: AppColors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('จำนวนผู้จอง', style: TextStyle(color: AppColors.grey, fontSize: 11)),
                  Text('ระบุจำนวนคน', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'ลดจำนวนผู้จอง',
              onPressed: guests <= 1 ? null : () => _changeGuestCount(guests - 1),
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.orange,
            ),
            Text('$guests คน', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              tooltip: 'เพิ่มจำนวนผู้จอง',
              onPressed: guests >= 8 ? null : () => _changeGuestCount(guests + 1),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.orange,
            ),
          ],
        ),
      );

  void _changeGuestCount(int value) {
    if (value < 1 || value > 8 || value == guests) return;
    setState(() {
      guests = value;
      selectedTable = null;
    });
    _loadTables();
  }
}

enum _ReservationDateStatus { closed, open, unknown }

class _ReservationCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _ReservationCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_ReservationCalendarDialog> createState() =>
      _ReservationCalendarDialogState();
}

class _ReservationCalendarDialogState
    extends State<_ReservationCalendarDialog> {
  static const _closedColor = Color(0xFFDC4C57);
  static const _openColor = Color(0xFF23865B);
  static const _unknownColor = Color(0xFF858B91);
  static const _months = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  late DateTime _selectedDate;
  late DateTime _month;
  Set<String> _holidayDates = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
    _month = DateTime(_selectedDate.year, _selectedDate.month);
    _loadMonth();
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    try {
      final rows = await ApiService.getHolidays(
        from: _formatDate(first),
        to: _formatDate(last),
      );
      if (!mounted) return;
      setState(() {
        _holidayDates = rows
            .map((row) => row['holiday_date']?.toString() ?? '')
            .where((date) => date.length >= 10)
            .map((date) => date.substring(0, 10))
            .toSet();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  _ReservationDateStatus _statusFor(DateTime date) {
    final key = _formatDate(date);
    if (date.weekday == DateTime.sunday || _holidayDates.contains(key)) {
      return _ReservationDateStatus.closed;
    }
    final day = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(DateTime.now());
    final insideBookingWindow = !day.isBefore(widget.firstDate) &&
        !day.isAfter(widget.lastDate);
    final todayStillOpen = !DateUtils.isSameDay(day, today) ||
        DateTime.now().hour < 13;
    if (insideBookingWindow && todayStillOpen) {
      return _ReservationDateStatus.open;
    }
    return _ReservationDateStatus.unknown;
  }

  Color _colorFor(_ReservationDateStatus status) => switch (status) {
        _ReservationDateStatus.closed => _closedColor,
        _ReservationDateStatus.open => _openColor,
        _ReservationDateStatus.unknown => _unknownColor,
      };

  Future<void> _changeMonth(int delta) async {
    final next = DateTime(_month.year, _month.month + delta);
    setState(() => _month = next);
    await _loadMonth();
  }

  bool get _canGoPrevious =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canGoNext =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset = DateTime(_month.year, _month.month, 1).weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final title = '${_months[_month.month - 1]} ${_month.year + 543}';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('เลือกวันที่จอง', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
              IconButton(tooltip: 'ปิด', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            Row(children: [
              IconButton(
                tooltip: 'เดือนก่อนหน้า',
                onPressed: !_loading && _canGoPrevious ? () => _changeMonth(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)))),
              IconButton(
                tooltip: 'เดือนถัดไป',
                onPressed: !_loading && _canGoNext ? () => _changeMonth(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
            const SizedBox(height: 4),
            const Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 6, children: [
              _DateStatusLegend(color: _closedColor, label: 'ร้านปิด'),
              _DateStatusLegend(color: _openColor, label: 'ร้านเปิด'),
              _DateStatusLegend(color: _unknownColor, label: 'ยังไม่กำหนด'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              'อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส',
            ].map((day) => Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 12, color: AppColors.grey))))).toList()),
            const SizedBox(height: 4),
            if (_loading)
              const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SizedBox(
                height: 260,
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_outlined, color: AppColors.grey, size: 32),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey)),
                  TextButton.icon(onPressed: _loadMonth, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง')),
                ])),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (context, index) {
                  final day = index - firstWeekdayOffset + 1;
                  if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                  final date = DateTime(_month.year, _month.month, day);
                  final status = _statusFor(date);
                  final color = _colorFor(status);
                  final selected = DateUtils.isSameDay(date, _selectedDate);
                  return Center(
                    child: InkWell(
                      onTap: status == _ReservationDateStatus.open
                          ? () => Navigator.pop(context, date)
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: status == _ReservationDateStatus.unknown ? 0.10 : 0.14),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: AppColors.orange, width: 2) : null,
                        ),
                        child: Text('$day', style: TextStyle(color: color, fontWeight: status == _ReservationDateStatus.open ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DateStatusLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DateStatusLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]);
}
