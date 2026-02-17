/// Provides [SettingsController] to the widget tree via
/// [InheritedNotifier], so descendants auto-rebuild when
/// settings change.
library;

import 'package:flutter/widgets.dart';

import 'settings_controller.dart';

/// Scoped access to the app's [SettingsController].
///
/// Usage:
/// ```dart
/// final settings = SettingsScope.of(context);
/// final zoom = settings.arabicZoom;
/// ```
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Retrieves the nearest [SettingsController] from the tree.
  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(
      scope != null,
      'SettingsScope.of() called with no SettingsScope in context.',
    );
    return scope!.notifier!;
  }
}
