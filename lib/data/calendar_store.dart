import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import 'sample_data.dart';

/// Mutable in-memory store for workouts scheduled to specific days of the month.
///
/// Seeded from [SampleData.workoutsByDay] so the demo calendar has pre-populated
/// data. Screens listen to this [ChangeNotifier] and rebuild when the schedule
/// changes.
class CalendarStore extends ChangeNotifier {
  CalendarStore._()
      : _schedule = {
          for (final e in SampleData.workoutsByDay.entries)
            e.key: List<Workout>.of(e.value),
        };

  static final CalendarStore instance = CalendarStore._();

  final Map<int, List<Workout>> _schedule;

  /// Returns the workouts scheduled for [day] of the current month.
  List<Workout> workoutsForDay(int day) =>
      List<Workout>.unmodifiable(_schedule[day] ?? const []);

  /// Returns [true] if [day] has at least one scheduled workout.
  bool hasWorkoutsOnDay(int day) => _schedule[day]?.isNotEmpty ?? false;

  /// Derived list of category markers for [day] (used for calendar dot indicators).
  List<WorkoutCategory> markersForDay(int day) =>
      workoutsForDay(day).map((w) => w.category).toSet().toList();

  /// Adds [workout] to [day] and notifies listeners.
  void scheduleWorkout(int day, Workout workout) {
    _schedule.update(
      day,
      (existing) => [...existing, workout],
      ifAbsent: () => [workout],
    );
    notifyListeners();
  }

  /// Removes the workout with [workoutId] from [day] and notifies listeners.
  void removeWorkout(int day, String workoutId) {
    final list = _schedule[day];
    if (list == null) return;
    list.removeWhere((w) => w.id == workoutId);
    if (list.isEmpty) _schedule.remove(day);
    notifyListeners();
  }
}
