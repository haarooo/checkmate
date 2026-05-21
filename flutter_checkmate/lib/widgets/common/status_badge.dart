import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, required this.status});

  final String text;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'SUCCESS' || 'CONFIRMED' || 'IN_PROGRESS' => AppColors.success,
      'READY' || 'WAITING_CONFIRM' => AppColors.warning,
      'FAILED' || 'MISSED' => AppColors.error,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
