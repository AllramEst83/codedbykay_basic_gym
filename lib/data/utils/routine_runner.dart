import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../screens/active_session_screen.dart';
import '../../screens/running_session_screen.dart';

/// Navigation helpers for launching the right session screen for a [Routine].
///
/// Centralizes the strength-vs-cardio branching and the empty-routine guard
/// so all entry points (Calendar, Workouts, Routine Management) behave the
/// same way and produce consistent feedback when the routine cannot be run.
class RoutineRunner {
  const RoutineRunner._();

  /// Launches the appropriate session screen for [routine].
  ///
  /// - Cardio routines open the [RunningSessionScreen] with the routine's
  ///   target distance (defaulting to 5km when unset).
  /// - Strength routines without any exercises show a `SnackBar` instructing
  ///   the user to add exercises before starting.
  /// - All other strength routines open the [ActiveSessionScreen],
  ///   resuming the saved in-progress session when one exists.
  static Future<void> start(BuildContext context, Routine routine) async {
    if (routine.category == WorkoutCategory.cardio) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RunningSessionScreen(
            routine: routine,
            targetKm: routine.targetKm ?? 5.0,
          ),
        ),
      );
      return;
    }

    if (routine.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This routine has no exercises. Edit it to add some first.',
          ),
        ),
      );
      return;
    }

    await ActiveSessionScreen.start(context, routine);
  }
}
