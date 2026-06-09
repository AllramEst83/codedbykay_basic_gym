import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/category_pill.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/squish.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key, required this.workoutTitle});

  final String workoutTitle;

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final Exercise _exercise;
  Timer? _ticker;
  Duration _elapsed = const Duration(minutes: 45, seconds: 22);
  bool _paused = false;

  final _currentExerciseIndex = 3;
  final _totalExercises = 6;

  @override
  void initState() {
    super.initState();
    _exercise = SampleData.activeExercise();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  void _completeActive() {
    setState(() {
      final idx = _exercise.sets.indexWhere((s) => !s.completed);
      if (idx >= 0) _exercise.sets[idx].completed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _SessionTopBar(
            paused: _paused,
            onPauseToggle: () => setState(() => _paused = !_paused),
            title: widget.workoutTitle,
            elapsed: _formatDuration(_elapsed),
            onSettings: () {},
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.gutter,
                AppSpacing.containerMargin,
                AppSpacing.gutter,
              ),
              children: [
                _ExerciseHeader(
                  muscleGroup: _exercise.muscleGroup,
                  index: _currentExerciseIndex,
                  total: _totalExercises,
                  name: _exercise.name,
                  target: _exercise.targetRepsLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                ..._buildSets(),
                const SizedBox(height: AppSpacing.lg),
                const _RestPreview(seconds: 90),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          _BottomActions(
            onAddNote: () {},
            onFinish: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSets() {
    final activeIdx = _exercise.sets.indexWhere((s) => !s.completed);
    return [
      for (var i = 0; i < _exercise.sets.length; i++) ...[
        _SetRow(
          number: i + 1,
          set: _exercise.sets[i],
          state: _exercise.sets[i].completed
              ? _SetState.completed
              : (i == activeIdx ? _SetState.active : _SetState.upcoming),
          onComplete: _completeActive,
          onWeightChanged: (v) =>
              setState(() => _exercise.sets[i].weightKg = v),
          onRepsChanged: (v) => setState(() => _exercise.sets[i].reps = v),
        ),
        if (i < _exercise.sets.length - 1) const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}

// ────────────────────────────────────────────────────────────────────────
// Top bar
// ────────────────────────────────────────────────────────────────────────

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.paused,
    required this.onPauseToggle,
    required this.title,
    required this.elapsed,
    required this.onSettings,
    required this.onClose,
  });

  final bool paused;
  final VoidCallback onPauseToggle;
  final String title;
  final String elapsed;
  final VoidCallback onSettings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        topInset + AppSpacing.base,
        AppSpacing.containerMargin,
        AppSpacing.base,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest),
        ),
      ),
      child: Row(
        children: [
          Squish(
            onTap: onPauseToggle,
            child: Icon(
              paused
                  ? Icons.play_circle_rounded
                  : Icons.pause_circle_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMd,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsed,
                      style: AppTextStyles.bodyMd,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Squish(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Exercise header
// ────────────────────────────────────────────────────────────────────────

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.muscleGroup,
    required this.index,
    required this.total,
    required this.name,
    required this.target,
  });

  final String muscleGroup;
  final int index;
  final int total;
  final String name;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CategoryPill(label: muscleGroup),
            Text(
              'Exercise $index of $total',
              style: AppTextStyles.bodyMd,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          style: AppTextStyles.displayLgMobile.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Target: $target',
          style: AppTextStyles.bodyLg,
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Set rows
// ────────────────────────────────────────────────────────────────────────

enum _SetState { completed, active, upcoming }

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.number,
    required this.set,
    required this.state,
    required this.onComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final int number;
  final WorkoutSet set;
  final _SetState state;
  final VoidCallback onComplete;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _SetState.active;
    final isCompleted = state == _SetState.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.surfaceContainerHighest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isActive
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              )
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 0),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: state == _SetState.upcoming ? 0.6 : 1,
        child: Row(
          children: [
            _LeadingBadge(state: state, number: number),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _SetField(
                      label: 'Weight (kg)',
                      value: set.weightKg?.toString(),
                      editable: isActive,
                      onChanged: (s) =>
                          onWeightChanged(double.tryParse(s)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SetField(
                      label: 'Reps',
                      value: set.reps?.toString(),
                      editable: isActive,
                      isInteger: true,
                      onChanged: (s) => onRepsChanged(int.tryParse(s)),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: AppSpacing.sm),
              Squish(
                onTap: onComplete,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.onPrimaryContainer,
                    size: 32,
                  ),
                ),
              ),
            ],
            if (isCompleted) const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({required this.state, required this.number});

  final _SetState state;
  final int number;

  @override
  Widget build(BuildContext context) {
    final completed = state == _SetState.completed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: completed ? AppColors.primary : AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(
              Icons.check_rounded,
              color: AppColors.onPrimary,
              size: 24,
            )
          : Text(
              '$number',
              style: AppTextStyles.statNumber.copyWith(
                fontSize: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _SetField extends StatefulWidget {
  const _SetField({
    required this.label,
    required this.value,
    required this.editable,
    required this.onChanged,
    this.isInteger = false,
  });

  final String label;
  final String? value;
  final bool editable;
  final bool isInteger;
  final ValueChanged<String> onChanged;

  @override
  State<_SetField> createState() => _SetFieldState();
}

class _SetFieldState extends State<_SetField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void didUpdateWidget(covariant _SetField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && (widget.value ?? '') != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showValue = widget.value ?? '-';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.outlineVariant,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.label,
            style: AppTextStyles.labelBold.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          if (widget.editable)
            TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.isInteger,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              style: AppTextStyles.statNumber.copyWith(fontSize: 26),
              onChanged: widget.onChanged,
            )
          else
            Text(
              showValue,
              textAlign: TextAlign.center,
              style: AppTextStyles.statNumber.copyWith(
                fontSize: 26,
                color: AppColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Rest preview
// ────────────────────────────────────────────────────────────────────────

class _RestPreview extends StatelessWidget {
  const _RestPreview({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 32,
              color: AppColors.onTertiaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next: Rest Period',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    '$seconds seconds',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onTertiaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Bottom actions
// ────────────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onAddNote, required this.onFinish});

  final VoidCallback onAddNote;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.gutter,
        AppSpacing.containerMargin,
        inset + AppSpacing.gutter,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryPillButton(
              label: 'Add Note',
              background: AppColors.surfaceContainerHighest,
              foreground: AppColors.onSurface,
              onPressed: onAddNote,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: PrimaryPillButton(
              label: 'Finish Workout',
              elevated: true,
              onPressed: onFinish,
            ),
          ),
        ],
      ),
    );
  }
}
