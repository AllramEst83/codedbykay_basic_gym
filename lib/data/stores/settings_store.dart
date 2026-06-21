import 'dart:math';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../repositories/settings_repository.dart';

/// Bridges [SettingsRepository] with the global [ValueNotifier]s used by the
/// UI. All writes go through the notifiers AND back to the repository so they
/// survive app restarts.
class SettingsStore {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  late SettingsRepository _repo;

  /// Reads persisted settings and populates the global notifiers.
  /// Generates and persists a random user name on first launch.
  Future<void> hydrate(SettingsRepository repo) async {
    _repo = repo;

    final mode = await repo.getThemeMode();
    themeModeNotifier.value = mode;

    var name = await repo.getUserName();
    if (name == null || name.isEmpty) {
      name = 'User_${1000 + Random().nextInt(9000)}';
      await repo.setUserName(name);
    }
    userNameNotifier.value = name;

    // Keep future changes written back to the DB.
    themeModeNotifier.addListener(_onThemeModeChanged);
    userNameNotifier.addListener(_onUserNameChanged);
  }

  void _onThemeModeChanged() {
    _repo.setThemeMode(themeModeNotifier.value);
  }

  void _onUserNameChanged() {
    final name = userNameNotifier.value;
    if (name.isNotEmpty) _repo.setUserName(name);
  }
}
