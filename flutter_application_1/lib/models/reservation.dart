class Reservation {
  final int reservationId;
  final int userId;
  final int tableId;
  final String bookingDate;
  final String diningDate;
  final String diningTime;
  final int guests;
  final int statusReservationId;
  final String? statusReservationName;
  final int? tableNumber;

  const Reservation({
    required this.reservationId,
    required this.userId,
    required this.tableId,
    required this.bookingDate,
    required this.diningDate,
    required this.diningTime,
    required this.guests,
    required this.statusReservationId,
    this.statusReservationName,
    this.tableNumber,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: json['reservation_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      tableId: json['table_id'] ?? 0,
      bookingDate: json['booking_date']?.toString() ?? '',
      diningDate: json['dining_date']?.toString() ?? '',
      diningTime: json['dining_time']?.toString() ?? '',
      guests: json['guests'] ?? 0,
      statusReservationId:
          json['statusreservation_id'] ?? 0,
      statusReservationName: json['statusreservation_name']?.toString(),
      tableNumber: int.tryParse(json['table_number']?.toString() ?? ''),
    );
  }
}
