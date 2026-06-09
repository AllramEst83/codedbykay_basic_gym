import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/session_store.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/squish.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Haversine helpers (no external geo package)
// ─────────────────────────────────────────────────────────────────────────────

double _toRad(double deg) => deg * math.pi / 180.0;

/// Returns the great-circle distance in kilometres between two GPS coordinates
/// using the Haversine formula.
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371.0;
  final double dLat = _toRad(lat2 - lat1);
  final double dLon = _toRad(lon2 - lon1);
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

/// Formats a pace value as "mm:ss /km". Returns "--:-- /km" when pace is
/// unknown (zero or near-zero).
String _formatPace(double paceKmh) {
  if (paceKmh < 0.1) return '--:-- /km';
  final minPerKm = 60.0 / paceKmh;
  final min = minPerKm.floor();
  final sec = ((minPerKm - min) * 60).round().clamp(0, 59);
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')} /km';
}

// ─────────────────────────────────────────────────────────────────────────────
// Kalman filter for GPS position smoothing
// ─────────────────────────────────────────────────────────────────────────────

/// 1-D Kalman filter on GPS position uncertainty.
///
/// Treats the device as a moving point whose uncertainty grows between fixes
/// and folds each new position in weighted by its reported accuracy.
///
/// [_qMps] (process noise, m/s) is set to 3.0 — covers the fastest realistic
/// recreational runner with headroom.  Degrees are fed in directly; only the
/// Q and R covariances need to be in metres².
class _GpsKalman {
  static const double _qMps = 3.0;

  double? _lat;
  double? _lng;
  double _pVar = 0; // state covariance in metres²
  int? _tsMs;

  void process(double lat, double lng, double accuracyMetres, int tsMs) {
    if (_lat == null) {
      _lat = lat;
      _lng = lng;
      _pVar = accuracyMetres * accuracyMetres;
      _tsMs = tsMs;
      return;
    }
    final dtSec = (tsMs - _tsMs!) / 1000.0;
    if (dtSec > 0) _pVar += dtSec * _qMps * _qMps; // Q matrix

    final r = accuracyMetres * accuracyMetres; // R matrix
    final k = _pVar / (_pVar + r); // Kalman gain
    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _pVar = (1 - k) * _pVar;
    _tsMs = tsMs;
  }

  /// Smoothed (lat, lng), or null before the first accepted fix.
  (double, double)? get position =>
      _lat == null ? null : (_lat!, _lng!);
}

// ─────────────────────────────────────────────────────────────────────────────
// Location service
// ─────────────────────────────────────────────────────────────────────────────

/// Tracks GPS position and accumulates distance using the Haversine formula.
///
/// Per-fix pipeline:
///   1. Spike filter (accuracy, implied speed, time-delta)
///   2. EMA pace update from [Position.speed]
///   3. Kalman smoother
///   4. 5 m minimum-displacement filter → Haversine accumulation
///
/// Falls back to simulated movement (+0.05 km every 3 s) when real GPS is
/// unavailable (emulator, disabled service, or permission denied).
class _LocationService {
  _LocationService({
    required this.onDistanceUpdated,
    this.onPaceUpdated,
    this.onError,
  });

  final void Function(double totalKm) onDistanceUpdated;
  final void Function(double paceKmh)? onPaceUpdated;

  /// Called with a human-readable message when the stream falls back to
  /// simulation due to a typed location exception.
  final void Function(String message)? onError;

  // ── Thresholds ─────────────────────────────────────────────────────────────
  static const double _minDisplacementKm = 0.005; // 5 m
  static const double _simStepKm = 0.05;
  static const double _maxAccuracyM = 25.0;
  static const double _maxSpeedMps = 8.0; // ≈ 28.8 km/h
  static const double _minDtSec = 1.0;
  static const double _emaAlpha = 0.3;

  // ── State ──────────────────────────────────────────────────────────────────
  StreamSubscription<Position>? _positionSub;
  Timer? _simTimer;

  Position? _lastAcceptedPosition; // last raw pos that passed spike filter
  DateTime? _lastAcceptedTimestamp;

  final _GpsKalman _kalman = _GpsKalman();
  (double, double)? _lastSummedKalman; // last Kalman pos used in accumulation

  double? _emaPaceKmh;

  double _totalKm = 0;
  bool _useSimulation = false;
  bool _stopped = false;
  bool _paused = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    _stopped = false;
    _paused = false;
    _useSimulation = false;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useSimulation = true;
      } else {
        _startGpsStream(LocationAccuracy.best);
      }
    } catch (_) {
      _useSimulation = true;
    }

    if (_useSimulation) _startSimulation();
  }

  /// Pauses tracking. Switches to [LocationAccuracy.low] to keep a warm GPS
  /// fix while reducing battery drain. Distance is not accumulated while
  /// paused. Spike-filter and Kalman displacement anchors are reset so the
  /// first fix after resume doesn't cause a false spike or distance jump.
  void pause() {
    _paused = true;
    _simTimer?.cancel();
    _simTimer = null;
    if (!_useSimulation) {
      _startGpsStream(LocationAccuracy.low);
    }
    _lastAcceptedPosition = null;
    _lastAcceptedTimestamp = null;
    _lastSummedKalman = null;
  }

  /// Resumes tracking at [LocationAccuracy.best].
  void resume() {
    if (_stopped) return;
    _paused = false;
    if (_useSimulation) {
      _startSimulation();
    } else {
      _startGpsStream(LocationAccuracy.best);
    }
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    _positionSub?.cancel();
    _simTimer?.cancel();
    _positionSub = null;
    _simTimer = null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  LocationSettings _buildLocationSettings(LocationAccuracy accuracy) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Run in progress',
          notificationTitle: 'FlexFlow',
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    }
    return LocationSettings(accuracy: accuracy, distanceFilter: 0);
  }

  void _startGpsStream(LocationAccuracy accuracy) {
    _positionSub?.cancel();
    _positionSub = null;
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(accuracy),
      ).listen(
        _handlePosition,
        onError: _handleStreamError,
        cancelOnError: false,
      );
    } catch (_) {
      _useSimulation = true;
      if (!_stopped && !_paused) _startSimulation();
    }
  }

  void _handleStreamError(Object error) {
    _positionSub?.cancel();
    _positionSub = null;
    String? message;
    if (error is PermissionDeniedException) {
      message =
          'Location permission denied — distance tracking will be simulated.';
    } else if (error is LocationServiceDisabledException) {
      message =
          'Location service disabled — distance tracking will be simulated.';
    }
    if (message != null) onError?.call(message);
    _useSimulation = true;
    if (!_stopped && !_paused) _startSimulation();
  }

  void _handlePosition(Position pos) {
    if (_stopped || _paused) return;

    // ── 1. Spike filter ──────────────────────────────────────────────────────
    if (pos.accuracy > _maxAccuracyM) return;

    final now = pos.timestamp;
    if (_lastAcceptedTimestamp != null) {
      final dt =
          now.difference(_lastAcceptedTimestamp!).inMilliseconds / 1000.0;
      if (dt < _minDtSec) return;
      if (_lastAcceptedPosition != null) {
        final distM = _haversineKm(
              _lastAcceptedPosition!.latitude,
              _lastAcceptedPosition!.longitude,
              pos.latitude,
              pos.longitude,
            ) *
            1000;
        final speedMps = dt > 0 ? distM / dt : double.infinity;
        if (speedMps > _maxSpeedMps) return;
      }
    }
    _lastAcceptedPosition = pos;
    _lastAcceptedTimestamp = now;

    // ── 2. EMA pace (device-reported speed, before Kalman smoothing) ─────────
    if (pos.speed >= 0) {
      final speedKmh = pos.speed * 3.6;
      final prevPace = _emaPaceKmh;
      _emaPaceKmh = prevPace == null
          ? speedKmh
          : _emaAlpha * speedKmh + (1 - _emaAlpha) * prevPace;
      onPaceUpdated?.call(_emaPaceKmh!);
    }

    // ── 3. Kalman smoothing ──────────────────────────────────────────────────
    _kalman.process(
      pos.latitude,
      pos.longitude,
      pos.accuracy,
      now.millisecondsSinceEpoch,
    );
    final smoothed = _kalman.position;
    if (smoothed == null) return;

    // ── 4. Minimum-displacement filter & Haversine accumulation ─────────────
    final lastKalman = _lastSummedKalman;
    if (lastKalman == null) {
      _lastSummedKalman = smoothed;
      return;
    }
    final distKm =
        _haversineKm(lastKalman.$1, lastKalman.$2, smoothed.$1, smoothed.$2);
    if (distKm > _minDisplacementKm) {
      _totalKm += distKm;
      _lastSummedKalman = smoothed;
      onDistanceUpdated(_totalKm);
    }
  }

  void _startSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_stopped || _paused) return;
      _totalKm += _simStepKm;
      onDistanceUpdated(_totalKm);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Session screen for running and cardio workouts.
///
/// Displays an HH:MM:SS timer, GPS-based distance progress bar, current pace,
/// and an audio cue toggle. Strength workouts use [ActiveSessionScreen] instead.
class RunningSessionScreen extends StatefulWidget {
  const RunningSessionScreen({
    super.key,
    required this.routine,
    this.targetKm = 5.0,
  });

  final Routine routine;

  /// Target distance in kilometres. Defaults to 5.0.
  final double targetKm;

  @override
  State<RunningSessionScreen> createState() => _RunningSessionScreenState();
}

class _RunningSessionScreenState extends State<RunningSessionScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _started = false;
  bool _paused = false;
  late final DateTime _startedAt;

  double _distanceKm = 0;
  double _currentPaceKmh = 0;
  int _lastCuedKm = 0;
  bool _audioCuesEnabled = true;

  late final _LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _locationService = _LocationService(
      onDistanceUpdated: _onDistanceUpdated,
      onPaceUpdated: _onPaceUpdated,
      onError: _onLocationError,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _locationService.stop();
    super.dispose();
  }

  void _onDistanceUpdated(double km) {
    if (!mounted) return;
    final curr = km.floor();
    if (_audioCuesEnabled && curr > _lastCuedKm && curr > 0) {
      _lastCuedKm = curr;
      _playKmCue();
    }
    setState(() => _distanceKm = km);
  }

  void _onPaceUpdated(double paceKmh) {
    if (!mounted) return;
    setState(() => _currentPaceKmh = paceKmh);
  }

  void _onLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Stub: wire to an audio player when assets/audio/km_cue.mp3 is ready.
  void _playKmCue() {
    debugPrint('[RunningSession] Audio cue: $_lastCuedKm km reached');
  }

  Future<void> _onStart() async {
    final locationStatus = await Permission.location.request();

    if (!mounted) return;
    if (!locationStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission denied — distance tracking will be simulated.',
          ),
        ),
      );
    }

    final audioStatus = await Permission.audio.request();
    if (!mounted) return;

    if (!audioStatus.isGranted) {
      final storageStatus = await Permission.storage.request();
      if (!mounted) return;
      if (!storageStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission denied — kilometre audio cues may not play.',
            ),
          ),
        );
      }
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_paused) setState(() => _elapsed += const Duration(seconds: 1));
      // Safety cutoff: auto-stop after 4 h of active time with < 100 m moved.
      if (_elapsed.inHours >= 4 && _distanceKm < 0.1) _autoStop();
    });

    await _locationService.start();

    if (!mounted) return;
    setState(() {
      _started = true;
      _paused = false;
    });
  }

  /// Automatically stops the session when the safety cutoff triggers.
  void _autoStop() {
    _ticker?.cancel();
    _ticker = null;
    _locationService.stop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session auto-stopped after 4 hours of inactivity.'),
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _onPauseResume() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _locationService.pause();
    } else {
      _locationService.resume();
    }
  }

  Future<void> _onStop() async {
    _ticker?.cancel();
    _ticker = null;
    _locationService.stop();

    final completedAt = DateTime.now();
    final sessionId = 'run_${completedAt.millisecondsSinceEpoch}';
    final session = WorkoutSession(
      id: sessionId,
      routineId: widget.routine.id,
      title: widget.routine.name,
      category: widget.routine.category,
      durationSeconds: _elapsed.inSeconds,
      distanceKm: _distanceKm,
      targetKm: widget.targetKm,
      startedAt: _startedAt,
      completedAt: completedAt,
      exercises: const [],
    );

    await SessionStore.instance.save(session);

    if (mounted) Navigator.of(context).maybePop();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}'
        ':${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(widget.routine.name, style: AppTextStyles.headlineMd),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.lg,
            AppSpacing.containerMargin,
            AppSpacing.lg,
          ),
          children: [
            _TimerDisplay(
              elapsed: _formatDuration(_elapsed),
              paused: _paused,
              started: _started,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ControlButtons(
              started: _started,
              paused: _paused,
              onStart: _onStart,
              onPauseResume: _onPauseResume,
              onStop: _onStop,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DistanceSection(
              currentKm: _distanceKm,
              targetKm: widget.targetKm,
              paceKmh: _currentPaceKmh,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AudioCueToggle(
              enabled: _audioCuesEnabled,
              onToggle: (v) => setState(() => _audioCuesEnabled = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer display
// ─────────────────────────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({
    required this.elapsed,
    required this.paused,
    required this.started,
  });

  final String elapsed;
  final bool paused;
  final bool started;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            elapsed,
            style: AppTextStyles.statNumber.copyWith(
              fontSize: 52,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          if (started) ...[
            const SizedBox(height: AppSpacing.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  paused
                      ? Icons.pause_circle_outline_rounded
                      : Icons.radio_button_checked_rounded,
                  size: 14,
                  color: paused
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  paused ? 'Paused' : 'Running',
                  style: AppTextStyles.labelBold.copyWith(
                    fontSize: 12,
                    color: paused
                        ? AppColors.onSurfaceVariant
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ControlButtons extends StatelessWidget {
  const _ControlButtons({
    required this.started,
    required this.paused,
    required this.onStart,
    required this.onPauseResume,
    required this.onStop,
  });

  final bool started;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return PrimaryPillButton(
        label: 'Start',
        icon: Icons.play_arrow_rounded,
        elevated: true,
        onPressed: onStart,
      );
    }

    return Row(
      children: [
        Expanded(
          child: PrimaryPillButton(
            label: paused ? 'Resume' : 'Pause',
            icon: paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            background: AppColors.surfaceContainerHighest,
            foreground: AppColors.onSurface,
            onPressed: onPauseResume,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PrimaryPillButton(
            label: 'Stop',
            icon: Icons.stop_rounded,
            background: AppColors.errorContainer,
            foreground: AppColors.onErrorContainer,
            onPressed: onStop,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Distance section
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceSection extends StatelessWidget {
  const _DistanceSection({
    required this.currentKm,
    required this.targetKm,
    required this.paceKmh,
  });

  final double currentKm;
  final double targetKm;
  final double paceKmh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Distance', style: AppTextStyles.labelBold),
              Text(
                '${currentKm.toStringAsFixed(2)} / '
                '${targetKm.toStringAsFixed(1)} km',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _DistanceBar(currentKm: currentKm, targetKm: targetKm),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pace', style: AppTextStyles.labelBold),
              Text(
                _formatPace(paceKmh),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Distance bar with km tick marks
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceBar extends StatelessWidget {
  const _DistanceBar({required this.currentKm, required this.targetKm});

  final double currentKm;
  final double targetKm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, 44),
        painter: _DistanceBarPainter(
          currentKm: currentKm,
          targetKm: targetKm,
          fillColor: AppColors.primary,
          trackColor: AppColors.surfaceContainerHighest,
          tickColor: AppColors.surface,
          labelStyle: AppTextStyles.labelBold.copyWith(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DistanceBarPainter extends CustomPainter {
  _DistanceBarPainter({
    required this.currentKm,
    required this.targetKm,
    required this.fillColor,
    required this.trackColor,
    required this.tickColor,
    required this.labelStyle,
  });

  final double currentKm;
  final double targetKm;
  final Color fillColor;
  final Color trackColor;
  final Color tickColor;
  final TextStyle labelStyle;

  static const double _barHeight = 16.0;
  static const double _barRadius = 8.0;
  static const double _labelTopOffset = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = Rect.fromLTWH(0, 0, size.width, _barHeight);
    final rrect = RRect.fromRectAndRadius(
      barRect,
      const Radius.circular(_barRadius),
    );

    // Track background
    canvas.drawRRect(rrect, Paint()..color = trackColor);

    // Progress fill
    if (targetKm > 0 && currentKm > 0) {
      final progress = (currentKm / targetKm).clamp(0.0, 1.0);
      final fillRect = Rect.fromLTWH(0, 0, size.width * progress, _barHeight);
      final fillRRect = RRect.fromRectAndRadius(
        fillRect,
        const Radius.circular(_barRadius),
      );
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRRect(fillRRect, Paint()..color = fillColor);
      canvas.restore();
    }

    // Tick marks at each integer km (not at 0 or targetKm)
    if (targetKm > 0) {
      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = 1.5;
      final int ticks = targetKm.ceil();
      for (int i = 1; i < ticks; i++) {
        if (i >= targetKm) break;
        final x = (i / targetKm) * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, _barHeight), tickPaint);
      }
    }

    // Labels: 0, 1, 2, … targetKm.ceil()
    if (targetKm > 0) {
      final int labelCount = targetKm.ceil();
      for (int i = 0; i <= labelCount; i++) {
        final double normX = i / targetKm;
        if (normX > 1.0) break;
        final double x = normX * size.width;
        final tp = TextPainter(
          text: TextSpan(text: '$i', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(labelX, _labelTopOffset));
      }
    }
  }

  @override
  bool shouldRepaint(_DistanceBarPainter old) =>
      old.currentKm != currentKm ||
      old.targetKm != targetKm ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio cue toggle
// ─────────────────────────────────────────────────────────────────────────────

class _AudioCueToggle extends StatelessWidget {
  const _AudioCueToggle({required this.enabled, required this.onToggle});

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: () => onToggle(!enabled),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: enabled ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audio Cues', style: AppTextStyles.labelBold),
                  Text(
                    'Plays a sound at each completed kilometre',
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
