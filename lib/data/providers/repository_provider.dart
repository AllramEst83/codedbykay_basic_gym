import '../repositories/in_progress_session_repository.dart';
import '../repositories/routine_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../sqflite/app_database.dart';
import '../sqflite/sqflite_in_progress_session_repository.dart';
import '../sqflite/sqflite_routine_repository.dart';
import '../sqflite/sqflite_schedule_repository.dart';
import '../sqflite/sqflite_session_repository.dart';
import '../sqflite/sqflite_settings_repository.dart';

/// Holds the concrete repository instances built from the open [AppDatabase].
///
/// Constructed once in [main] and passed into each store's [hydrate] call.
/// Keeps the database layer out of all store/screen code — stores only depend
/// on the abstract interfaces.
class RepositoryProvider {
  RepositoryProvider._({
    required this.routines,
    required this.schedule,
    required this.sessions,
    required this.settings,
    required this.inProgressSessions,
  });

  static RepositoryProvider? _instance;

  /// Global accessor for repositories. Must be initialized in main.
  static RepositoryProvider get instance {
    if (_instance == null) {
      throw StateError('RepositoryProvider not initialized');
    }
    return _instance!;
  }

  factory RepositoryProvider.fromDatabase(AppDatabase db) {
    _instance = RepositoryProvider._(
      routines: SqfliteRoutineRepository(db.db),
      schedule: SqfliteScheduleRepository(db.db),
      sessions: SqfliteSessionRepository(db.db),
      settings: SqfliteSettingsRepository(db.db),
      inProgressSessions: SqfliteInProgressSessionRepository(db.db),
    );
    return _instance!;
  }

  final RoutineRepository routines;
  final ScheduleRepository schedule;
  final SessionRepository sessions;
  final SettingsRepository settings;
  final InProgressSessionRepository inProgressSessions;
}
