import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';

/// Full workout history list, accessible from the Progress screen.
class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = SampleData.history;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Workout History', style: AppTextStyles.headlineMd),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: Squish(
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.gutter,
            AppSpacing.containerMargin,
            AppSpacing.lg,
          ),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _HistoryCard(entry: items[i]),
        ),
      ),
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
        return (
          bg: AppColors.secondaryContainer,
          fg: AppColors.onSecondaryContainer
        );
      case WorkoutCategory.yoga:
        return (
          bg: AppColors.tertiaryContainer,
          fg: AppColors.onTertiaryContainer
        );
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
