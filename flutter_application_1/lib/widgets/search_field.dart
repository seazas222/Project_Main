import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    this.hint = 'Search',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: const Icon(Icons.tune, size: 20, color: Colors.grey),
      ),
    );
  }
}
