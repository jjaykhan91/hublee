/// Persists and restores the user's chosen [ThemeMode] using
/// [SharedPreferences].
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple persistence layer for the app's light/dark theme setting.
///
/// Stores the [ThemeMode.index] as an integer under a single key.
class ThemeModeService {
  /// SharedPreferences key for the stored theme index.
  static const _kThemeModeKey = 'user_theme_mode';

  /// Saves the selected [mode] to disk.
  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, mode.index);
  }

  /// Loads the previously saved theme mode, defaulting to
  /// [ThemeMode.system] if none was stored.
  Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kThemeModeKey);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }
}
