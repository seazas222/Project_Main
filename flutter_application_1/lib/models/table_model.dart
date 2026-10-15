class RestaurantTable {
  final int id;
  final int tableNumber;
  final int capacity;
  final int statusTableId;
  final String statusName;

  const RestaurantTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.statusTableId,
    required this.statusName,
  });

  factory RestaurantTable.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestaurantTable(
      id: int.parse(json['table_id'].toString()),
      tableNumber: int.parse(
        json['table_number'].toString(),
      ),
      capacity: int.parse(
        json['capacity'].toString(),
      ),
      statusTableId: int.parse(
        json['statustable_id'].toString(),
      ),
      statusName:
          json['statustable_name'].toString(),
    );
  }

  bool get available => statusName == 'ว่าง';

  String get displayNumber =>
      'T${tableNumber.toString().padLeft(3, '0')}';
}
