import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/flex_bottom_nav.dart';
import '../widgets/flex_top_bar.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'workouts_screen.dart';

/// Hosts the four bottom-nav destinations behind a shared top app bar.
///
/// Requests location and audio permissions on the first frame so the user
/// is prompted before they reach any feature that needs them.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // start on Calendar (home)

  static const _pages = <Widget>[
    WorkoutsScreen(),
    CalendarScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Request after the first frame so context/navigator is ready.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _requestLaunchPermissions());
  }

  // ── Permission helpers ──────────────────────────────────────────────────

  Future<void> _requestLaunchPermissions() async {
    // Location for GPS distance tracking.
    await _requestIfNeeded(
      permission: Permission.location,
      label: 'Location (GPS)',
      reason: 'Required for tracking distance during runs.',
    );
    if (!mounted) return;

    // Audio for kilometre cues; fall back to Storage when audio is unavailable.
    final audioGranted = await _requestIfNeeded(
      permission: Permission.audio,
      label: 'Audio Cues',
      reason: 'Plays a sound at each completed kilometer.',
    );
    if (!mounted) return;

    if (!audioGranted) {
      await _requestIfNeeded(
        permission: Permission.storage,
        label: 'Audio Cues (Storage)',
        reason: 'Storage access is needed to play kilometre audio cues during runs.',
      );
      if (!mounted) return;
    }
  }

  /// Requests [permission] if it has not been granted yet.
  ///
  /// Shows an [AlertDialog] with an "Open Settings" button when permanently
  /// denied. Returns `true` if the permission is granted after the call.
  Future<bool> _requestIfNeeded({
    required Permission permission,
    required String label,
    required String reason,
  }) async {
    final status = await permission.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      await _showPermanentlyDeniedDialog(label: label, reason: reason);
      return false;
    }

    if (status.isDenied || status.isRestricted) {
      final result = await permission.request();
      if (!mounted) return false;
      if (result.isPermanentlyDenied) {
        await _showPermanentlyDeniedDialog(label: label, reason: reason);
        if (!mounted) return false;
      }
      return result.isGranted;
    }

    return false;
  }

  Future<void> _showPermanentlyDeniedDialog({
    required String label,
    required String reason,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Permission'),
        content: Text(
          '$reason\n\n'
          'This permission has been permanently denied. '
          'Tap "Open Settings" to enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const FlexTopBar(),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _pages[_index],
          ),
        ),
      ),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
