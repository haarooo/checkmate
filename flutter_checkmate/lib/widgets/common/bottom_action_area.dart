import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'primary_button.dart';

class ActionConfig {
  const ActionConfig({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
}

class BottomActionArea extends StatelessWidget {
  const BottomActionArea({
    super.key,
    required this.primary,
    this.secondary,
  });

  final ActionConfig primary;
  final ActionConfig? secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: secondary != null
              ? Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(config: secondary!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: primary.text,
                        onPressed: primary.onPressed,
                        isLoading: primary.isLoading,
                        icon: primary.icon,
                        backgroundColor: primary.backgroundColor,
                      ),
                    ),
                  ],
                )
              : PrimaryButton(
                  text: primary.text,
                  onPressed: primary.onPressed,
                  isLoading: primary.isLoading,
                  icon: primary.icon,
                  backgroundColor: primary.backgroundColor,
                ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.config});

  final ActionConfig config;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: config.isLoading ? null : config.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          config.text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
