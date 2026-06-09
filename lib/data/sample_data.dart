import '../models/workout.dart';

/// Static sample data used to populate screens. In a real app this would
/// come from a repository / database.
class SampleData {
  SampleData._();

  static final List<Workout> todaysWorkouts = [
    const Workout(
      id: 'leg-day',
      title: 'Leg Day',
      category: WorkoutCategory.strength,
      durationMinutes: 45,
      scheduledDay: 9,
    ),
    const Workout(
      id: 'evening-run',
      title: 'Evening Run',
      category: WorkoutCategory.cardio,
      durationMinutes: 30,
      scheduledDay: 9,
    ),
  ];

  /// Workouts mapped by day of month for the calendar demo.
  static final Map<int, List<Workout>> workoutsByDay = {
    5: [
      const Workout(
        id: 'upper-5',
        title: 'Upper Body',
        category: WorkoutCategory.strength,
        durationMinutes: 50,
        scheduledDay: 5,
      ),
    ],
    6: [
      const Workout(
        id: 'squat-6',
        title: 'Squat Session',
        category: WorkoutCategory.strength,
        durationMinutes: 40,
        scheduledDay: 6,
      ),
      const Workout(
        id: 'run-6',
        title: 'Morning Run',
        category: WorkoutCategory.cardio,
        durationMinutes: 25,
        scheduledDay: 6,
      ),
    ],
    9: todaysWorkouts,
    11: [
      const Workout(
        id: 'run-11',
        title: '5K Run',
        category: WorkoutCategory.cardio,
        durationMinutes: 35,
        scheduledDay: 11,
      ),
    ],
    13: [
      const Workout(
        id: 'push-13',
        title: 'Push Day',
        category: WorkoutCategory.strength,
        durationMinutes: 55,
        scheduledDay: 13,
      ),
    ],
    22: [
      const Workout(
        id: 'full-22',
        title: 'Full Body',
        category: WorkoutCategory.strength,
        durationMinutes: 60,
        scheduledDay: 22,
      ),
    ],
    25: [
      const Workout(
        id: 'back-25',
        title: 'Back & Biceps',
        category: WorkoutCategory.strength,
        durationMinutes: 45,
        scheduledDay: 25,
      ),
    ],
    28: [
      const Workout(
        id: 'run-28',
        title: 'Long Run',
        category: WorkoutCategory.cardio,
        durationMinutes: 60,
        scheduledDay: 28,
      ),
    ],
  };

  /// Days of the month that have at least one workout, with a list of
  /// category dot colors for the calendar markers.
  static const Map<int, List<WorkoutCategory>> calendarMarkers = {
    3: [WorkoutCategory.yoga],
    5: [WorkoutCategory.strength],
    6: [WorkoutCategory.strength, WorkoutCategory.cardio],
    9: [WorkoutCategory.strength, WorkoutCategory.cardio],
    11: [WorkoutCategory.cardio],
    13: [WorkoutCategory.strength],
    18: [WorkoutCategory.yoga],
    22: [WorkoutCategory.strength, WorkoutCategory.yoga],
    25: [WorkoutCategory.strength],
    28: [WorkoutCategory.cardio],
  };

  /// Workout categories shown on the Workouts screen.
  /// Yoga is intentionally excluded — it is handled elsewhere in the app.
  static const List<({String name, int routines, WorkoutCategory category})>
      workoutCategories = [
    (name: 'Gym', routines: 12, category: WorkoutCategory.strength),
    (name: 'Running', routines: 5, category: WorkoutCategory.cardio),
  ];

  static const List<({String title, String subtitle})> recentUpdates = [
    (title: 'Upper Body Power', subtitle: 'Gym • Modified Today'),
    (title: 'Morning 5K', subtitle: 'Running • Modified Yesterday'),
  ];

  /// Bar heights (0 - 1) for the weekly volume chart.
  static const List<({String label, double height, bool today})> weeklyVolume = [
    (label: 'Mon', height: 0.40, today: false),
    (label: 'Tue', height: 0.60, today: false),
    (label: 'Wed', height: 0.85, today: true),
    (label: 'Thu', height: 0.30, today: false),
    (label: 'Fri', height: 0.70, today: false),
    (label: 'Sat', height: 0.50, today: false),
    (label: 'Sun', height: 0.20, today: false),
  ];

  static const List<WorkoutHistoryEntry> history = [
    WorkoutHistoryEntry(
      title: 'Full Body Power',
      dateLabel: 'Today',
      durationMinutes: 45,
      category: WorkoutCategory.strength,
    ),
    WorkoutHistoryEntry(
      title: 'Core & Flow',
      dateLabel: 'Yesterday',
      durationMinutes: 30,
      category: WorkoutCategory.yoga,
    ),
    WorkoutHistoryEntry(
      title: 'Outdoor Run',
      dateLabel: 'Mon, Oct 12',
      durationMinutes: 60,
      category: WorkoutCategory.cardio,
    ),
    WorkoutHistoryEntry(
      title: 'Upper Body Sculpt',
      dateLabel: 'Sun, Oct 11',
      durationMinutes: 40,
      category: WorkoutCategory.strength,
    ),
    WorkoutHistoryEntry(
      title: 'Morning 5K',
      dateLabel: 'Sat, Oct 10',
      durationMinutes: 30,
      category: WorkoutCategory.cardio,
    ),
    WorkoutHistoryEntry(
      title: 'Leg Day',
      dateLabel: 'Fri, Oct 9',
      durationMinutes: 50,
      category: WorkoutCategory.strength,
    ),
  ];

  /// Active session demo content.
  static Exercise activeExercise() => Exercise(
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        targetSets: 4,
        targetRepsLabel: '4 Sets x 8-10 Reps',
        sets: [
          WorkoutSet(weightKg: 80, reps: 10, completed: true),
          WorkoutSet(weightKg: 82.5, reps: 8),
          WorkoutSet(weightKg: null, reps: null),
          WorkoutSet(weightKg: null, reps: null),
        ],
      );
}
