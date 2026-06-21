import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../data/stores/workout_store.dart';
import '../data/utils/routine_runner.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/resume_session_banner.dart';
import '../widgets/squish.dart';
import 'create_workout_screen.dart';
import 'routine_management_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  static const _categories = [
    (
      category: WorkoutCategory.strength,
      name: 'Gym',
    ),
    (
      category: WorkoutCategory.cardio,
      name: 'Running',
    ),
  ];

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

  Future<void> _openAllRoutinesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => const _AllRoutinesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.gutter,
              AppSpacing.containerMargin,
              AppSpacing.lg + 80,
            ),
            children: [
              const ResumeSessionBanner(),
              const _PageHeader(),
              const SizedBox(height: AppSpacing.lg),
              ..._categoryItems(context),
              const SizedBox(height: AppSpacing.xl),
              _RecentUpdatesHeader(
                onSeeAll: WorkoutStore.instance.hasRoutines
                    ? () => _openAllRoutinesSheet(context)
                    : null,
              ),
              const SizedBox(height: AppSpacing.gutter),
              ..._recentItems(context),
            ],
          ),
          Positioned(
            right: AppSpacing.containerMargin,
            bottom: AppSpacing.containerMargin,
            child: _Fab(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateWorkoutScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categoryItems(BuildContext context) {
    final colors = [
      (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      (AppColors.secondaryContainer, AppColors.onSecondaryContainer),
    ];
    return [
      for (var i = 0; i < _categories.length; i++) ...[
        _CategoryRow(
          name: _categories[i].name,
          routines: WorkoutStore.instance
              .routinesFor(_categories[i].category)
              .length,
          category: _categories[i].category,
          iconBg: colors[i].$1,
          iconFg: colors[i].$2,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RoutineManagementScreen(
                category: _categories[i].category,
                title: _categories[i].name,
              ),
            ),
          ),
        ),
        if (i < _categories.length - 1)
          const SizedBox(height: AppSpacing.gutter),
      ],
    ];
  }

  List<Widget> _recentItems(BuildContext context) {
    final recent = WorkoutStore.instance.allSortedByRecent.take(5).toList();
    if (recent.isEmpty) return const [];
    return [
      for (var i = 0; i < recent.length; i++) ...[
        _RecentRow(
          title: recent[i].name,
          subtitle:
              '${recent[i].category.label} • ${recent[i].exerciseCount} exercise${recent[i].exerciseCount == 1 ? '' : 's'}',
          onEdit: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CreateWorkoutScreen(
                  defaultCategory: recent[i].category,
                  editRoutine: recent[i],
                ),
              ),
            );
          },
        ),
        if (i < recent.length - 1) const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workout Types', style: AppTextStyles.displayLgMobile),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Manage your routines and categories.',
          style: AppTextStyles.bodyLg,
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.routines,
    required this.category,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
  });

  final String name;
  final int routines;
  final WorkoutCategory category;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(category.icon, color: iconFg, size: 30),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headlineMd),
                  Text(
                    '$routines Routines',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentUpdatesHeader extends StatelessWidget {
  const _RecentUpdatesHeader({required this.onSeeAll});

  /// `null` hides the "See All" link (e.g. when no routines exist yet).
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Recent Updates', style: AppTextStyles.headlineMd),
        if (onSeeAll != null)
          Squish(
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'See All',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.labelBold),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Squish(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllRoutinesSheet extends StatelessWidget {
  const _AllRoutinesSheet();

  String _subtitle(Routine r) {
    final updated = DateFormat('MMM d').format(r.updatedAt);
    if (r.category == WorkoutCategory.cardio) {
      final km = r.targetKm;
      final detail = km != null ? '${km.toStringAsFixed(1)} km target' : 'Free run';
      return '$detail • Updated $updated';
    }
    final count = r.exerciseCount;
    return '$count exercise${count == 1 ? '' : 's'} • Updated $updated';
  }

  @override
  Widget build(BuildContext context) {
    final routines = WorkoutStore.instance.allSortedByRecent;
    final inset = MediaQuery.of(context).padding.bottom;
    final height = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.md,
                AppSpacing.containerMargin,
                AppSpacing.base,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Routines',
                      style: AppTextStyles.headlineMd,
                    ),
                  ),
                  Squish(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  inset + AppSpacing.md,
                ),
                itemCount: routines.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final r = routines[i];
                  return Squish(
                    onTap: () {
                      Navigator.of(context).pop();
                      RoutineRunner.start(context, r);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: r.category == WorkoutCategory.cardio
                                  ? AppColors.primaryContainer
                                  : AppColors.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              r.category.icon,
                              color: r.category == WorkoutCategory.cardio
                                  ? AppColors.onPrimaryContainer
                                  : AppColors.onSecondaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: AppTextStyles.labelBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _subtitle(r),
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Squish(
                            onTap: () async {
                              Navigator.of(context).pop();
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => CreateWorkoutScreen(
                                    defaultCategory: r.category,
                                    editRoutine: r,
                                  ),
                                ),
                              );
                            },
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.base),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.onPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Start',
                                  style: AppTextStyles.labelBold.copyWith(
                                    color: AppColors.onPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onPressed});

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
