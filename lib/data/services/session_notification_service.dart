import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../models/workout.dart';

// SharedPreferences keys used to pass session state to the background isolate.
const String _kStartedAtKey = 'session_started_at_ms';
const String _kPausedDurationKey = 'session_paused_duration_ms';
const String _kIsPausedKey = 'session_is_paused';
const String _kPausedAtKey = 'session_paused_at_ms';
const String _kTitleKey = 'session_title';

/// Entry point for the background isolate that drives the foreground service.
///
/// Must be a top-level function annotated with @pragma so the AOT compiler
/// preserves it.
@pragma('vm:entry-point')
void _sessionTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_SessionTaskHandler());
}

/// Manages the Android foreground service that keeps workout sessions alive
/// when the phone screen is locked.
///
/// Call [start] when a session begins, [setPaused] on pause/resume, and [stop]
/// when the session ends. The notification shows the session title and a
/// live elapsed-time counter; tapping it returns the user to the app.
class SessionNotificationService {
  SessionNotificationService._();

  static final SessionNotificationService instance =
      SessionNotificationService._();

  bool _running = false;
  DateTime? _startedAt;
  int _pausedDurationMs = 0;
  DateTime? _pausedAt;

  /// Whether the foreground service is currently active.
  bool get isRunning => _running;

  static const String _kChannelId = 'flexflow_active_session';

  /// Starts the foreground service for the given workout session.
  ///
  /// Set [includesLocation] to `true` for running sessions so the foreground
  /// service declares the `location` type, allowing geolocator to continue
  /// streaming GPS fixes without needing its own separate service.
  Future<void> start({
    required String routineName,
    required WorkoutCategory category,
    required DateTime startedAt,
    bool includesLocation = false,
  }) async {
    // Tear down any stale service before starting fresh.
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    _startedAt = startedAt;
    _pausedDurationMs = 0;
    _pausedAt = null;
    _running = true;

    final title = '${category.label} · $routineName';

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _kChannelId,
        channelName: 'Active Session',
        channelDescription:
            'Keeps your workout session running while the screen is off.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowAutoRestart: false,
        stopWithTask: true,
      ),
    );

    // Persist state readable by the background isolate via SharedPreferences.
    await Future.wait([
      FlutterForegroundTask.saveData(
        key: _kStartedAtKey,
        value: startedAt.millisecondsSinceEpoch,
      ),
      FlutterForegroundTask.saveData(
        key: _kPausedDurationKey,
        value: 0,
      ),
      FlutterForegroundTask.saveData(
        key: _kIsPausedKey,
        value: false,
      ),
      FlutterForegroundTask.saveData(
        key: _kPausedAtKey,
        value: -1,
      ),
      FlutterForegroundTask.saveData(
        key: _kTitleKey,
        value: title,
      ),
    ]);

    final serviceTypes = includesLocation
        ? [ForegroundServiceTypes.health, ForegroundServiceTypes.location]
        : [ForegroundServiceTypes.health];

    await FlutterForegroundTask.startService(
      serviceTypes: serviceTypes,
      notificationTitle: title,
      notificationText: '00:00:00',
      callback: _sessionTaskEntryPoint,
    );
  }

  /// Notifies the background task of a pause or resume event.
  Future<void> setPaused(bool paused) async {
    if (!_running || _startedAt == null) return;

    final now = DateTime.now();
    if (paused && _pausedAt == null) {
      _pausedAt = now;
    } else if (!paused && _pausedAt != null) {
      _pausedDurationMs += now.difference(_pausedAt!).inMilliseconds;
      _pausedAt = null;
    }

    // Update SharedPreferences for persistence across process restarts.
    await Future.wait([
      FlutterForegroundTask.saveData(
        key: _kPausedDurationKey,
        value: _pausedDurationMs,
      ),
      FlutterForegroundTask.saveData(
        key: _kIsPausedKey,
        value: paused,
      ),
      FlutterForegroundTask.saveData(
        key: _kPausedAtKey,
        value: _pausedAt?.millisecondsSinceEpoch ?? -1,
      ),
    ]);

    // Send live update to the background isolate for immediate notification
    // text change without waiting for SharedPreferences round-trip.
    FlutterForegroundTask.sendDataToTask(<String, dynamic>{
      'paused': paused,
      'pausedDurationMs': _pausedDurationMs,
      'pausedAtMs': _pausedAt?.millisecondsSinceEpoch ?? -1,
    });
  }

  /// Stops the foreground service and clears persisted session state.
  /// Call when the session finishes or the user navigates away.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _startedAt = null;
    _pausedDurationMs = 0;
    _pausedAt = null;

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await FlutterForegroundTask.clearAllData();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background task handler — runs in a separate isolate
// ─────────────────────────────────────────────────────────────────────────────

class _SessionTaskHandler extends TaskHandler {
  int _startedAtMs = 0;
  int _pausedDurationMs = 0;
  int _pausedAtMs = -1; // -1 = not currently paused
  bool _paused = false;
  String _title = 'Workout';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startedAtMs =
        await FlutterForegroundTask.getData<int>(key: _kStartedAtKey) ??
            timestamp.millisecondsSinceEpoch;
    _pausedDurationMs =
        await FlutterForegroundTask.getData<int>(key: _kPausedDurationKey) ?? 0;
    _paused =
        await FlutterForegroundTask.getData<bool>(key: _kIsPausedKey) ?? false;
    _pausedAtMs =
        await FlutterForegroundTask.getData<int>(key: _kPausedAtKey) ?? -1;
    _title =
        await FlutterForegroundTask.getData<String>(key: _kTitleKey) ??
            'Workout';
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final nowMs = timestamp.millisecondsSinceEpoch;

    // Add any currently active pause window to the accumulated total.
    final effectivePausedMs = (_paused && _pausedAtMs != -1)
        ? _pausedDurationMs + (nowMs - _pausedAtMs)
        : _pausedDurationMs;

    final elapsedMs =
        (nowMs - _startedAtMs - effectivePausedMs).clamp(0, 99 * 3600 * 1000);

    FlutterForegroundTask.updateService(
      notificationTitle: _title,
      notificationText:
          _paused ? 'Paused · ${_formatMs(elapsedMs)}' : _formatMs(elapsedMs),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      _paused = (data['paused'] as bool?) ?? _paused;
      _pausedDurationMs =
          (data['pausedDurationMs'] as int?) ?? _pausedDurationMs;
      _pausedAtMs = (data['pausedAtMs'] as int?) ?? _pausedAtMs;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}'
        ':${two(d.inSeconds.remainder(60))}';
  }
}
