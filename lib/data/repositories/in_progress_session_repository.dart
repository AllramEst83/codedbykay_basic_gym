import '../../models/workout.dart';

/// Abstract contract for in-progress workout session persistence.
abstract class InProgressSessionRepository {
  /// Returns an in-progress session by routine ID, or null if none exists.
  Future<InProgressSession?> getByRoutineId(String routineId);

  /// Saves or updates an in-progress session.
  Future<void> save(InProgressSession session);

  /// Deletes an in-progress session by routine ID.
  Future<void> delete(String routineId);

  /// Returns all in-progress sessions (useful for cleanup/recovery).
  Future<List<InProgressSession>> getAll();
}
