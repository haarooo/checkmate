import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class UploadBox extends StatelessWidget {
  const UploadBox({super.key, required this.onTap, this.fileName});

  final VoidCallback onTap;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              fileName ?? '사진 또는 동영상 선택',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
