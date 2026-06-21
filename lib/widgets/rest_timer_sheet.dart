import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_pill_button.dart';
import 'squish.dart';

/// Modal countdown timer used between sets during an active session.
///
/// Opens via [show] and resolves when the user skips or the countdown
/// reaches zero. Lets the user adjust the duration on the fly with the
/// +/- buttons.
class RestTimerSheet extends StatefulWidget {
  const RestTimerSheet({super.key, required this.initialSeconds});

  /// Default starting duration of the rest period.
  final int initialSeconds;

  /// Opens the timer as a non-dismissable bottom sheet so the user must
  /// explicitly skip or wait.
  static Future<void> show(
    BuildContext context, {
    int initialSeconds = 90,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => RestTimerSheet(initialSeconds: initialSeconds),
    );
  }

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _totalSeconds;
  late int _remaining;
  Timer? _ticker;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remaining = widget.initialSeconds;
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining--;
      });
      if (_remaining <= 0) {
        _ticker?.cancel();
        Future.microtask(() {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    });
  }

  void _adjust(int delta) {
    setState(() {
      _totalSeconds = (_totalSeconds + delta).clamp(15, 600);
      _remaining = (_remaining + delta).clamp(0, _totalSeconds);
    });
  }

  void _togglePause() => setState(() => _paused = !_paused);

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0
        ? 0.0
        : (1 - (_remaining / _totalSeconds)).clamp(0.0, 1.0);
    final inset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.lg,
        AppSpacing.containerMargin,
        inset + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _paused ? 'Rest paused' : 'Rest period',
            style: AppTextStyles.labelBold.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      _paused
                          ? AppColors.tertiary
                          : AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  _format(_remaining),
                  style: AppTextStyles.statNumber.copyWith(fontSize: 44),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustButton(
                icon: Icons.remove_rounded,
                label: '-15s',
                onTap: () => _adjust(-15),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AdjustButton(
                icon: _paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: _paused ? 'Resume' : 'Pause',
                onTap: _togglePause,
              ),
              const SizedBox(width: AppSpacing.sm),
              _AdjustButton(
                icon: Icons.add_rounded,
                label: '+15s',
                onTap: () => _adjust(15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: PrimaryPillButton(
              label: 'Skip Rest',
              elevated: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelBold.copyWith(
                color: AppColors.onSurface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
