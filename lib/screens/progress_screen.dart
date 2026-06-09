import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';
import 'workout_history_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.gutter,
          AppSpacing.containerMargin,
          AppSpacing.lg + 80,
        ),
        children: [
          const _SectionHeader(),
          const SizedBox(height: AppSpacing.md),
          const _SummaryRow(),
          const SizedBox(height: AppSpacing.lg),
          const _VolumeChart(),
          const SizedBox(height: AppSpacing.lg),
          _HistoryHeader(
            onViewAll: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WorkoutHistoryScreen(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          const _HistoryList(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Text('This Week', style: AppTextStyles.displayLgMobile);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SummaryCard(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '184',
            unit: 'min',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Calories',
            value: '1,240',
            unit: 'kcal',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.statNumber),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Volume', style: AppTextStyles.headlineMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Last 7 Days',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.surfaceContainerHighest),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in SampleData.weeklyVolume) ...[
                  Expanded(child: _Bar(label: bar.label, height: bar.height, today: bar.today)),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.height, required this.today});

  final String label;
  final double height;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: c.maxHeight * height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: today ? AppColors.primary : AppColors.secondaryContainer,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          label,
          style: AppTextStyles.labelBold.copyWith(
            fontSize: 11,
            color: today ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Workout History', style: AppTextStyles.headlineMd),
          Squish(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'View All',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    final items = SampleData.history;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _HistoryCard(entry: items[i]),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final WorkoutHistoryEntry entry;

  ({Color bg, Color fg}) _iconPalette() {
    switch (entry.category) {
      case WorkoutCategory.strength:
        return (bg: AppColors.primaryContainer, fg: AppColors.onPrimaryContainer);
      case WorkoutCategory.cardio:
        return (bg: AppColors.secondaryContainer, fg: AppColors.onSecondaryContainer);
      case WorkoutCategory.yoga:
        return (bg: AppColors.tertiaryContainer, fg: AppColors.onTertiaryContainer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _iconPalette();
    return Squish(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(entry.category.icon, size: 32, color: p.fg),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.dateLabel} • ${entry.durationMinutes} min',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
