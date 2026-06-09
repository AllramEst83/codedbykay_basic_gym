import 'package:flutter/material.dart';

enum WorkoutCategory { strength, cardio, yoga }


extension WorkoutCategoryX on WorkoutCategory {
  String get label {
    switch (this) {
      case WorkoutCategory.strength:
        return 'Strength';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.yoga:
        return 'Yoga';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutCategory.strength:
        return Icons.fitness_center_rounded;
      case WorkoutCategory.cardio:
        return Icons.directions_run_rounded;
      case WorkoutCategory.yoga:
        return Icons.self_improvement_rounded;
    }
  }
}

/// A single set of an exercise.
class WorkoutSet {
  WorkoutSet({
    required this.weightKg,
    required this.reps,
    this.completed = false,
  });

  double? weightKg;
  int? reps;
  bool completed;
}

/// One exercise inside a workout (e.g. "Barbell Bench Press").
class Exercise {
  Exercise({
    required this.name,
    required this.muscleGroup,
    required this.targetSets,
    required this.targetRepsLabel,
    required this.sets,
  });

  final String name;
  final String muscleGroup;
  final int targetSets;
  final String targetRepsLabel;
  final List<WorkoutSet> sets;
}

/// A workout template / scheduled workout.
class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.scheduledDay,
    this.imageUrl,
  });

  final String id;
  final String title;
  final WorkoutCategory category;
  final int durationMinutes;
  final int scheduledDay; // day of month for the demo calendar
  final String? imageUrl;
}

/// A historical entry shown on the progress screen.
class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.title,
    required this.dateLabel,
    required this.durationMinutes,
    required this.category,
    this.imageUrl,
  });

  final String title;
  final String dateLabel;
  final int durationMinutes;
  final WorkoutCategory category;
  final String? imageUrl;
}

/// A single exercise template inside a [Routine] (name, target sets/reps).
class ExerciseTemplate {
  const ExerciseTemplate({
    required this.name,
    required this.sets,
    required this.repsLabel,
  });

  final String name;
  final int sets;

  /// Human-readable reps description, e.g. "8-10" or "12-15".
  final String repsLabel;
}

/// A named workout routine belonging to a [WorkoutCategory].
class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.category,
    required this.exercises,
  });

  final String id;
  String name;
  final WorkoutCategory category;
  final List<ExerciseTemplate> exercises;

  int get exerciseCount => exercises.length;
}
