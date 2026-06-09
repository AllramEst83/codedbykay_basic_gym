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

  String toJson() => name;

  static WorkoutCategory fromJson(String value) =>
      WorkoutCategory.values.firstWhere((e) => e.name == value);
}

// ─────────────────────────────────────────────────────────────────────────────
// Active-session runtime models (not persisted directly)
// ─────────────────────────────────────────────────────────────────────────────

/// A single set of an exercise during an active session.
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

// ─────────────────────────────────────────────────────────────────────────────
// Persisted domain models
// ─────────────────────────────────────────────────────────────────────────────

/// A single exercise template inside a [Routine] (name, target sets/reps).
class ExerciseTemplate {
  const ExerciseTemplate({
    required this.id,
    required this.name,
    required this.sets,
    required this.repsLabel,
  });

  final String id;
  final String name;
  final int sets;

  /// Human-readable reps description, e.g. "8-10" or "12-15".
  final String repsLabel;

  Map<String, dynamic> toMap({required String routineId, required int orderIndex}) => {
        'id': id,
        'routine_id': routineId,
        'name': name,
        'sets': sets,
        'reps_label': repsLabel,
        'order_index': orderIndex,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'repsLabel': repsLabel,
      };

  static ExerciseTemplate fromMap(Map<String, dynamic> m) => ExerciseTemplate(
        id: m['id'] as String,
        name: m['name'] as String,
        sets: m['sets'] as int,
        repsLabel: m['reps_label'] as String,
      );
}

/// A named workout routine belonging to a [WorkoutCategory].
class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.category,
    required this.exercises,
    this.targetKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  final WorkoutCategory category;
  final List<ExerciseTemplate> exercises;

  /// Target distance in kilometres for cardio/running routines.
  final double? targetKm;

  final DateTime createdAt;
  DateTime updatedAt;

  int get exerciseCount => exercises.length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'target_km': targetKm,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': null,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.toJson(),
        'targetKm': targetKm,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Routine fromMap(Map<String, dynamic> m, List<ExerciseTemplate> exercises) =>
      Routine(
        id: m['id'] as String,
        name: m['name'] as String,
        category: WorkoutCategory.values.firstWhere(
          (e) => e.name == m['category'],
        ),
        exercises: exercises,
        targetKm: m['target_km'] as double?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}

/// A workout scheduled to a specific date.
class Workout {
  Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.scheduledDate,
    this.routineId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final WorkoutCategory category;
  final int durationMinutes;

  /// Full date this workout is scheduled on (time portion ignored).
  final DateTime scheduledDate;

  /// Optional back-reference to the [Routine] this was created from.
  final String? routineId;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Day-of-month accessor kept for backwards-compat with calendar UI.
  int get scheduledDay => scheduledDate.day;

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'title': title,
        'category': category.name,
        'duration_minutes': durationMinutes,
        'scheduled_date': scheduledDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': null,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'title': title,
        'category': category.toJson(),
        'durationMinutes': durationMinutes,
        'scheduledDate': scheduledDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Workout fromMap(Map<String, dynamic> m) => Workout(
        id: m['id'] as String,
        routineId: m['routine_id'] as String?,
        title: m['title'] as String,
        category: WorkoutCategory.values.firstWhere(
          (e) => e.name == m['category'],
        ),
        durationMinutes: m['duration_minutes'] as int,
        scheduledDate: DateTime.fromMillisecondsSinceEpoch(
          m['scheduled_date'] as int,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Session models
// ─────────────────────────────────────────────────────────────────────────────

/// A completed set recorded during a session.
class SessionSet {
  SessionSet({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    this.weightKg,
    this.reps,
    this.completed = false,
  });

  final String id;
  final String exerciseId;
  final int orderIndex;
  double? weightKg;
  int? reps;
  bool completed;

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'weight_kg': weightKg,
        'reps': reps,
        'completed': completed ? 1 : 0,
        'order_index': orderIndex,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'orderIndex': orderIndex,
        'weightKg': weightKg,
        'reps': reps,
        'completed': completed,
      };

  static SessionSet fromMap(Map<String, dynamic> m) => SessionSet(
        id: m['id'] as String,
        exerciseId: m['exercise_id'] as String,
        orderIndex: m['order_index'] as int,
        weightKg: m['weight_kg'] as double?,
        reps: m['reps'] as int?,
        completed: (m['completed'] as int) == 1,
      );
}

/// An exercise recorded during a session.
class SessionExercise {
  SessionExercise({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.orderIndex,
    required this.sets,
    this.muscleGroup,
  });

  final String id;
  final String sessionId;
  final String name;
  final String? muscleGroup;
  final int orderIndex;
  final List<SessionSet> sets;

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'name': name,
        'muscle_group': muscleGroup,
        'order_index': orderIndex,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'name': name,
        'muscleGroup': muscleGroup,
        'orderIndex': orderIndex,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  static SessionExercise fromMap(
    Map<String, dynamic> m,
    List<SessionSet> sets,
  ) =>
      SessionExercise(
        id: m['id'] as String,
        sessionId: m['session_id'] as String,
        name: m['name'] as String,
        muscleGroup: m['muscle_group'] as String?,
        orderIndex: m['order_index'] as int,
        sets: sets,
      );
}

/// A fully completed workout session (strength or running/cardio).
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.title,
    required this.category,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
    required this.exercises,
    this.routineId,
    this.distanceKm,
    this.targetKm,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String? routineId;
  final String title;
  final WorkoutCategory category;
  final int durationSeconds;

  /// Null for strength sessions; set for running/cardio.
  final double? distanceKm;

  /// Null for strength sessions; set for running/cardio.
  final double? targetKm;

  final DateTime startedAt;
  final DateTime completedAt;
  final String? notes;
  final List<SessionExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'title': title,
        'category': category.name,
        'duration_seconds': durationSeconds,
        'distance_km': distanceKm,
        'target_km': targetKm,
        'started_at': startedAt.millisecondsSinceEpoch,
        'completed_at': completedAt.millisecondsSinceEpoch,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': null,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'title': title,
        'category': category.toJson(),
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
        'targetKm': targetKm,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'notes': notes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static WorkoutSession fromMap(
    Map<String, dynamic> m,
    List<SessionExercise> exercises,
  ) =>
      WorkoutSession(
        id: m['id'] as String,
        routineId: m['routine_id'] as String?,
        title: m['title'] as String,
        category: WorkoutCategory.values.firstWhere(
          (e) => e.name == m['category'],
        ),
        durationSeconds: m['duration_seconds'] as int,
        distanceKm: m['distance_km'] as double?,
        targetKm: m['target_km'] as double?,
        startedAt: DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        completedAt:
            DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        notes: m['notes'] as String?,
        exercises: exercises,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy display model (sample_data.dart only, not persisted)
// ─────────────────────────────────────────────────────────────────────────────

/// A historical entry for sample/dev data display only.
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
