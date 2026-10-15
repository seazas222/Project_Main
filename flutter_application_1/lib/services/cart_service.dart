import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/cart_item.dart';
import '../models/food.dart';

class CartService extends ChangeNotifier {
  static final CartService instance =
      CartService._();

  CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items =>
      List.unmodifiable(_items);

  int get itemCount {
    return _items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  void add(
    Food food, {
    String spicy = 'ไม่เผ็ด',
    String size = 'ธรรมดา',
    String egg = 'ไม่เพิ่ม',
    String serving = 'ทานที่ร้าน',
    String note = '',
    double extraPrice = 0,
    List<Map<String, dynamic>> selectedOptions = const [],
  }) {

    final index =
        _items.indexWhere(
      (item) =>
          item.food.id == food.id &&
          item.spicy == spicy &&
          item.size == size &&
          item.egg == egg &&
          item.serving == serving &&
          item.note == note &&
          item.extraPrice == extraPrice &&
          jsonEncode(item.selectedOptions) == jsonEncode(selectedOptions),
    );

    if (index == -1) {
      _items.add(
        CartItem(
          food: food,
          quantity: 1,
          spicy: spicy,
          size: size,
          egg: egg,
          serving: serving,
          note: note,
          extraPrice: extraPrice,
          selectedOptions: selectedOptions,
        ),
      );
    }

    else {
      _items[index].quantity++;
    }

    notifyListeners();
  }

  void increment(
    CartItem item,
  ) {
    item.quantity++;

    notifyListeners();
  }

  void decrement(
    CartItem item,
  ) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }

    notifyListeners();
  }

  void remove(
    CartItem item,
  ) {
    _items.remove(item);

    notifyListeners();
  }

  void replaceItem(CartItem oldItem, CartItem updatedItem) {
    final index = _items.indexOf(oldItem);
    if (index < 0) return;
    _items[index] = updatedItem;
    notifyListeners();
  }

  void clear() {
    _items.clear();

    notifyListeners();
  }
}
