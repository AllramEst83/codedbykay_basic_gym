import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import 'repositories/session_repository.dart';

/// In-memory cache for completed [WorkoutSession]s, backed by
/// [SessionRepository].
///
/// Screens listen to this [ChangeNotifier] and rebuild when history changes.
class SessionStore extends ChangeNotifier {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  late SessionRepository _repo;
  final List<WorkoutSession> _sessions = [];

  /// All sessions, newest first.
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  /// Loads sessions from the repository into the in-memory cache.
  /// Call once in [main] after the database is open.
  Future<void> hydrate(SessionRepository repo) async {
    _repo = repo;
    final loaded = await repo.getAll();
    _sessions
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  /// Persists [session] and prepends it to the cache (newest first).
  Future<void> save(WorkoutSession session) async {
    await _repo.save(session);
    _sessions.insert(0, session);
    notifyListeners();
  }
}
