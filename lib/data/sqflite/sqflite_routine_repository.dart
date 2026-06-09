import 'package:sqflite/sqflite.dart';

import '../../models/workout.dart';
import '../repositories/routine_repository.dart';

class SqfliteRoutineRepository implements RoutineRepository {
  const SqfliteRoutineRepository(this._db);

  final Database _db;

  @override
  Future<List<Routine>> getAll() async {
    final rows = await _db.query(
      'routines',
      orderBy: 'updated_at DESC',
    );

    final routines = <Routine>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final templateRows = await _db.query(
        'exercise_templates',
        where: 'routine_id = ?',
        whereArgs: [id],
        orderBy: 'order_index ASC',
      );
      final templates =
          templateRows.map(ExerciseTemplate.fromMap).toList();
      routines.add(Routine.fromMap(row, templates));
    }
    return routines;
  }

  @override
  Future<void> upsert(Routine routine) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'routines',
        routine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace exercise templates: delete existing then re-insert in order.
      await txn.delete(
        'exercise_templates',
        where: 'routine_id = ?',
        whereArgs: [routine.id],
      );

      for (var i = 0; i < routine.exercises.length; i++) {
        await txn.insert(
          'exercise_templates',
          routine.exercises[i].toMap(routineId: routine.id, orderIndex: i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }
}
