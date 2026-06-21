import 'package:flutter/foundation.dart';

import '../../models/workout.dart';
import '../repositories/routine_repository.dart';

/// In-memory cache for user [Routine]s, backed by [RoutineRepository].
///
/// Screens listen to this [ChangeNotifier] and rebuild when routines change.
/// All mutations write through to the repository so data survives restarts.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._();

  static final WorkoutStore instance = WorkoutStore._();

  late RoutineRepository _repo;
  final List<Routine> _routines = [];

  /// Loads all routines from the repository into the in-memory cache.
  /// Call once in [main] after the database is open.
  Future<void> hydrate(RoutineRepository repo) async {
    _repo = repo;
    final loaded = await repo.getAll();
    _routines
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  /// All routines for [category], in current sort order.
  List<Routine> routinesFor(WorkoutCategory category) =>
      _routines.where((r) => r.category == category).toList();

  /// All routines sorted by most recently updated first.
  List<Routine> get allSortedByRecent => List.of(_routines);

  /// Finds a [Routine] for a calendar [Workout].
  ///
  /// Tries [Workout.routineId] first, then falls back to matching [Workout.title]
  /// and [Workout.category] when the link is missing or stale (e.g. after a
  /// routine was deleted and recreated).
  Routine? resolveRoutine(Workout workout) {
    if (workout.routineId != null) {
      final byId =
          _routines.where((r) => r.id == workout.routineId).firstOrNull;
      if (byId != null) return byId;
    }
    return _routines
        .where(
          (r) => r.name == workout.title && r.category == workout.category,
        )
        .firstOrNull;
  }

  /// Returns the routine with [id], or null if it is not in the cache.
  Routine? routineById(String id) =>
      _routines.where((r) => r.id == id).firstOrNull;

  /// Persists [routine] and adds it to the cache.
  Future<void> addRoutine(Routine routine) async {
    await _repo.upsert(routine);
    _routines.add(routine);
    notifyListeners();
  }

  /// Renames the routine with [id] and writes through.
  Future<void> renameRoutine(String id, String newName) async {
    final index = _routines.indexWhere((r) => r.id == id);
    if (index == -1) throw StateError('Routine $id not found');
    _routines[index].name = newName;
    _routines[index].updatedAt = DateTime.now();
    await _repo.upsert(_routines[index]);
    notifyListeners();
  }

  /// Replaces the routine that has the same [Routine.id] as [updated]
  /// and writes through.
  Future<void> updateRoutine(Routine updated) async {
    final index = _routines.indexWhere((r) => r.id == updated.id);
    if (index == -1) throw StateError('Routine ${updated.id} not found');
    updated.updatedAt = DateTime.now();
    _routines[index] = updated;
    await _repo.upsert(updated);
    notifyListeners();
  }

  /// Hard-deletes the routine with [id] from the DB and cache.
  Future<void> deleteRoutine(String id) async {
    await _repo.delete(id);
    _routines.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
