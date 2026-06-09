import 'package:intl/intl.dart';

import '../models/workout.dart';

/// Reference body mass (kg) for calorie estimates when the user has not
/// provided weight.
const double kCalorieReferenceWeightKg = 70.0;

/// Total weight lifted (kg) across all completed sets with weight and reps.
double sessionVolumeKg(WorkoutSession session) {
  var total = 0.0;
  for (final exercise in session.exercises) {
    for (final set in exercise.sets) {
      if (set.completed && set.weightKg != null && set.reps != null) {
        total += set.weightKg! * set.reps!;
      }
    }
  }
  return total;
}

/// Rough calorie estimate using MET values and [kCalorieReferenceWeightKg].
int estimateSessionCalories(WorkoutSession session) {
  final hours = session.durationSeconds / 3600.0;
  if (hours <= 0) return 0;
  return (_metForSession(session) * kCalorieReferenceWeightKg * hours).round();
}

double _metForSession(WorkoutSession session) {
  switch (session.category) {
    case WorkoutCategory.strength:
      return 5.0;
    case WorkoutCategory.yoga:
      return 3.0;
    case WorkoutCategory.cardio:
      final km = session.distanceKm;
      if (km != null && km > 0 && session.durationSeconds > 0) {
        final speedKmh = km / (session.durationSeconds / 3600.0);
        if (speedKmh < 6) return 6.0;
        if (speedKmh < 8) return 8.3;
        if (speedKmh < 10) return 9.8;
        if (speedKmh < 12) return 11.0;
        return 12.8;
      }
      return 7.0;
  }
}

DateTime _dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Monday 00:00 of the week containing [date].
DateTime startOfWeek(DateTime date) {
  final local = _dateOnly(date);
  return local.subtract(Duration(days: local.weekday - 1));
}

bool isInCurrentWeek(DateTime date, DateTime now) {
  final weekStart = startOfWeek(now);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final day = _dateOnly(date);
  return !day.isBefore(weekStart) && day.isBefore(weekEnd);
}

/// Total workout minutes for sessions completed in the current calendar week.
int thisWeekDurationMinutes(List<WorkoutSession> sessions, DateTime now) {
  final totalSeconds = sessions
      .where((s) => isInCurrentWeek(s.completedAt, now))
      .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  return (totalSeconds / 60).round();
}

/// Estimated calories burned this calendar week.
int thisWeekCalories(List<WorkoutSession> sessions, DateTime now) {
  return sessions
      .where((s) => isInCurrentWeek(s.completedAt, now))
      .fold<int>(0, (sum, s) => sum + estimateSessionCalories(s));
}

/// Bar data for the last 7 days of lifting volume, normalized to 0–1 height.
List<({String label, double height, bool today})> lastSevenDaysVolumeBars(
  List<WorkoutSession> sessions,
  DateTime now,
) {
  final today = _dateOnly(now);
  final days = List.generate(
    7,
    (i) => today.subtract(Duration(days: 6 - i)),
  );

  final volumesByDay = {for (final day in days) day: 0.0};

  for (final session in sessions) {
    final day = _dateOnly(session.completedAt);
    if (volumesByDay.containsKey(day)) {
      volumesByDay[day] = volumesByDay[day]! + sessionVolumeKg(session);
    }
  }

  final maxVolume =
      volumesByDay.values.fold<double>(0, (a, b) => a > b ? a : b);

  return [
    for (final day in days)
      (
        label: DateFormat('E').format(day).substring(0, 3),
        height: maxVolume > 0 ? volumesByDay[day]! / maxVolume : 0.0,
        today: day == today,
      ),
  ];
}
