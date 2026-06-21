import 'package:sqflite/sqflite.dart';

import '../../models/workout.dart';
import '../repositories/session_repository.dart';

class SqfliteSessionRepository implements SessionRepository {
  const SqfliteSessionRepository(this._db);

  final Database _db;

  @override
  Future<List<WorkoutSession>> getAll({int? limit}) async {
    final sessionRows = await _db.query(
      'workout_sessions',
      orderBy: 'completed_at DESC',
      limit: limit,
    );

    final sessions = <WorkoutSession>[];
    for (final row in sessionRows) {
      final sessionId = row['id'] as String;

      final exerciseRows = await _db.query(
        'session_exercises',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'order_index ASC',
      );

      final exercises = <SessionExercise>[];
      for (final exRow in exerciseRows) {
        final exId = exRow['id'] as String;
        final setRows = await _db.query(
          'session_sets',
          where: 'exercise_id = ?',
          whereArgs: [exId],
          orderBy: 'order_index ASC',
        );
        final sets = setRows.map(SessionSet.fromMap).toList();
        exercises.add(SessionExercise.fromMap(exRow, sets));
      }

      sessions.add(WorkoutSession.fromMap(row, exercises));
    }

    return sessions;
  }

  @override
  Future<void> delete(String id) async {
    // Cascade on foreign keys removes child exercises and sets, since the
    // PRAGMA foreign_keys = ON is set in [AppDatabase._onConfigure].
    await _db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> save(WorkoutSession session) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'workout_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var i = 0; i < session.exercises.length; i++) {
        final ex = session.exercises[i];
        await txn.insert(
          'session_exercises',
          ex.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final s in ex.sets) {
          await txn.insert(
            'session_sets',
            s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}
