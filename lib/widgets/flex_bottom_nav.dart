import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Glassmorphic bottom navigation bar matching the Kinetic Pastel
/// design language (pill-shaped active state, soft active scale).
class FlexBottomNav extends StatelessWidget {
  const FlexBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<({IconData icon, IconData filled, String label})> _items = [
    (
      icon: Icons.fitness_center_outlined,
      filled: Icons.fitness_center_rounded,
      label: 'Workouts',
    ),
    (
      icon: Icons.calendar_month_outlined,
      filled: Icons.calendar_month_rounded,
      label: 'Calendar',
    ),
    (
      icon: Icons.insights_outlined,
      filled: Icons.insights_rounded,
      label: 'Progress',
    ),
    (
      icon: Icons.settings_outlined,
      filled: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: surfaceColor.withValues(alpha: 0.85),
          padding: EdgeInsets.only(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            top: AppSpacing.base,
            bottom: bottomInset + AppSpacing.base,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return _NavTab(
                selected: selected,
                icon: selected ? item.filled : item.icon,
                label: item.label,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  const _NavTab({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected ? AppColors.primaryContainer : Colors.transparent;
    final fg = selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: fg, size: 22),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
