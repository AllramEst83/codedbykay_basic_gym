import 'package:flutter/foundation.dart';

import '../models/workout.dart';

/// In-memory store for user-created [Routine]s.
///
/// Screens listen to this [ChangeNotifier] and rebuild when routines change.
/// Seed data mimics an existing user library.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._() : _routines = List.of(_seed);

  /// Singleton instance — screens share one store for the lifetime of the app.
  static final WorkoutStore instance = WorkoutStore._();

  final List<Routine> _routines;

  /// All routines for [category], in insertion order.
  List<Routine> routinesFor(WorkoutCategory category) =>
      _routines.where((r) => r.category == category).toList();

  /// Adds [routine] and notifies listeners.
  void addRoutine(Routine routine) {
    _routines.add(routine);
    notifyListeners();
  }

  /// Renames the routine with [id] and notifies listeners.
  void renameRoutine(String id, String newName) {
    final r = _routines.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('not found'),
    );
    r.name = newName;
    notifyListeners();
  }

  /// Replaces the routine that has the same [Routine.id] as [updated] and
  /// notifies listeners.
  void updateRoutine(Routine updated) {
    final index = _routines.indexWhere((r) => r.id == updated.id);
    if (index == -1) throw StateError('Routine ${updated.id} not found');
    _routines[index] = updated;
    notifyListeners();
  }

  static final List<Routine> _seed = [
    Routine(
      id: 'gym-push',
      name: 'Push Day',
      category: WorkoutCategory.strength,
      exercises: const [
        ExerciseTemplate(name: 'Bench Press', sets: 4, repsLabel: '8-10'),
        ExerciseTemplate(name: 'Shoulder Press', sets: 3, repsLabel: '10-12'),
        ExerciseTemplate(name: 'Tricep Pushdown', sets: 3, repsLabel: '12-15'),
      ],
    ),
    Routine(
      id: 'gym-pull',
      name: 'Pull Day',
      category: WorkoutCategory.strength,
      exercises: const [
        ExerciseTemplate(name: 'Barbell Row', sets: 4, repsLabel: '6-8'),
        ExerciseTemplate(name: 'Pull-Up', sets: 3, repsLabel: '8-10'),
        ExerciseTemplate(name: 'Bicep Curl', sets: 3, repsLabel: '12-15'),
      ],
    ),
    Routine(
      id: 'gym-legs',
      name: 'Leg Day',
      category: WorkoutCategory.strength,
      exercises: const [
        ExerciseTemplate(name: 'Squat', sets: 4, repsLabel: '6-8'),
        ExerciseTemplate(name: 'Romanian Deadlift', sets: 3, repsLabel: '8-10'),
        ExerciseTemplate(name: 'Leg Press', sets: 3, repsLabel: '12'),
        ExerciseTemplate(name: 'Calf Raise', sets: 4, repsLabel: '15-20'),
      ],
    ),
    Routine(
      id: 'gym-upper',
      name: 'Upper Body Power',
      category: WorkoutCategory.strength,
      exercises: const [
        ExerciseTemplate(name: 'Incline Bench Press', sets: 4, repsLabel: '5'),
        ExerciseTemplate(name: 'Weighted Pull-Up', sets: 4, repsLabel: '5'),
        ExerciseTemplate(name: 'Overhead Press', sets: 3, repsLabel: '5'),
      ],
    ),
    Routine(
      id: 'run-5k',
      name: 'Morning 5K',
      category: WorkoutCategory.cardio,
      exercises: const [
        ExerciseTemplate(name: '5K Run', sets: 1, repsLabel: '30 min'),
      ],
    ),
    Routine(
      id: 'run-intervals',
      name: 'Sprint Intervals',
      category: WorkoutCategory.cardio,
      exercises: const [
        ExerciseTemplate(name: 'Warm-up Jog', sets: 1, repsLabel: '5 min'),
        ExerciseTemplate(name: '200m Sprint', sets: 8, repsLabel: '30 sec'),
        ExerciseTemplate(name: 'Cool-down Walk', sets: 1, repsLabel: '5 min'),
      ],
    ),
    Routine(
      id: 'run-long',
      name: 'Long Run',
      category: WorkoutCategory.cardio,
      exercises: const [
        ExerciseTemplate(name: 'Easy Pace Run', sets: 1, repsLabel: '60 min'),
      ],
    ),
  ];
}
