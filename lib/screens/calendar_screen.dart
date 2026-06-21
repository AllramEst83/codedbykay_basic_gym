import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/stores/calendar_store.dart';
import '../data/stores/session_store.dart';
import '../data/stores/workout_store.dart';
import '../data/utils/routine_runner.dart';
import '../data/utils/session_completion.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/category_pill.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/resume_session_banner.dart';
import '../widgets/squish.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  CalendarView _view = CalendarView.month;
  late DateTime _displayMonth;
  late DateTime _selectedDate;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDate = now;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    CalendarStore.instance.addListener(_onStoreChanged);
    SessionStore.instance.addListener(_onStoreChanged);
    WorkoutStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    CalendarStore.instance.removeListener(_onStoreChanged);
    SessionStore.instance.removeListener(_onStoreChanged);
    WorkoutStore.instance.removeListener(_onStoreChanged);
    _entranceController.dispose();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  Animation<double> _delayedFade(double start, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  List<Workout> get _workoutsForSelected =>
      CalendarStore.instance.workoutsForDay(_selectedDate);

  /// Builds a marker map for every day 1–31 of the displayed month.
  Map<int, List<WorkoutCategory>> get _markerData => {
        for (int d = 1; d <= 31; d++) ...() {
          final date =
              DateTime(_displayMonth.year, _displayMonth.month, d);
          if (CalendarStore.instance.hasWorkoutsOnDay(date)) {
            return {d: CalendarStore.instance.markersForDay(date)};
          }
          return {};
        }(),
      };

  void _showAddWorkoutSheet() {
    final routines = [
      ...WorkoutStore.instance.routinesFor(WorkoutCategory.strength),
      ...WorkoutStore.instance.routinesFor(WorkoutCategory.cardio),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => _AddWorkoutSheet(
        routines: routines,
        selectedDate: _selectedDate,
      ),
    );
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(_displayMonth.year, _displayMonth.month, day);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _displayMonth = DateTime(date.year, date.month);
    });
    CalendarStore.instance.ensureMonthLoaded(_displayMonth);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_displayMonth.year, _displayMonth.month + delta);
    setState(() {
      _displayMonth = next;
      // If the selected date is no longer in the visible month, jump it to
      // the first day so the "selected" highlight stays meaningful.
      if (_selectedDate.year != next.year ||
          _selectedDate.month != next.month) {
        _selectedDate = DateTime(next.year, next.month, 1);
      }
    });
    CalendarStore.instance.ensureMonthLoaded(_displayMonth);
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _displayMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
    CalendarStore.instance.ensureMonthLoaded(_displayMonth);
  }

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
          const ResumeSessionBanner(),
          _SlideUp(
            animation: _delayedFade(0.0, 0.55),
            child: _Header(
              month: _displayMonth,
              view: _view,
              onViewChanged: (v) => setState(() => _view = v),
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onTitleTap: _jumpToToday,
              showJumpToToday: _displayMonth.year != DateTime.now().year ||
                  _displayMonth.month != DateTime.now().month,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SlideUp(
            animation: _delayedFade(0.15, 0.75),
            child: _buildCalendarSection(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SlideUp(
            animation: _delayedFade(0.3, 1.0),
            child: _SelectedDayWorkouts(
              date: _selectedDate,
              workouts: _workoutsForSelected,
              onAdd: _showAddWorkoutSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final markers = _markerData;
    switch (_view) {
      case CalendarView.month:
        return _CalendarCard(
          month: _displayMonth,
          selectedDate: _selectedDate,
          onSelectDay: _selectDay,
          markerData: markers,
        );
      case CalendarView.week:
        return _WeekStrip(
          date: _selectedDate,
          onSelectDay: _selectDate,
          markerData: markers,
        );
      case CalendarView.day:
        return _DayHeader(date: _selectedDate);
    }
  }
}

// ────────────────────────────────────────────────────────────────────────
// Header (month title + segmented view picker)
// ────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.view,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleTap,
    required this.showJumpToToday,
  });

  final DateTime month;
  final CalendarView view;
  final ValueChanged<CalendarView> onViewChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;
  final bool showJumpToToday;

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('MMMM yyyy').format(month);
    return Column(
      children: [
        Row(
          children: [
            _MonthArrow(
              icon: Icons.chevron_left_rounded,
              onTap: onPrevious,
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Squish(
                onTap: onTitleTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLgMobile,
                  ),
                ),
              ),
            ),
            _MonthArrow(
              icon: Icons.chevron_right_rounded,
              onTap: onNext,
              tooltip: 'Next month',
            ),
          ],
        ),
        if (showJumpToToday) ...[
          const SizedBox(height: AppSpacing.xs),
          Squish(
            onTap: onTitleTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.today_rounded,
                    size: 14,
                    color: AppColors.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Jump to today',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.gutter),
        _ViewSegmentedControl(view: view, onChanged: onViewChanged),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Squish(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _ViewSegmentedControl extends StatelessWidget {
  const _ViewSegmentedControl({required this.view, required this.onChanged});

  final CalendarView view;
  final ValueChanged<CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: CalendarView.values.map((v) {
          final selected = v == view;
          return Expanded(
            child: Squish(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  switch (v) {
                    CalendarView.month => 'Month',
                    CalendarView.week => 'Week',
                    CalendarView.day => 'Day',
                  },
                  style: AppTextStyles.labelBold.copyWith(
                    color: selected
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Month calendar grid
// ────────────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.month,
    required this.selectedDate,
    required this.onSelectDay,
    required this.markerData,
  });

  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<int> onSelectDay;
  final Map<int, List<WorkoutCategory>> markerData;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmpty = firstDayOfMonth.weekday % 7; // Sunday-first
    final today = DateTime.now();
    final showSelected =
        selectedDate.year == month.year && selectedDate.month == month.month;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppTextStyles.labelBold.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              if (i < leadingEmpty) return const SizedBox.shrink();
              final day = i - leadingEmpty + 1;
              final markers = markerData[day] ?? const [];
              final isSelected = showSelected && day == selectedDate.day;
              final isToday = today.year == month.year &&
                  today.month == month.month &&
                  today.day == day;
              return _CalendarDay(
                day: day,
                markers: markers,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => onSelectDay(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.markers,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final List<WorkoutCategory> markers;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  Color _markerColor(WorkoutCategory c) {
    switch (c) {
      case WorkoutCategory.strength:
        return AppColors.primary;
      case WorkoutCategory.cardio:
        return AppColors.primaryContainer;
      case WorkoutCategory.yoga:
        return AppColors.tertiaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onTap,
      scale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isToday
                  ? AppColors.primaryContainer.withValues(alpha: 0.5)
                  : AppColors.surfaceContainerLow),
          shape: BoxShape.circle,
          border: !isSelected && isToday
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: AppTextStyles.labelBold.copyWith(
                color: isSelected
                    ? AppColors.onPrimary
                    : (isToday
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant),
                fontSize: 14,
              ),
            ),
            if (markers.isNotEmpty)
              Positioned(
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in markers.take(3))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : _markerColor(m),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Week strip view
// ────────────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.date,
    required this.onSelectDay,
    required this.markerData,
  });

  final DateTime date;
  final ValueChanged<DateTime> onSelectDay;
  final Map<int, List<WorkoutCategory>> markerData;

  @override
  Widget build(BuildContext context) {
    // Find the Sunday of the week containing [date].
    final weekdayOffset = date.weekday % 7; // Sunday = 0
    final sunday = date.subtract(Duration(days: weekdayOffset));
    final days = List.generate(7, (i) => sunday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: days.map((d) {
          final isSelected = DateUtils.isSameDay(d, date);
          final hasWorkout =
              (markerData[d.day]?.isNotEmpty ?? false) && d.month == date.month;
          return Expanded(
            child: Squish(
              onTap: () => onSelectDay(d),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(d)[0],
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.day}',
                      style: AppTextStyles.labelBold.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasWorkout
                          ? AppColors.primaryContainer
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Day view header
// ────────────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: AppTextStyles.statNumber.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(date),
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(date),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Workouts for the selected day
// ────────────────────────────────────────────────────────────────────────

class _SelectedDayWorkouts extends StatelessWidget {
  const _SelectedDayWorkouts({
    required this.date,
    required this.workouts,
    required this.onAdd,
  });

  final DateTime date;
  final List<Workout> workouts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final label =
        isToday ? "Today's Workouts" : DateFormat('EEE, MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.headlineMd),
              Squish(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: AppColors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (workouts.isEmpty)
          _EmptyDay()
        else
          for (final w in workouts) ...[
            _WorkoutCard(
              workout: w,
              date: date,
              completionStatus: completionStatusForWorkout(
                w,
                SessionStore.instance.sessions,
                date,
              ),
              onRemove: () =>
                  CalendarStore.instance.removeWorkout(date, w.id),
            ),
            const SizedBox(height: AppSpacing.gutter),
          ],
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
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
              Icons.event_available_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No workouts scheduled',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Workout card
// ────────────────────────────────────────────────────────────────────────

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.status});

  final WorkoutCompletionStatus status;

  @override
  Widget build(BuildContext context) {
    final complete = status == WorkoutCompletionStatus.complete;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: complete
            ? AppColors.primary
            : AppColors.tertiaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        complete ? Icons.check_rounded : Icons.pending_actions_rounded,
        size: complete ? 16 : 18,
        color: complete
            ? AppColors.onPrimary
            : AppColors.onTertiaryContainer,
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.date,
    required this.completionStatus,
    required this.onRemove,
  });

  final Workout workout;
  final DateTime date;
  final WorkoutCompletionStatus? completionStatus;
  final VoidCallback onRemove;

  Future<void> _startWorkout(BuildContext context) async {
    final routine = WorkoutStore.instance.resolveRoutine(workout);

    if (routine == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not find this routine. Remove and re-add it from the calendar.',
          ),
        ),
      );
      return;
    }

    if (workout.routineId != routine.id) {
      await CalendarStore.instance.relinkRoutine(date, workout, routine.id);
    }

    if (!context.mounted) return;
    await RoutineRunner.start(context, routine);
  }

  ({Color bg, Color glow, Color titleFg, Color labelFg, Color buttonBg, Color buttonFg})
      _palette() {
    if (workout.category == WorkoutCategory.cardio) {
      return (
        bg: AppColors.primaryContainer,
        glow: AppColors.primaryFixedDim,
        titleFg: AppColors.onPrimaryFixed,
        labelFg: AppColors.onPrimaryContainer,
        buttonBg: AppColors.onPrimaryFixed,
        buttonFg: AppColors.surfaceContainerLowest,
      );
    }
    return (
      bg: AppColors.secondaryContainer,
      glow: AppColors.secondaryFixedDim,
      titleFg: AppColors.onSecondaryFixed,
      labelFg: AppColors.onSecondaryContainer,
      buttonBg: AppColors.onSecondaryFixed,
      buttonFg: AppColors.surfaceContainerLowest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
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
            right: -24,
            top: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: p.glow.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryPill(
                              label: workout.category.label,
                              background: AppColors.surfaceContainerLowest
                                  .withValues(alpha: 0.6),
                              foreground: p.labelFg,
                            ),
                            if (completionStatus != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              _CompletionBadge(status: completionStatus!),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          workout.title,
                          style: AppTextStyles.headlineMd.copyWith(
                            color: p.titleFg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: p.labelFg,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${workout.durationMinutes} min',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: p.labelFg,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          workout.category.icon,
                          color: p.titleFg,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Squish(
                        onTap: onRemove,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          width: 48,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest
                                .withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: p.titleFg.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryPillButton(
                label: 'Start Workout',
                background: p.buttonBg,
                foreground: p.buttonFg,
                height: 48,
                onPressed: () => _startWorkout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Add-workout bottom sheet
// ────────────────────────────────────────────────────────────────────────

class _AddWorkoutSheet extends StatelessWidget {
  const _AddWorkoutSheet({
    required this.routines,
    required this.selectedDate,
  });

  final List<Routine> routines;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            child: Text('Schedule a Workout', style: AppTextStyles.headlineMd),
          ),
          if (routines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No routines available.\nCreate one from the Workouts tab first.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  AppSpacing.md,
                ),
                itemCount: routines.length,
                separatorBuilder: (context2, index2) =>
                    const SizedBox(height: AppSpacing.base),
                itemBuilder: (_, i) {
                  final r = routines[i];
                  return Squish(
                    onTap: () {
                      final now = DateTime.now();
                      final workout = Workout(
                        id: '${r.id}_${now.millisecondsSinceEpoch}',
                        routineId: r.id,
                        title: r.name,
                        category: r.category,
                        durationMinutes:
                            (r.exercises.fold(0, (acc, e) => acc + e.sets * 5))
                                .clamp(15, 120),
                        scheduledDate: selectedDate,
                      );
                      CalendarStore.instance.scheduleWorkout(
                          selectedDate, workout);
                      Navigator.of(context).pop();
                    },
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
                              color: AppColors.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              r.category.icon,
                              color: AppColors.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: AppTextStyles.labelBold),
                                Text(
                                  '${r.exerciseCount} exercises',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
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
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Slide-up entrance helper
// ────────────────────────────────────────────────────────────────────────

class _SlideUp extends StatelessWidget {
  const _SlideUp({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
