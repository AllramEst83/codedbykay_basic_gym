import 'package:flutter/foundation.dart';

import '../../models/workout.dart';
import '../repositories/in_progress_session_repository.dart';

/// In-memory cache for [InProgressSession]s, backed by
/// [InProgressSessionRepository].
///
/// Screens listen to this [ChangeNotifier] to surface a "Resume session" CTA
/// when one or more workouts were started but not finished. The cache is kept
/// in sync by the [ActiveSessionScreen] via [refresh].
class InProgressSessionStore extends ChangeNotifier {
  InProgressSessionStore._();

  static final InProgressSessionStore instance = InProgressSessionStore._();

  late InProgressSessionRepository _repo;
  final List<InProgressSession> _sessions = [];

  /// All in-progress sessions, most recently updated first.
  List<InProgressSession> get sessions => List.unmodifiable(_sessions);

  /// True when at least one in-progress session exists.
  bool get hasAny => _sessions.isNotEmpty;

  /// Loads sessions from the repository into the in-memory cache.
  /// Call once in [main] after the database is open.
  Future<void> hydrate(InProgressSessionRepository repo) async {
    _repo = repo;
    await refresh();
  }

  /// Re-reads the persisted list from disk. Cheap to call repeatedly; the
  /// active-session screen invokes it on save / close / discard so other
  /// screens get the latest state without sharing a listener stream.
  Future<void> refresh() async {
    final loaded = await _repo.getAll();
    _sessions
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }
}
