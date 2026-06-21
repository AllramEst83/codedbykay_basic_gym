import 'package:flutter/material.dart';

import '../../models/workout.dart';

/// Whether a scheduled workout has a matching completed session on [date].
enum WorkoutCompletionStatus {
  /// User finished and every set was marked complete.
  complete,

  /// User finished but at least one set was left incomplete.
  partial,
}

/// Returns the completion status for [workout] on [date], or null if no session
/// was recorded that day.
WorkoutCompletionStatus? completionStatusForWorkout(
  Workout workout,
  List<WorkoutSession> sessions,
  DateTime date,
) {
  final match = sessions.where((s) => _matchesWorkout(s, workout, date)).firstOrNull;
  if (match == null) return null;

  if (match.category == WorkoutCategory.cardio) {
    return WorkoutCompletionStatus.complete;
  }

  final sets = match.exercises.expand((e) => e.sets);
  if (sets.isEmpty) return WorkoutCompletionStatus.complete;

  return sets.every((s) => s.completed)
      ? WorkoutCompletionStatus.complete
      : WorkoutCompletionStatus.partial;
}

bool _matchesWorkout(WorkoutSession session, Workout workout, DateTime date) {
  if (!DateUtils.isSameDay(session.completedAt, date)) return false;
  if (workout.routineId != null && session.routineId == workout.routineId) {
    return true;
  }
  return session.title == workout.title;
}
