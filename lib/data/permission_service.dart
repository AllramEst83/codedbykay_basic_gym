import 'package:permission_handler/permission_handler.dart';

/// Requests all permissions the app needs on first launch (or when they have
/// not yet been granted). Call once after the first frame is rendered so the
/// OS dialogs appear with a fully drawn UI behind them.
///
/// Permissions requested:
/// - Location — required by [RunningSessionScreen] for GPS distance tracking.
/// - Audio/Storage — required for kilometre audio cues during a run.
class PermissionService {
  const PermissionService._();

  /// Requests any permissions that are not yet granted.
  /// Permanently-denied permissions are silently skipped here; the user can
  /// grant them later via the Settings screen.
  static Future<void> requestAll() async {
    final statuses = await [
      Permission.location,
      Permission.audio,
    ].request();

    // If audio was denied, fall back to requesting storage (Android < 13).
    if (statuses[Permission.audio] != PermissionStatus.granted) {
      await Permission.storage.request();
    }
  }
}
