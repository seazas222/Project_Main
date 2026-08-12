import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFFFD9C7)),
        ),
      ),
      child: Row(
        children: [
          _item(Icons.home_outlined, 'Home', 0),
          _item(Icons.restaurant_menu_outlined, 'Menu', 1),
          _item(Icons.calendar_month_outlined, 'Booking', 2),
          _item(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected ? AppColors.orange : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.orange : Colors.grey,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
