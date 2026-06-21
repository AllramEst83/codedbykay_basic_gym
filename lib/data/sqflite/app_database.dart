import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton that owns the single [Database] connection for the app.
///
/// Call [AppDatabase.open] once in [main] before [runApp].
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  /// The underlying sqflite [Database]. Prefer using repository classes
  /// instead of accessing this directly.
  Database get db => _db;

  static const int _version = 4;

  /// Opens (and if necessary creates) the SQLite database file in the app's
  /// documents directory, which survives app updates.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'flexflow.db');

    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return AppDatabase._(db);
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key         TEXT PRIMARY KEY,
        value       TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routines (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        category    TEXT NOT NULL,
        target_km   REAL,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        deleted_at  INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_templates (
        id           TEXT PRIMARY KEY,
        routine_id   TEXT NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
        name         TEXT NOT NULL,
        sets         INTEGER NOT NULL,
        reps_label   TEXT NOT NULL,
        note         TEXT,
        order_index  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_exercise_templates_routine
        ON exercise_templates(routine_id)
    ''');

    await db.execute('''
      CREATE TABLE scheduled_workouts (
        id                TEXT PRIMARY KEY,
        routine_id        TEXT REFERENCES routines(id) ON DELETE SET NULL,
        title             TEXT NOT NULL,
        category          TEXT NOT NULL,
        duration_minutes  INTEGER NOT NULL,
        scheduled_date    INTEGER NOT NULL,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL,
        deleted_at        INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_scheduled_workouts_date
        ON scheduled_workouts(scheduled_date)
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id                TEXT PRIMARY KEY,
        routine_id        TEXT REFERENCES routines(id) ON DELETE SET NULL,
        title             TEXT NOT NULL,
        category          TEXT NOT NULL,
        duration_seconds  INTEGER NOT NULL,
        distance_km       REAL,
        target_km         REAL,
        started_at        INTEGER NOT NULL,
        completed_at      INTEGER NOT NULL,
        notes             TEXT,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL,
        deleted_at        INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_sessions_completed
        ON workout_sessions(completed_at)
    ''');

    await db.execute('''
      CREATE TABLE session_exercises (
        id            TEXT PRIMARY KEY,
        session_id    TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
        name          TEXT NOT NULL,
        muscle_group  TEXT,
        note          TEXT,
        order_index   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_session_exercises_session
        ON session_exercises(session_id)
    ''');

    await db.execute('''
      CREATE TABLE session_sets (
        id           TEXT PRIMARY KEY,
        exercise_id  TEXT NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
        weight_kg    REAL,
        reps         INTEGER,
        completed    INTEGER NOT NULL DEFAULT 0,
        order_index  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_session_sets_exercise
        ON session_sets(exercise_id)
    ''');

    await db.execute('''
      CREATE TABLE in_progress_sessions (
        id                TEXT PRIMARY KEY,
        routine_id        TEXT NOT NULL,
        routine_name      TEXT NOT NULL,
        routine_category  TEXT NOT NULL,
        started_at        INTEGER NOT NULL,
        elapsed_seconds   INTEGER NOT NULL DEFAULT 0,
        current_exercise  INTEGER NOT NULL DEFAULT 0,
        selected_set      INTEGER NOT NULL DEFAULT 0,
        paused            INTEGER NOT NULL DEFAULT 0,
        exercises_json    TEXT NOT NULL,
        updated_at        INTEGER NOT NULL
      )
    ''');
  }

  /// Versioned migrations.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE routines ADD COLUMN target_km REAL',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE exercise_templates ADD COLUMN note TEXT',
      );
      await db.execute(
        'ALTER TABLE session_exercises ADD COLUMN note TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE in_progress_sessions (
          id                TEXT PRIMARY KEY,
          routine_id        TEXT NOT NULL,
          routine_name      TEXT NOT NULL,
          routine_category  TEXT NOT NULL,
          started_at        INTEGER NOT NULL,
          elapsed_seconds   INTEGER NOT NULL DEFAULT 0,
          current_exercise  INTEGER NOT NULL DEFAULT 0,
          selected_set      INTEGER NOT NULL DEFAULT 0,
          paused            INTEGER NOT NULL DEFAULT 0,
          exercises_json    TEXT NOT NULL,
          updated_at        INTEGER NOT NULL
        )
      ''');
    }
  }
}
