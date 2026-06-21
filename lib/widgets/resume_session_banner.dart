import 'package:flutter/material.dart';

import '../data/stores/in_progress_session_store.dart';
import '../data/stores/workout_store.dart';
import '../models/workout.dart';
import '../screens/active_session_screen.dart';
import '../screens/running_session_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'squish.dart';

/// Banner shown at the top of [CalendarScreen] and [WorkoutsScreen] when an
/// in-progress session was paused and is waiting to be resumed.
///
/// Listens directly to [InProgressSessionStore] so adding it to a screen
/// requires no extra plumbing — drop it into the build tree and it manages
/// its own visibility.
class ResumeSessionBanner extends StatefulWidget {
  const ResumeSessionBanner({super.key});

  @override
  State<ResumeSessionBanner> createState() => _ResumeSessionBannerState();
}

class _ResumeSessionBannerState extends State<ResumeSessionBanner> {
  @override
  void initState() {
    super.initState();
    InProgressSessionStore.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    InProgressSessionStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _resume(BuildContext context, InProgressSession session) async {
    final routine = WorkoutStore.instance.routineById(session.routineId);
    if (routine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The routine for this session has been deleted.',
          ),
        ),
      );
      return;
    }

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

    await ActiveSessionScreen.start(context, routine);
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = InProgressSessionStore.instance.sessions;
    if (sessions.isEmpty) return const SizedBox.shrink();

    final session = sessions.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Squish(
        onTap: () => _resume(context, session),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume ${session.routineName}',
                      style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.onTertiaryContainer,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${session.routineCategory.label} • '
                      '${_formatElapsed(session.elapsedSeconds)} logged',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onTertiaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
