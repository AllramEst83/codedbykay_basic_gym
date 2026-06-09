import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Glassmorphic top app bar used across the bottom-nav screens.
///
/// The container height is `_toolbarHeight + MediaQuery.padding.top` so the
/// title always sits below the status bar / camera notch, even on phones with
/// a punch-hole or pill-shaped cutout.
class FlexTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FlexTopBar({super.key});

  static const double _toolbarHeight = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _toolbarHeight + topPadding,
          color: surfaceColor.withValues(alpha: 0.85),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: SizedBox(
              height: _toolbarHeight,
              child: Center(
                child: Text(
                  'FlexFlow',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.primary,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
