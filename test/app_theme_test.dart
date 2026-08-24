/// Theme tokens that must stay in sync with `.cursor/rules/theming.mdc`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/theme/app_theme.dart';

void main() {
  test('light cards use elevation 1', () {
    expect(buildLightTheme().cardTheme.elevation, 1);
  });

  test('dark cards use no elevation', () {
    expect(buildDarkTheme().cardTheme.elevation, 0);
  });

  test('page transitions cover desktop platforms', () {
    final builders = buildLightTheme().pageTransitionsTheme.builders;
    expect(builders[TargetPlatform.windows], isNotNull);
    expect(builders[TargetPlatform.linux], isNotNull);
    expect(builders[TargetPlatform.macOS], isNotNull);
  });

  test('paper theme is light and uses elevation 1 cards', () {
    final theme = buildPaperTheme();
    expect(theme.brightness, Brightness.light);
    expect(theme.cardTheme.elevation, 1);
  });
}
