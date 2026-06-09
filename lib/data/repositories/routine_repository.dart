import '../../models/workout.dart';

/// Abstract contract for routine persistence.
///
/// Swap the implementation (sqflite → remote HTTP, Firestore, Supabase)
/// without touching stores or screens.
abstract class RoutineRepository {
  /// Returns all non-deleted routines with their exercises, ordered by
  /// [Routine.updatedAt] descending.
  Future<List<Routine>> getAll();

  /// Insert or replace a routine and its exercises atomically.
  Future<void> upsert(Routine routine);

  /// Hard-delete a routine by [id] (cascades to exercise_templates).
  Future<void> delete(String id);
}
