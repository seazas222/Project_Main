import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food.dart';

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._();
  CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  void add(Food food) {
    final index = _items.indexWhere((item) => item.food.id == food.id);
    if (index == -1) {
      _items.add(CartItem(food: food));
    } else {
      _items[index].quantity++;
    }
    notifyListeners();
  }

  void increment(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  void decrement(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
