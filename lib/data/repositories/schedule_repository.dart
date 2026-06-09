import '../../models/workout.dart';

/// Abstract contract for calendar schedule persistence.
abstract class ScheduleRepository {
  /// Returns all workouts whose [Workout.scheduledDate] falls within
  /// [[from], [to]] inclusive (date boundaries, time is ignored).
  Future<List<Workout>> getForDateRange(DateTime from, DateTime to);

  /// Persists a new scheduled workout entry.
  Future<void> schedule(Workout workout);

  /// Hard-delete a scheduled workout by [id].
  Future<void> unschedule(String id);
}
