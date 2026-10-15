import 'food.dart';

class CartItem {
  final Food food;

  int quantity;

  final String spicy;

  final String size;

  final String egg;

  final String serving;

  final String note;

  final double extraPrice;

  final List<Map<String, dynamic>> selectedOptions;

  CartItem({
    required this.food,

    this.quantity = 1,

    this.spicy = 'ไม่เผ็ด',

    this.size = 'ธรรมดา',

    this.egg = 'ไม่เพิ่ม',

    this.serving = 'ทานที่ร้าน',

    this.note = '',

    this.extraPrice = 0,
    this.selectedOptions = const [],
  });

  double get unitPrice {
    final basePrice =
        double.tryParse(
              food.price
                  .replaceAll('฿', '')
                  .replaceAll(',', '')
                  .trim(),
            ) ??
            0;

    return basePrice + extraPrice;
  }

  double get total {
    return unitPrice * quantity;
  }
}
