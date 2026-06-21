import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stores/session_store.dart';
import '../data/utils/progress_stats.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/category_pill.dart';
import '../widgets/squish.dart';

/// Detail view for a completed [WorkoutSession].
///
/// Shows the full breakdown of exercises, sets, weights, reps, distance and
/// any saved notes. Allows the user to delete the record.
class SessionDetailsScreen extends StatelessWidget {
  const SessionDetailsScreen({super.key, required this.session});

  final WorkoutSession session;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete session?', style: AppTextStyles.headlineMd),
        content: Text(
          'Remove this completed workout? This cannot be undone.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SessionStore.instance.delete(session.id);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout removed from history.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Session Details', style: AppTextStyles.headlineMd),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: Squish(
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.gutter,
            AppSpacing.containerMargin,
            AppSpacing.lg,
          ),
          children: [
            _HeaderCard(session: session),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(session: session),
            const SizedBox(height: AppSpacing.lg),
            if (session.category == WorkoutCategory.cardio)
              _CardioSection(session: session)
            else
              _StrengthSection(session: session),
            if ((session.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _NotesCard(notes: session.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Header
// ────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.session});

  final WorkoutSession session;

  ({Color bg, Color glow, Color titleFg}) _palette() {
    switch (session.category) {
      case WorkoutCategory.cardio:
        return (
          bg: AppColors.primaryContainer,
          glow: AppColors.primaryFixedDim,
          titleFg: AppColors.onPrimaryFixed,
        );
      case WorkoutCategory.yoga:
        return (
          bg: AppColors.tertiaryContainer,
          glow: AppColors.tertiaryFixedDim,
          titleFg: AppColors.onTertiaryFixed,
        );
      case WorkoutCategory.strength:
        return (
          bg: AppColors.secondaryContainer,
          glow: AppColors.secondaryFixedDim,
          titleFg: AppColors.onSecondaryFixed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final dateText =
        DateFormat('EEEE, MMM d • h:mm a').format(session.completedAt);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: p.glow.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryPill(
                label: session.category.label,
                background: AppColors.surfaceContainerLowest
                    .withValues(alpha: 0.7),
                foreground: p.titleFg,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                session.title,
                style: AppTextStyles.displayLgMobile.copyWith(
                  color: p.titleFg,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                dateText,
                style: AppTextStyles.bodyMd.copyWith(color: p.titleFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Summary stat tiles
// ────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.session});

  final WorkoutSession session;

  String _formatDuration() {
    final secs = session.durationSeconds;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatDurationUnit() {
    final h = session.durationSeconds ~/ 3600;
    return h > 0 ? 'h:m' : 'm:s';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTile>[
      _StatTile(
        icon: Icons.timer_outlined,
        label: 'Duration',
        value: _formatDuration(),
        unit: _formatDurationUnit(),
      ),
      _StatTile(
        icon: Icons.local_fire_department_outlined,
        label: 'Calories',
        value: estimateSessionCalories(session).toString(),
        unit: 'kcal',
      ),
    ];

    if (session.distanceKm != null) {
      tiles.add(_StatTile(
        icon: Icons.straighten_rounded,
        label: 'Distance',
        value: session.distanceKm!.toStringAsFixed(2),
        unit: 'km',
      ));
    } else {
      final volume = sessionVolumeKg(session);
      tiles.add(_StatTile(
        icon: Icons.fitness_center_outlined,
        label: 'Volume',
        value: volume == 0
            ? '0'
            : NumberFormat('#,###').format(volume.round()),
        unit: 'kg',
      ));
    }

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i < tiles.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.statNumber.copyWith(fontSize: 22),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Cardio details
// ────────────────────────────────────────────────────────────────────────

class _CardioSection extends StatelessWidget {
  const _CardioSection({required this.session});

  final WorkoutSession session;

  String _averagePace() {
    final km = session.distanceKm;
    if (km == null || km <= 0 || session.durationSeconds <= 0) {
      return '--:-- /km';
    }
    final speedKmh = km / (session.durationSeconds / 3600);
    if (speedKmh < 0.1) return '--:-- /km';
    final minPerKm = 60.0 / speedKmh;
    final min = minPerKm.floor();
    final sec = ((minPerKm - min) * 60).round().clamp(0, 59);
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context) {
    final km = session.distanceKm ?? 0;
    final target = session.targetKm;
    final progress = (target != null && target > 0)
        ? (km / target).clamp(0.0, 1.0)
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Run Details', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                label: 'Avg Pace',
                value: _averagePace(),
              ),
              if (target != null)
                _MiniStat(
                  label: 'Target',
                  value: '${target.toStringAsFixed(1)} km',
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}% of goal',
              style: AppTextStyles.bodyMd.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.statNumber.copyWith(fontSize: 22),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Strength details — list of exercises with completed sets
// ────────────────────────────────────────────────────────────────────────

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    if (session.exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          'No exercises were recorded for this session.',
          style: AppTextStyles.bodyMd,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exercises', style: AppTextStyles.headlineMd),
        const SizedBox(height: AppSpacing.gutter),
        for (var i = 0; i < session.exercises.length; i++) ...[
          _ExerciseCard(exercise: session.exercises[i]),
          if (i < session.exercises.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final SessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final completed = exercise.sets.where((s) => s.completed).length;
    final total = exercise.sets.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: AppTextStyles.labelBold.copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: completed == total
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$completed / $total sets',
                    style: AppTextStyles.labelBold.copyWith(
                      color: completed == total
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if ((exercise.note ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      exercise.note!,
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          for (var i = 0; i < exercise.sets.length; i++)
            _SetRow(index: i + 1, set: exercise.sets[i]),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.index, required this.set});

  final int index;
  final SessionSet set;

  String _weightText() {
    final w = set.weightKg;
    if (w == null) return '—';
    if (w == w.roundToDouble()) return '${w.toStringAsFixed(0)} kg';
    return '${w.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: set.completed
                  ? AppColors.primary
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: set.completed
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.onPrimary,
                    size: 16,
                  )
                : Text(
                    '$index',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Set $index',
              style: AppTextStyles.bodyMd,
            ),
          ),
          Text(
            _weightText(),
            style: AppTextStyles.labelBold,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            set.reps == null ? '— reps' : '${set.reps} reps',
            style: AppTextStyles.labelBold,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Notes
// ────────────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.onTertiaryContainer,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Notes',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            notes,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
