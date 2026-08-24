/// Persists and restores the user's [AppAppearance].
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_appearance.dart';

/// Stores appearance as a string, with a fallback from the old
/// [ThemeMode.index] integer key.
class ThemeModeService {
  static const _kAppearanceKey = 'user_appearance';
  static const _kLegacyThemeModeKey = 'user_theme_mode';

  /// Saves [appearance] to disk.
  Future<void> save(AppAppearance appearance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppearanceKey, appearance.name);
  }

  /// Loads appearance, defaulting to [AppAppearance.system].
  Future<AppAppearance> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kAppearanceKey);
    if (name != null) {
      return AppAppearance.values.firstWhere(
        (value) => value.name == name,
        orElse: () => AppAppearance.system,
      );
    }

    final index = prefs.getInt(_kLegacyThemeModeKey);
    if (index == null) return AppAppearance.system;
    final mode = ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
    return switch (mode) {
      ThemeMode.light => AppAppearance.light,
      ThemeMode.dark => AppAppearance.dark,
      ThemeMode.system => AppAppearance.system,
    };
  }
}
