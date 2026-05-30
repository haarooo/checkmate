import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, required this.status});

  final String text;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _resolve(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  (Color, Color) _resolve(String s) {
    switch (s) {
      case 'SUCCESS':
      case 'CONFIRMED':
        return (AppColors.successDark, AppColors.successSoft);
      case 'IN_PROGRESS':
        return (AppColors.primaryDark, AppColors.primarySoft);
      case 'READY':
      case 'WAITING_CONFIRM':
        return (AppColors.primaryDark, AppColors.primarySoft);
      case 'NEED_SUBMIT':
      case 'NEED_MORE':
        return (AppColors.warning, AppColors.warningSoft);
      case 'FAILED':
      case 'MISSED':
        return (AppColors.error, AppColors.errorSoft);
      case 'SETTLED':
        return (AppColors.textSecondary, AppColors.cardBorder);
      default:
        return (AppColors.primary, AppColors.primarySoft);
    }
  }
}
