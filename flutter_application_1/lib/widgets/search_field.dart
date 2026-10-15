import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;

  const AppSearchField({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: IconButton(
          tooltip: 'กรองหมวดอาหาร',
          onPressed: onFilter,
          icon: Icon(Icons.tune, size: 20, color: onFilter == null ? Colors.grey : Colors.black54),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
