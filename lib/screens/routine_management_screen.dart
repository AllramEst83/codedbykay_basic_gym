import 'package:flutter/material.dart';

import '../data/workout_store.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';
import 'create_workout_screen.dart';

/// Shows all [Routine]s for a given [WorkoutCategory] and lets the user
/// create new ones or start an existing one.
class RoutineManagementScreen extends StatefulWidget {
  const RoutineManagementScreen({
    super.key,
    required this.category,
    required this.title,
  });

  final WorkoutCategory category;
  final String title;

  @override
  State<RoutineManagementScreen> createState() =>
      _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen> {
  @override
  void initState() {
    super.initState();
    WorkoutStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    WorkoutStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  List<Routine> get _routines =>
      WorkoutStore.instance.routinesFor(widget.category);

  @override
  Widget build(BuildContext context) {
    final routines = _routines;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.title} Routines',
          style: AppTextStyles.headlineMd,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: Squish(
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: routines.isEmpty
            ? _EmptyState(category: widget.category)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.gutter,
                  AppSpacing.containerMargin,
                  AppSpacing.lg + 80,
                ),
                itemCount: routines.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _RoutineCard(
                  routine: routines[i],
                  onEdit: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => CreateWorkoutScreen(
                          defaultCategory: widget.category,
                          editRoutine: routines[i],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: _CreateFab(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => CreateWorkoutScreen(
                defaultCategory: widget.category,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Routine card
// ────────────────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onEdit});

  final Routine routine;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                routine.category.icon,
                color: AppColors.onPrimaryContainer,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name, style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    '${routine.exerciseCount} exercises',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Squish(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                'Start',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Empty state
// ────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.category});

  final WorkoutCategory category;

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
              child: Icon(category.icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No routines yet',
              style: AppTextStyles.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Tap + to create your first workout routine.',
              style: AppTextStyles.bodyLg,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// FAB
// ────────────────────────────────────────────────────────────────────────

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 30),
      ),
    );
  }
}
