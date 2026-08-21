/// Provides top-level app actions (e.g. theme toggle) via an
/// [InheritedWidget] so any descendant can access them.
library;

import 'package:flutter/widgets.dart';

/// Exposes global app-level actions through the widget tree.
///
/// Usage:
/// ```dart
/// AppScope.of(context).toggleTheme();
/// ```
class AppScope extends InheritedWidget {
  final VoidCallback _toggleTheme;

  const AppScope({
    super.key,
    required VoidCallback toggleTheme,
    required super.child,
  }) : _toggleTheme = toggleTheme;

  /// Switches between light and dark mode.
  void toggleTheme() => _toggleTheme();

  /// Retrieves the nearest [AppScope] from the widget tree.
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget._toggleTheme != _toggleTheme;
}
