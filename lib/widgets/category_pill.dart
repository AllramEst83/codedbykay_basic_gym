import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small pill chip used for muscle groups / workout tags.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    this.background = AppColors.secondaryContainer,
    this.foreground = AppColors.onSecondaryContainer,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelBold.copyWith(color: foreground),
      ),
    );
  }
}
