import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeService {
  static const _key = 'user_theme_mode';

  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_key);
    if (idx == null) return ThemeMode.system;
    return ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
  }
}
