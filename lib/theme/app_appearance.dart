/// User-facing appearance: follow the OS, light, dark, or paper/sepia.
library;

import 'package:flutter/material.dart';

/// Four reading appearances. [paper] is a warm light theme.
enum AppAppearance {
  system,
  light,
  dark,
  paper;

  /// [ThemeMode] to feed [MaterialApp].
  ThemeMode get themeMode => switch (this) {
    AppAppearance.system => ThemeMode.system,
    AppAppearance.light || AppAppearance.paper => ThemeMode.light,
    AppAppearance.dark => ThemeMode.dark,
  };

  /// Short label for chips.
  String get label => switch (this) {
    AppAppearance.system => 'System',
    AppAppearance.light => 'Light',
    AppAppearance.dark => 'Dark',
    AppAppearance.paper => 'Paper',
  };

  IconData get icon => switch (this) {
    AppAppearance.system => Icons.brightness_auto_rounded,
    AppAppearance.light => Icons.light_mode_rounded,
    AppAppearance.dark => Icons.dark_mode_rounded,
    AppAppearance.paper => Icons.auto_stories_rounded,
  };
}
