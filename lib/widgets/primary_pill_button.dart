import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'squish.dart';

/// Oversized, pill-shaped primary button.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.height = 56,
    this.elevated = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double height;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onPressed,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: background.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.base),
            ],
            Text(
              label,
              style: AppTextStyles.labelBold.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
