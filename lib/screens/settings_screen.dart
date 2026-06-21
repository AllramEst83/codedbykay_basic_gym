import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/squish.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool get _darkMode => themeModeNotifier.value == ThemeMode.dark;

  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _audioStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatuses();
    }
  }

  Future<void> _loadPermissionStatuses() async {
    final location = await Permission.location.status;
    final audio = await Permission.audio.status;
    if (!mounted) return;
    setState(() {
      _locationStatus = location;
      _audioStatus = audio;
    });
  }

  // ── Permission tap handlers ─────────────────────────────────────────────

  Future<void> _onLocationTap() async {
    if (_locationStatus.isGranted) return;

    if (_locationStatus.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is permanently denied — enable it in system Settings.',
          ),
        ),
      );
      await openAppSettings();
      return;
    }

    final result = await Permission.location.request();
    if (!mounted) return;
    setState(() => _locationStatus = result);
  }

  Future<void> _onAudioTap() async {
    if (_audioStatus.isGranted) return;

    if (_audioStatus.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio Cues is permanently denied — enable it in system Settings.',
          ),
        ),
      );
      await openAppSettings();
      return;
    }

    final result = await Permission.audio.request();
    if (!mounted) return;
    setState(() => _audioStatus = result);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.gutter,
          AppSpacing.containerMargin,
          AppSpacing.lg + 80,
        ),
        children: [
          _NameCard(),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Preferences'),
          const SizedBox(height: AppSpacing.base),
          _SettingsGroup(
            children: [
              _ToggleRow(
                icon: Icons.palette_outlined,
                title: 'App Theme',
                subtitle: _darkMode ? 'Dark Mode' : 'Light Mode',
                value: _darkMode,
                onChanged: (v) {
                  setState(() {
                    themeModeNotifier.value =
                        v ? ThemeMode.dark : ThemeMode.light;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Permissions'),
          const SizedBox(height: AppSpacing.base),
          _SettingsGroup(
            children: [
              _PermissionRow(
                icon: Icons.location_on_outlined,
                title: 'Location (GPS)',
                description: 'Required for tracking distance during runs',
                status: _locationStatus,
                onTap: _locationStatus.isGranted ? null : _onLocationTap,
              ),
              const _RowDivider(),
              _PermissionRow(
                icon: Icons.volume_up_outlined,
                title: 'Audio Cues',
                description: 'Plays a sound at each completed kilometer',
                status: _audioStatus,
                onTap: _audioStatus.isGranted ? null : _onAudioTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Name card (replaces the account details card)
// ────────────────────────────────────────────────────────────────────────

class _NameCard extends StatefulWidget {
  @override
  State<_NameCard> createState() => _NameCardState();
}

class _NameCardState extends State<_NameCard> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: userNameNotifier.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _controller.text = userNameNotifier.value;
      _editing = true;
    });
  }

  void _save() {
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      userNameNotifier.value = trimmed;
    }
    setState(() => _editing = false);
  }

  void _cancel() {
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: userNameNotifier,
      builder: (context, name, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -32,
                top: -32,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                      border: Border.all(
                        color: AppColors.surfaceContainer,
                        width: 4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _editing
                        ? _NameEditField(
                            controller: _controller,
                            onSave: _save,
                            onCancel: _cancel,
                          )
                        : _NameDisplay(
                            name: name,
                            onEditTap: _startEditing,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NameDisplay extends StatelessWidget {
  const _NameDisplay({required this.name, required this.onEditTap});

  final String name;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppTextStyles.headlineMd),
        const SizedBox(height: AppSpacing.sm),
        Squish(
          onTap: onEditTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.base),
                Text(
                  'Edit Name',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NameEditField extends StatelessWidget {
  const _NameEditField({
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Squish(
              onTap: onCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Squish(
              onTap: onSave,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Save',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Shared settings widgets
// ────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.base),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

/// Thin separator between rows inside a [_SettingsGroup], inset to align
/// with the label text (after the icon tile).
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md + 48 + AppSpacing.sm,
      ),
      child: const Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _IconTile(
            icon: icon,
            bg: AppColors.secondaryContainer,
            fg: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.bodyMd),
              ],
            ),
          ),
          _PillSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A settings row that reflects a [PermissionStatus].
///
/// Tapping calls [onTap] (nil when the permission is already granted).
/// The pill switch is visual-only; the entire row is the tap target,
/// wrapped in [Squish] for tactile feedback.
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final VoidCallback? onTap;

  String get _statusLabel {
    if (status.isGranted) return 'Granted';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    if (status.isRestricted) return 'Restricted';
    return 'Denied';
  }

  Color get _statusColor =>
      status.isGranted ? AppColors.primary : AppColors.tertiary;

  @override
  Widget build(BuildContext context) {
    return Squish(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _IconTile(
              icon: icon,
              bg: AppColors.secondaryContainer,
              fg: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(description, style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.xs),
                  _StatusBadge(label: _statusLabel, color: _statusColor),
                ],
              ),
            ),
            // Visual-only switch; the Squish row owns the tap.
            IgnorePointer(
              child: _PillSwitch(
                value: status.isGranted,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill badge showing a permission status string.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelBold.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.bg, required this.fg});

  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: 22),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
