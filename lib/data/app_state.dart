import 'dart:math';

import 'package:flutter/material.dart';

/// App-level state shared across screens via module-level [ValueNotifier]s.
///
/// Using simple notifiers avoids third-party state management for the small
/// amount of non-hierarchical global data this app needs.

/// Controls the active [ThemeMode] for [MaterialApp].
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

/// The current display name for the user (editable in Settings).
final ValueNotifier<String> userNameNotifier = ValueNotifier<String>(
  'User_${1000 + Random().nextInt(9000)}',
);
