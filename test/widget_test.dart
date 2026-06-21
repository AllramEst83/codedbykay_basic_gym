import 'package:codedbykay_basic_gym/data/utils/progress_stats.dart';
import 'package:codedbykay_basic_gym/models/workout.dart';
import 'package:codedbykay_basic_gym/theme/app_colors.dart';
import 'package:codedbykay_basic_gym/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    // testWidgets ensures the test binding is initialized so GoogleFonts
    // can resolve its bundled font lookup table without throwing.
    testWidgets('light theme uses Material 3 with the primary mint color',
        (tester) async {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    testWidgets('dark theme uses Material 3 with an inverted scheme',
        (tester) async {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.inversePrimary, AppColors.primary);
    });
  });

  group('progress stats', () {
    final today = DateTime(2026, 6, 21, 12);

    WorkoutSession buildStrengthSession({
      required DateTime completedAt,
      int durationSeconds = 1800,
      List<({double weight, int reps, bool done})> sets = const [],
    }) {
      final sessionId = 'session_${completedAt.millisecondsSinceEpoch}';
      const exId = 'ex_1';
      return WorkoutSession(
        id: sessionId,
        title: 'Push Day',
        category: WorkoutCategory.strength,
        durationSeconds: durationSeconds,
        startedAt: completedAt
            .subtract(Duration(seconds: durationSeconds)),
        completedAt: completedAt,
        exercises: [
          SessionExercise(
            id: exId,
            sessionId: sessionId,
            name: 'Bench Press',
            orderIndex: 0,
            sets: [
              for (var i = 0; i < sets.length; i++)
                SessionSet(
                  id: '${exId}_$i',
                  exerciseId: exId,
                  orderIndex: i,
                  weightKg: sets[i].weight,
                  reps: sets[i].reps,
                  completed: sets[i].done,
                ),
            ],
          ),
        ],
      );
    }

    test('sessionVolumeKg sums completed sets only', () {
      final session = buildStrengthSession(
        completedAt: today,
        sets: const [
          (weight: 60, reps: 10, done: true), // 600
          (weight: 80, reps: 8, done: true), // 640
          (weight: 100, reps: 5, done: false), // skipped
        ],
      );
      expect(sessionVolumeKg(session), 1240);
    });

    test('thisWeekDurationMinutes only counts current-week sessions', () {
      final lastWeek = today.subtract(const Duration(days: 8));
      final sessions = [
        buildStrengthSession(completedAt: today, durationSeconds: 1800),
        buildStrengthSession(completedAt: lastWeek, durationSeconds: 3600),
      ];
      expect(thisWeekDurationMinutes(sessions, today), 30);
    });

    test('lastSevenDaysVolumeBars produces 7 entries with today marked', () {
      final bars = lastSevenDaysVolumeBars(const [], today);
      expect(bars.length, 7);
      expect(bars.last.today, isTrue);
      expect(bars.first.today, isFalse);
    });
  });

  group('WorkoutCategory display', () {
    test('label returns human-readable name', () {
      expect(WorkoutCategory.strength.label, 'Strength');
      expect(WorkoutCategory.cardio.label, 'Cardio');
      expect(WorkoutCategory.yoga.label, 'Yoga');
    });

    test('icon is set for every category', () {
      for (final c in WorkoutCategory.values) {
        expect(c.icon, isA<IconData>());
      }
    });
  });
}
