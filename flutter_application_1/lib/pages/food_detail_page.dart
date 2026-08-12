import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/food.dart';
import '../services/cart_service.dart';
import '../widgets/app_buttons.dart';
import 'cart_page.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;

  const FoodDetailPage({
    super.key,
    required this.food,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int quantity = 1;
  String spicy = 'ไม่เผ็ด';
  String size = 'ธรรมดา';
  String egg = 'ไม่เพิ่ม';

  double get extras {
    var total = 0.0;
    if (size == 'พิเศษ +10') total += 10;
    if (size == 'พิเศษ +20') total += 20;
    if (egg == 'ไข่ดาว +10') total += 10;
    if (egg == 'ไข่เจียว +15') total += 15;
    return total;
  }

  double get base =>
      double.tryParse(widget.food.price.replaceAll('฿', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final total = (base + extras) * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Food Detail'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CartPage(),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    widget.food.imageAsset,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.food.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFC400),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.food.rating} / 5.0',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.food.price,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.food.description,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _ChoiceSection(
                  title: 'ระดับความเผ็ด',
                  options: const ['ไม่เผ็ด', 'เผ็ดกลาง', 'เผ็ดมาก'],
                  selected: spicy,
                  onSelected: (value) =>
                      setState(() => spicy = value),
                ),
                _ChoiceSection(
                  title: 'เลือกขนาด',
                  options: const ['ธรรมดา', 'พิเศษ +10', 'พิเศษ +20'],
                  selected: size,
                  onSelected: (value) =>
                      setState(() => size = value),
                ),
                _ChoiceSection(
                  title: 'ไข่',
                  options: const [
                    'ไม่เพิ่ม',
                    'ไข่ดาว +10',
                    'ไข่เจียว +15',
                  ],
                  selected: egg,
                  onSelected: (value) =>
                      setState(() => egg = value),
                ),
                const Text(
                  'หมายเหตุ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                const TextField(
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'เช่น ไม่ใส่ผัก',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 15),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () =>
                            setState(() => quantity++),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: 'Add to cart • ฿${total.toStringAsFixed(0)}',
                    onPressed: () {
                      for (var i = 0; i < quantity; i++) {
                        CartService.instance.add(widget.food);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChoiceSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            children: options.map((option) {
              final isSelected = option == selected;
              return ChoiceChip(
                label: Text(
                  option,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white
                        : AppColors.text,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.orange,
                onSelected: (_) => onSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
