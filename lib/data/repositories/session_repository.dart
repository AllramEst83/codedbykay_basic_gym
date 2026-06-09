import '../../models/workout.dart';

/// Abstract contract for completed workout session persistence.
abstract class SessionRepository {
  /// Returns completed sessions, newest first.
  /// Pass [limit] to cap the result (e.g. for the home preview list).
  Future<List<WorkoutSession>> getAll({int? limit});

  /// Persists a newly completed session with all its exercises and sets.
  Future<void> save(WorkoutSession session);
}
