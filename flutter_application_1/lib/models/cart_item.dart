import 'food.dart';

class CartItem {
  final Food food;
  int quantity;

  CartItem({
    required this.food,
    this.quantity = 1,
  });

  double get unitPrice =>
      double.tryParse(food.price.replaceAll('฿', '').trim()) ?? 0;

  double get total => unitPrice * quantity;
}
