import 'package:sqflite/sqflite.dart';

import '../../models/workout.dart';
import '../repositories/in_progress_session_repository.dart';

class SqfliteInProgressSessionRepository
    implements InProgressSessionRepository {
  const SqfliteInProgressSessionRepository(this._db);

  final Database _db;

  @override
  Future<InProgressSession?> getByRoutineId(String routineId) async {
    final rows = await _db.query(
      'in_progress_sessions',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return InProgressSession.fromMap(rows.first);
  }

  @override
  Future<void> save(InProgressSession session) async {
    await _db.insert(
      'in_progress_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String routineId) async {
    await _db.delete(
      'in_progress_sessions',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  @override
  Future<List<InProgressSession>> getAll() async {
    final rows = await _db.query(
      'in_progress_sessions',
      orderBy: 'updated_at DESC',
    );

    return rows.map((row) => InProgressSession.fromMap(row)).toList();
  }
}
