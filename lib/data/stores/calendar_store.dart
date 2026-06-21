import 'package:flutter/foundation.dart';

import '../../models/workout.dart';
import '../repositories/schedule_repository.dart';

/// In-memory cache for scheduled [Workout]s keyed by local day, backed by
/// [ScheduleRepository].
///
/// Screens listen to this [ChangeNotifier] and rebuild when the schedule changes.
/// All mutations write through to the repository so data survives restarts.
class CalendarStore extends ChangeNotifier {
  CalendarStore._();

  static final CalendarStore instance = CalendarStore._();

  late ScheduleRepository _repo;

  /// Cache keyed by the start-of-day [DateTime] (time zeroed).
  final Map<DateTime, List<Workout>> _schedule = {};

  /// Inclusive lower / upper bounds of the date range currently cached in
  /// [_schedule]. Used by [ensureMonthLoaded] to avoid redundant DB hits.
  DateTime? _loadedRangeStart;
  DateTime? _loadedRangeEnd;

  /// Normalises any [DateTime] to midnight of that day.
  static DateTime _dayKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Loads the current month (+/- 1 month buffer) from the repository.
  /// Call once in [main] after the database is open.
  Future<void> hydrate(ScheduleRepository repo) async {
    _repo = repo;
    await ensureMonthLoaded(DateTime.now());
  }

  /// Loads [month] (and a 1-month buffer either side) if it is not already
  /// cached. Cheap to call repeatedly — does nothing when the window is a
  /// subset of the already-loaded range.
  Future<void> ensureMonthLoaded(DateTime month) async {
    final from = DateTime(month.year, month.month - 1);
    final to = DateTime(month.year, month.month + 2, 0); // last day of +1 mo
    await _ensureRangeLoaded(from, to);
  }

  Future<void> _ensureRangeLoaded(DateTime from, DateTime to) async {
    final wantStart = _dayKey(from);
    final wantEnd = _dayKey(to);

    if (_loadedRangeStart != null &&
        _loadedRangeEnd != null &&
        !wantStart.isBefore(_loadedRangeStart!) &&
        !wantEnd.isAfter(_loadedRangeEnd!)) {
      return;
    }

    final mergedStart =
        _loadedRangeStart == null || wantStart.isBefore(_loadedRangeStart!)
            ? wantStart
            : _loadedRangeStart!;
    final mergedEnd =
        _loadedRangeEnd == null || wantEnd.isAfter(_loadedRangeEnd!)
            ? wantEnd
            : _loadedRangeEnd!;

    final workouts = await _repo.getForDateRange(mergedStart, mergedEnd);
    _schedule.clear();
    for (final w in workouts) {
      final key = _dayKey(w.scheduledDate);
      _schedule.putIfAbsent(key, () => []).add(w);
    }
    _loadedRangeStart = mergedStart;
    _loadedRangeEnd = mergedEnd;
    notifyListeners();
  }

  // ── Read helpers ────────────────────────────────────────────────────────────

  /// Returns the workouts scheduled for the given [date].
  List<Workout> workoutsForDay(DateTime date) =>
      List.unmodifiable(_schedule[_dayKey(date)] ?? const []);

  /// Convenience accessor for calendar UI still passing [int] day-of-month
  /// within the currently displayed month.
  List<Workout> workoutsForDayOfMonth(int day, DateTime displayMonth) =>
      workoutsForDay(DateTime(displayMonth.year, displayMonth.month, day));

  /// [true] if [date] has at least one scheduled workout.
  bool hasWorkoutsOnDay(DateTime date) =>
      _schedule[_dayKey(date)]?.isNotEmpty ?? false;

  /// Derived category markers for [date] (used for calendar dot indicators).
  List<WorkoutCategory> markersForDay(DateTime date) =>
      workoutsForDay(date).map((w) => w.category).toSet().toList();

  // ── Write helpers ───────────────────────────────────────────────────────────

  /// Persists [workout] for [date] and notifies listeners.
  Future<void> scheduleWorkout(DateTime date, Workout workout) async {
    await _repo.schedule(workout);
    final key = _dayKey(date);
    _schedule.update(
      key,
      (existing) => [...existing, workout],
      ifAbsent: () => [workout],
    );
    notifyListeners();
  }

  /// Removes the workout with [workoutId] from [date] and notifies listeners.
  Future<void> removeWorkout(DateTime date, String workoutId) async {
    await _repo.unschedule(workoutId);
    final key = _dayKey(date);
    final list = _schedule[key];
    if (list == null) return;
    list.removeWhere((w) => w.id == workoutId);
    if (list.isEmpty) _schedule.remove(key);
    notifyListeners();
  }

  /// Updates [workout]'s [Workout.routineId] when a stale calendar link is repaired.
  Future<void> relinkRoutine(
    DateTime date,
    Workout workout,
    String routineId,
  ) async {
    if (workout.routineId == routineId) return;

    final updated = Workout(
      id: workout.id,
      routineId: routineId,
      title: workout.title,
      category: workout.category,
      durationMinutes: workout.durationMinutes,
      scheduledDate: workout.scheduledDate,
      createdAt: workout.createdAt,
      updatedAt: DateTime.now(),
    );

    await _repo.schedule(updated);

    final key = _dayKey(date);
    final list = _schedule[key];
    if (list == null) return;
    final index = list.indexWhere((w) => w.id == workout.id);
    if (index == -1) return;
    list[index] = updated;
    notifyListeners();
  }
}
