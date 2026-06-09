# GPS Noise Handling — Research for the Running Session Screen

Scope: consumer mobile running app, real-time distance during a session, walking/running pace (3–20 km/h), no road snapping, local-only data, solo/small team.

## 1. Recommended algorithm pipeline (ranked)

For a running tracker we don't need road snapping — we just need cumulative distance that doesn't inflate while standing at a traffic light. Ranked by value-per-effort:

1. **Threshold / spike filter** (must-have, ~1 day). Reject any incoming `Position` whose `accuracy > 20–25 m`, whose implied speed vs. the previous accepted point is > 8 m/s (≈ 28.8 km/h, well above any recreational runner), or whose timestamp delta is < ~1 s. Cheap, drops the worst outliers.
2. **Minimum-displacement filter** (must-have, already planned). Don't accumulate distance for steps < ~5 m. This alone removes the bulk of "stationary drift" inflation.
3. **1D Kalman filter on accuracy-weighted position** (high value, ~1–2 days). Smooths the remaining wander without adding lag noticeable at running pace. *Implement first after the MVP.*
4. **Velocity smoothing** (nice-to-have). Exponential moving average over `Position.speed` for the pace display; keeps the on-screen pace from flickering.
5. **Smoothing splines / Douglas-Peucker simplification** (post-session only). Use *after* the run ends, to draw a clean route polyline and shrink the stored point count. Don't use the smoothed track to recompute distance — that biases low.
6. **HMM / Viterbi map matching** (skip). Requires a road graph (OSM tile + routing) and only helps for *driving* or strict on-road cycling. A trail run through a park is exactly where map matching hurts.

## 2. Kalman filter for Dart/Flutter

For a running app, a **1D Kalman on position uncertainty** (per the approach popularised by Stochastically/Android's `LocationKalmanFilter` gist) is plenty. It treats the device as a point with growing uncertainty over time, and folds in each new `Position` weighted by its reported `accuracy`.

State: `lat`, `lng`, variance `pVar` (metres²). Tunable: `qMetresPerSecond` ≈ 3.0 for running (process noise — how fast we believe the runner can move/turn).

```dart
class GpsKalman {
  static const double _qMps = 3.0;
  double? _lat, _lng;
  double _pVar = 0; // metres^2
  int? _tsMs;

  void process(double lat, double lng, double accuracyMetres, int tsMs) {
    if (_lat == null) {
      _lat = lat; _lng = lng;
      _pVar = accuracyMetres * accuracyMetres;
      _tsMs = tsMs;
      return;
    }
    final dtSec = (tsMs - _tsMs!) / 1000.0;
    if (dtSec > 0) _pVar += dtSec * _qMps * _qMps; // Q

    final r = accuracyMetres * accuracyMetres;     // R
    final k = _pVar / (_pVar + r);                 // gain
    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _pVar = (1 - k) * _pVar;
    _tsMs = tsMs;
  }

  (double, double)? get position => _lat == null ? null : (_lat!, _lng!);
}
```

Notes: degrees are fed in directly because `k` is dimensionless and the correction is tiny per step; only `Q` and `R` need to be in metres². For a 2D constant-velocity model (separate state for velocity, 4×4 matrices) reach for the `kalman_filter` pub package — overkill for v2.

## 3. Flutter/Dart package landscape

| Package | Use it for | Notes |
| --- | --- | --- |
| [`geolocator`](https://pub.dev/packages/geolocator) | `getPositionStream`, permission flow, `Position.accuracy/speed/heading`, distance helper | The default choice. Use `LocationSettings(accuracy: best, distanceFilter: 0)` and filter in-app — its built-in `distanceFilter` is a hard cutoff with no spike rejection. |
| [`latlong2`](https://pub.dev/packages/latlong2) | `Distance().as(LengthUnit.Meter, a, b)` (Haversine) and `Distance.vincenty` | Drop-in if you'd rather not hand-roll Haversine. Vincenty is more accurate but slower; Haversine is fine at running distances (<1 cm error per 100 m). |
| [`sensors_plus`](https://pub.dev/packages/sensors_plus) | Accelerometer / step detection for dead-reckoning when GPS drops (tunnels, dense tree cover) | Worth it later, not in v2. Pair with a pedometer-style step×stride estimate, not raw integration of acceleration (that drifts in seconds). |
| [`flutter_background_geolocation`](https://pub.dev/packages/flutter_background_geolocation) | Battery-tuned background tracking on both platforms | Paid for production but the most reliable background story; consider only if `geolocator` background mode is insufficient. |
| [`pedometer`](https://pub.dev/packages/pedometer) | Hardware step count as a sanity check on distance | Cheap GPS-loss fallback. |
| [`flutter_map`](https://pub.dev/packages/flutter_map) + `flutter_map_tile_caching` | Post-run route polyline, offline tiles | UI only — no map matching. |

Skip `google_maps_flutter` unless you actually need Google tiles; it adds API-key overhead and binary size.

## 4. Minimum viable implementation plan

**v1 (current target).** `geolocator` stream → 5 m min-displacement filter → Haversine sum. Persist points + cumulative distance via the `sqflite` repository from `research.md`. Ship it.

**v2 — add robustness (do this next).**
- Spike filter: drop `accuracy > 25 m`, implied speed > 8 m/s, dt < 1 s.
- Kalman filter from §2 between the spike filter and the displacement filter.
- EMA on `Position.speed` for the pace readout (α ≈ 0.3).
- Unit-test with recorded `.gpx` fixtures (one clean run, one urban-canyon run, one stand-still) so regressions are catchable.

**v3 — resilience & polish.**
- `sensors_plus` + `pedometer` fallback: when no fix for > 5 s, estimate distance as `steps × strideLength` until GPS returns.
- Post-session Douglas-Peucker simplification of the stored polyline (display + storage only — keep raw points for the distance total).
- Optional `.gpx` export.

Defer HMM map matching indefinitely; it's the wrong tool for an off-road-friendly running app.

## 5. Battery & background considerations

A 30–90 min `accuracy: best` stream at 1 Hz is the single largest power draw in the app. Budget accordingly:

- **Sampling cadence.** 1 Hz fix rate is the sweet spot for running. Drop to 2–3 s when paused. Don't use sub-second polling — GPS hardware doesn't update faster than ~1 Hz on most phones anyway.
- **Accuracy tier.** Use `LocationAccuracy.best` (not `bestForNavigation` — that's tuned for driving and burns more power). On low battery (`Battery.level < 20%`), step down to `high`.
- **Android background.**
  - Declare `ACCESS_FINE_LOCATION` + `ACCESS_BACKGROUND_LOCATION` and request them in the foreground first, background second (Android 11+ enforces this two-step flow).
  - Run the tracking inside a **foreground service with a persistent notification** ("Run in progress — 2.4 km"). This is the only reliable way to keep GPS alive when the screen is off. `geolocator` ships `ForegroundNotificationConfig` for this.
  - Add `<uses-permission android:name="FOREGROUND_SERVICE_LOCATION"/>` (required on Android 14+).
- **iOS background.**
  - Add `UIBackgroundModes: location` to `Info.plist` and the `NSLocationAlwaysAndWhenInUseUsageDescription` string.
  - Set `allowsBackgroundLocationUpdates = true` (via `geolocator`'s `AppleSettings`) and `pausesLocationUpdatesAutomatically = false` — otherwise iOS will silently pause the stream mid-run.
  - The blue status bar / Dynamic Island indicator while tracking is expected and required by Apple.
- **Screen.** The screen, not GPS, is usually the biggest drain. Default to screen-off-friendly: persistent notification on Android, Live Activity on iOS (future enhancement).
- **Wake locks.** Don't hold a partial wake lock yourself — the foreground service + location updates already keep the CPU alive enough to process fixes.
- **Hygiene.** Stop the stream the instant the user taps Stop; don't leak it across navigation. Add an automatic safety cutoff (e.g. auto-stop after 4 h with no movement) so a forgotten session can't drain the battery overnight.

Rough budget on a modern mid-range phone with the above settings: ~6–10 %/hr battery for a screen-off run. Anything materially worse means the stream is mis-configured.
