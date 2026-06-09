import 'package:flutter/material.dart';

/// App-level state shared across screens via module-level [ValueNotifier]s.
///
/// Initial values are set by [SettingsStore.hydrate] on app startup — do not
/// rely on these defaults beyond the brief splash before hydration completes.

/// Controls the active [ThemeMode] for [MaterialApp].
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

/// The current display name for the user (editable in Settings).
final ValueNotifier<String> userNameNotifier = ValueNotifier<String>('');
