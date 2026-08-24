/// Provides appearance and theme actions via an [InheritedWidget].
library;

import 'package:flutter/widgets.dart';

import '../theme/app_appearance.dart';

/// Exposes [AppAppearance] so Settings and the reader sheet can set it.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.appearance,
    required ValueChanged<AppAppearance> setAppearance,
    required super.child,
  }) : _setAppearance = setAppearance;

  final AppAppearance appearance;
  final ValueChanged<AppAppearance> _setAppearance;

  /// Applies [value] and persists it.
  void setAppearance(AppAppearance value) => _setAppearance(value);

  /// Retrieves the nearest [AppScope].
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.appearance != appearance ||
      oldWidget._setAppearance != _setAppearance;
}
