import 'package:flutter/material.dart';

/// Abstract contract for key-value settings persistence.
abstract class SettingsRepository {
  /// Returns the raw string value for [key], or null if not set.
  Future<String?> get(String key);

  /// Persists [value] for [key], overwriting any existing entry.
  Future<void> set(String key, String value);

  // ── Typed helpers ──────────────────────────────────────────────────────────

  Future<ThemeMode> getThemeMode() async {
    final raw = await get('theme_mode');
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      set('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');

  Future<String?> getUserName() => get('user_name');

  Future<void> setUserName(String name) => set('user_name', name);
}
