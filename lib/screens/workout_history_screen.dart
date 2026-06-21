import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stores/session_store.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';

/// Full workout history list, read from [SessionStore].
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    SessionStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    SessionStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = SessionStore.instance.sessions;
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
        child: items.isEmpty
            ? _EmptyHistory()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.gutter,
                  AppSpacing.containerMargin,
                  AppSpacing.lg,
                ),
                itemCount: items.length,
                separatorBuilder: (context2, index2) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _HistoryCard(session: items[i]),
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No workouts yet',
              style: AppTextStyles.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Complete a workout to see your history here.',
              style: AppTextStyles.bodyLg,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session});

  final WorkoutSession session;

  ({Color bg, Color fg}) _iconPalette() {
    switch (session.category) {
      case WorkoutCategory.strength:
        return (
          bg: AppColors.primaryContainer,
          fg: AppColors.onPrimaryContainer
        );
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

  String _dateLabel() {
    final now = DateTime.now();
    final d = session.completedAt;
    if (DateUtils.isSameDay(d, now)) return 'Today';
    if (DateUtils.isSameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('EEE, MMM d').format(d);
  }

  String _subtitle() {
    final mins = (session.durationSeconds / 60).round();
    final timeStr = '$mins min';
    if (session.distanceKm != null) {
      return '${session.distanceKm!.toStringAsFixed(2)} km • $timeStr';
    }
    final exCount = session.exercises.length;
    return '$exCount exercise${exCount == 1 ? '' : 's'} • $timeStr';
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
              child: Icon(session.category.icon, size: 32, color: p.fg),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.title,
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dateLabel()} • ${_subtitle()}',
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
