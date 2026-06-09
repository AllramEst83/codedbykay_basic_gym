import 'package:sqflite/sqflite.dart';

import '../repositories/settings_repository.dart';

class SqfliteSettingsRepository extends SettingsRepository {
  SqfliteSettingsRepository(this._db);

  final Database _db;

  @override
  Future<String?> get(String key) async {
    final rows = await _db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> set(String key, String value) async {
    await _db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
