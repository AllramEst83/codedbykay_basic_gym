import 'dart:async';

import 'package:flutter/material.dart';

import '../data/providers/repository_provider.dart';
import '../data/repositories/in_progress_session_repository.dart';
import '../data/services/session_notification_service.dart';
import '../data/stores/in_progress_session_store.dart';
import '../data/stores/session_store.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/category_pill.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/rest_timer_sheet.dart';
import '../widgets/squish.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({
    super.key,
    required this.routine,
    this.restoredSession,
  });

  final Routine routine;
  final InProgressSession? restoredSession;

  /// Checks if an in-progress session exists for this routine and navigates
  /// to either resume or start fresh.
  static Future<void> start(
    BuildContext context,
    Routine routine,
  ) async {
    final repo = RepositoryProvider.instance.inProgressSessions;
    final existing = await repo.getByRoutineId(routine.id);
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveSessionScreen(
          routine: routine,
          restoredSession: existing,
        ),
      ),
    );
  }

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final List<Exercise> _exercises;
  late int _currentExerciseIndex;
  late int _selectedSetIndex;
  Timer? _ticker;
  Timer? _saveTimer;
  Duration _elapsed = Duration.zero;
  bool _paused = false;
  late final DateTime _startedAt;
  late final InProgressSessionRepository _repo;
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _repo = RepositoryProvider.instance.inProgressSessions;
    
    if (widget.restoredSession != null) {
      _restoreSession(widget.restoredSession!);
    } else {
      _startFreshSession();
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveInProgressSession();
    });

    // Start the foreground service so the session stays alive when the phone
    // is locked. Fire-and-forget; session is already persisted every 5 s.
    _startBackgroundService();
  }

  void _startBackgroundService() {
    final paused = _paused;
    SessionNotificationService.instance.start(
      routineName: widget.routine.name,
      category: widget.routine.category,
      startedAt: _startedAt,
    ).then((_) {
      if (paused) SessionNotificationService.instance.setPaused(true);
    }).catchError((_) {});
  }

  void _restoreSession(InProgressSession session) {
    _sessionId = session.id;
    _startedAt = session.startedAt;
    _elapsed = Duration(seconds: session.elapsedSeconds);
    _paused = session.paused;
    _exercises = session.exercises;
    _currentExerciseIndex = session.currentExerciseIndex;
    _selectedSetIndex = session.selectedSetIndex;
  }

  void _startFreshSession() {
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _startedAt = DateTime.now();
    _exercises = widget.routine.exercises.map((t) {
      return Exercise(
        name: t.name,
        muscleGroup: widget.routine.category.label,
        targetSets: t.sets,
        targetRepsLabel: '${t.sets} Sets x ${t.repsLabel} Reps',
        note: t.note,
        sets: List.generate(
          t.sets,
          (_) => WorkoutSet(weightKg: null, reps: null),
        ),
      );
    }).toList();
    _currentExerciseIndex = 0;
    _selectedSetIndex = _exercises.isEmpty
        ? 0
        : _firstIncompleteSetIndex(_exercises.first);
  }

  Future<void> _saveInProgressSession() async {
    if (!mounted) return;

    try {
      final session = InProgressSession(
        id: _sessionId,
        routineId: widget.routine.id,
        routineName: widget.routine.name,
        routineCategory: widget.routine.category,
        startedAt: _startedAt,
        elapsedSeconds: _elapsed.inSeconds,
        currentExerciseIndex: _currentExerciseIndex,
        selectedSetIndex: _selectedSetIndex,
        paused: _paused,
        exercises: _exercises,
      );
      await _repo.save(session);
      await InProgressSessionStore.instance.refresh();
    } catch (_) {
      // Persistence is best-effort; the 5-second timer will retry shortly.
    }
  }

  Future<void> _deleteInProgressSession() async {
    try {
      await _repo.delete(widget.routine.id);
      await InProgressSessionStore.instance.refresh();
    } catch (_) {
      // Silent fail – the row may not have been persisted yet.
    }
  }

  int _firstIncompleteSetIndex(Exercise exercise) {
    if (exercise.sets.isEmpty) return 0;
    final idx = exercise.sets.indexWhere((s) => !s.completed);
    return idx >= 0 ? idx : exercise.sets.length - 1;
  }

  bool get _hasExercises => _exercises.isNotEmpty;

  bool get _allSetsCompleted {
    if (_exercises.isEmpty) return true;
    for (final exercise in _exercises) {
      if (exercise.sets.any((set) => !set.completed)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveTimer?.cancel();
    SessionNotificationService.instance.stop();
    if (!_allSetsCompleted) {
      _saveInProgressSession();
    }
    super.dispose();
  }

  Exercise get _currentExercise {
    assert(_hasExercises, 'No exercises in this routine');
    return _exercises[_currentExerciseIndex];
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  void _completeActiveSet() {
    final idx = _selectedSetIndex;
    if (idx < 0 || idx >= _currentExercise.sets.length) return;
    if (_currentExercise.sets[idx].completed) return;

    setState(() {
      _currentExercise.sets[idx].completed = true;
      final next = _currentExercise.sets.indexWhere((s) => !s.completed);
      if (next >= 0) _selectedSetIndex = next;
    });

    final allDoneInExercise = _currentExercise.sets.every((s) => s.completed);
    if (allDoneInExercise) {
      final nextExIdx = _currentExerciseIndex + 1;
      if (nextExIdx < _exercises.length) {
        _goToExercise(nextExIdx);
        _showRestTimer();
      }
      // Last exercise: Finish Workout button becomes active; nothing more to do.
      return;
    }

    _showRestTimer();
  }

  void _showRestTimer() {
    if (!mounted) return;
    RestTimerSheet.show(context);
  }

  void _selectSet(int index) {
    setState(() => _selectedSetIndex = index);
  }

  void _goToExercise(int index) {
    if (index < 0 || index >= _exercises.length) return;
    setState(() {
      _currentExerciseIndex = index;
      _selectedSetIndex = _firstIncompleteSetIndex(_currentExercise);
    });
  }

  Future<void> _editExerciseNote() async {
    final controller = TextEditingController(text: _currentExercise.note ?? '');
    
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Exercise Note', style: AppTextStyles.headlineMd),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a note for this exercise…',
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      
      if (saved == true && mounted) {
        final text = controller.text.trim();
        setState(() => _currentExercise.note = text.isEmpty ? null : text);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openSessionMenu() async {
    final result = await showModalBottomSheet<_MenuAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.md,
            AppSpacing.containerMargin,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Session Options', style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.md),
              _MenuRow(
                icon: Icons.flag_rounded,
                title: 'Finish now',
                subtitle:
                    'Save the workout with the sets you have completed so far.',
                onTap: () => Navigator.of(ctx).pop(_MenuAction.finishEarly),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuRow(
                icon: Icons.timer_rounded,
                title: 'Start rest timer',
                subtitle: 'Open the countdown timer without completing a set.',
                onTap: () => Navigator.of(ctx).pop(_MenuAction.openRest),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuRow(
                icon: Icons.delete_outline_rounded,
                title: 'Discard session',
                subtitle:
                    'Throw away the in-progress data without saving a record.',
                destructive: true,
                onTap: () => Navigator.of(ctx).pop(_MenuAction.discard),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;
    switch (result) {
      case _MenuAction.finishEarly:
        await _finishWorkout();
        break;
      case _MenuAction.openRest:
        _showRestTimer();
        break;
      case _MenuAction.discard:
        await _discardSession();
        break;
    }
  }

  Future<void> _discardSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Discard session?', style: AppTextStyles.headlineMd),
        content: const Text(
          'Your progress for this session will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _ticker?.cancel();
    _saveTimer?.cancel();
    await SessionNotificationService.instance.stop();
    await _deleteInProgressSession();

    // Mark all sets completed in-memory so [dispose] does NOT re-save the
    // in-progress session after we navigate away.
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.completed = true;
      }
    }

    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _finishWorkout() async {
    _ticker?.cancel();
    _saveTimer?.cancel();
    await SessionNotificationService.instance.stop();
    final completedAt = DateTime.now();

    final sessionExercises = <SessionExercise>[];
    for (var ei = 0; ei < _exercises.length; ei++) {
      final ex = _exercises[ei];
      final exId = '${_sessionId}_ex$ei';
      final sets = <SessionSet>[];
      for (var si = 0; si < ex.sets.length; si++) {
        final ws = ex.sets[si];
        sets.add(SessionSet(
          id: '${exId}_set$si',
          exerciseId: exId,
          orderIndex: si,
          weightKg: ws.weightKg,
          reps: ws.reps,
          completed: ws.completed,
        ));
      }
      sessionExercises.add(SessionExercise(
        id: exId,
        sessionId: _sessionId,
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        orderIndex: ei,
        note: ex.note,
        sets: sets,
      ));
    }

    final session = WorkoutSession(
      id: _sessionId,
      routineId: widget.routine.id,
      title: widget.routine.name,
      category: widget.routine.category,
      durationSeconds: _elapsed.inSeconds,
      startedAt: _startedAt,
      completedAt: completedAt,
      exercises: sessionExercises,
    );

    await SessionStore.instance.save(session);
    await _deleteInProgressSession();

    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _SessionTopBar(
            paused: _paused,
            onPauseToggle: () {
              setState(() => _paused = !_paused);
              SessionNotificationService.instance.setPaused(_paused);
            },
            title: widget.routine.name,
            elapsed: _formatDuration(_elapsed),
            onSettings: _openSessionMenu,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: _hasExercises
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.gutter,
                      AppSpacing.containerMargin,
                      AppSpacing.gutter,
                    ),
                    children: [
                      _ExerciseHeader(
                        muscleGroup: _currentExercise.muscleGroup,
                        index: _currentExerciseIndex + 1,
                        total: _exercises.length,
                        name: _currentExercise.name,
                        target: _currentExercise.targetRepsLabel,
                        note: _currentExercise.note,
                        canGoBack: _currentExerciseIndex > 0,
                        canGoForward:
                            _currentExerciseIndex < _exercises.length - 1,
                        onPrevious: () =>
                            _goToExercise(_currentExerciseIndex - 1),
                        onNext: () =>
                            _goToExercise(_currentExerciseIndex + 1),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._buildSets(),
                      const SizedBox(height: AppSpacing.lg),
                      _RestPreview(
                        seconds: 90,
                        onTap: _showRestTimer,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  )
                : _NoExercisesBody(routineName: widget.routine.name),
          ),
          _BottomActions(
            onAddNote: _hasExercises ? _editExerciseNote : null,
            hasNote: _hasExercises &&
                (_currentExercise.note ?? '').isNotEmpty,
            onFinish: _finishWorkout,
            canFinish: _allSetsCompleted,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSets() {
    return [
      for (var i = 0; i < _currentExercise.sets.length; i++) ...[
        _SetRow(
          number: i + 1,
          set: _currentExercise.sets[i],
          state: _setStateFor(i),
          onTap: () => _selectSet(i),
          onComplete: _completeActiveSet,
          onWeightChanged: (v) =>
              setState(() => _currentExercise.sets[i].weightKg = v),
          onRepsChanged: (v) =>
              setState(() => _currentExercise.sets[i].reps = v),
        ),
        if (i < _currentExercise.sets.length - 1)
          const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

  _SetState _setStateFor(int index) {
    if (_currentExercise.sets[index].completed) return _SetState.completed;
    if (index == _selectedSetIndex) return _SetState.active;
    return _SetState.upcoming;
  }
}

class _NoExercisesBody extends StatelessWidget {
  const _NoExercisesBody({required this.routineName});

  final String routineName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.gutter,
        AppSpacing.containerMargin,
        AppSpacing.gutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routineName,
            style: AppTextStyles.displayLgMobile.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'This workout has no exercises yet. Edit the routine to add '
              'exercises, or tap Finish Workout to log the session.',
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
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
                    Text(elapsed, style: AppTextStyles.bodyMd),
                  ],
                ),
              ],
            ),
          ),
          Squish(
            onTap: onSettings,
            child: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(
                Icons.more_vert_rounded,
                color: AppColors.primary,
                size: 28,
              ),
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
    required this.note,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final String muscleGroup;
  final int index;
  final int total;
  final String name;
  final String target;
  final String? note;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CategoryPill(label: muscleGroup),
            if (total > 1)
              Row(
                children: [
                  Squish(
                    onTap: canGoBack ? onPrevious : null,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: canGoBack
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                      size: 28,
                    ),
                  ),
                  Text('Exercise $index of $total', style: AppTextStyles.bodyMd),
                  Squish(
                    onTap: canGoForward ? onNext : null,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: canGoForward
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                      size: 28,
                    ),
                  ),
                ],
              )
            else
              Text('Exercise $index of $total', style: AppTextStyles.bodyMd),
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
        Text('Target: $target', style: AppTextStyles.bodyLg),
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(note!, style: AppTextStyles.bodyMd),
                ),
              ],
            ),
          ),
        ],
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
    required this.onTap,
    required this.onComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final int number;
  final WorkoutSet set;
  final _SetState state;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _SetState.active;
    final isCompleted = state == _SetState.completed;

    return Squish(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
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
                        onChanged: (s) => onWeightChanged(double.tryParse(s)),
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
          ? const Icon(Icons.check_rounded,
              color: AppColors.onPrimary, size: 24)
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
    if (old.value != widget.value &&
        (widget.value ?? '') != _controller.text) {
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
  const _RestPreview({required this.seconds, required this.onTap});

  final int seconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onTap,
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
                      color:
                          AppColors.onTertiaryContainer.withValues(alpha: 0.85),
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

enum _MenuAction { finishEarly, openRest, discard }

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.error : AppColors.onSurface;
    return Squish(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.errorContainer.withValues(alpha: 0.6)
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: destructive
                    ? AppColors.error
                    : AppColors.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelBold.copyWith(
                      color: fg,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onAddNote,
    required this.hasNote,
    required this.onFinish,
    required this.canFinish,
  });

  final VoidCallback? onAddNote;
  final bool hasNote;
  final VoidCallback onFinish;
  final bool canFinish;

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
        border:
            Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
      ),
      child: Row(
        children: [
          if (onAddNote != null) ...[
            Expanded(
              child: PrimaryPillButton(
                label: hasNote ? 'Edit Note' : 'Add Note',
                background: AppColors.surfaceContainerHighest,
                foreground: AppColors.onSurface,
                onPressed: onAddNote,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: onAddNote != null ? 2 : 1,
            child: PrimaryPillButton(
              label: 'Finish Workout',
              elevated: true,
              onPressed: canFinish ? onFinish : null,
            ),
          ),
        ],
      ),
    );
  }
}
