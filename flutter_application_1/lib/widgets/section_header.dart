import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action = 'See All',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
