import 'package:sqflite/sqflite.dart';

import '../../models/workout.dart';
import '../repositories/schedule_repository.dart';

class SqfliteScheduleRepository implements ScheduleRepository {
  const SqfliteScheduleRepository(this._db);

  final Database _db;

  /// Converts a [DateTime] to the start-of-day epoch millis used in the DB.
  static int _dayEpoch(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

  @override
  Future<List<Workout>> getForDateRange(DateTime from, DateTime to) async {
    final fromMs = _dayEpoch(from);
    final toMs = _dayEpoch(to) + Duration.millisecondsPerDay - 1;

    final rows = await _db.query(
      'scheduled_workouts',
      where: 'scheduled_date BETWEEN ? AND ?',
      whereArgs: [fromMs, toMs],
      orderBy: 'scheduled_date ASC',
    );

    return rows.map(Workout.fromMap).toList();
  }

  @override
  Future<void> schedule(Workout workout) async {
    await _db.insert(
      'scheduled_workouts',
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> unschedule(String id) async {
    await _db.delete(
      'scheduled_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
