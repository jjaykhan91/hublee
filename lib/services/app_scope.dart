import 'package:flutter/widgets.dart';

/// Makes top-level app actions (like toggleTheme) available anywhere via context.
class AppScope extends InheritedWidget {
  final VoidCallback toggleTheme;

  const AppScope({
    super.key,
    required this.toggleTheme,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.toggleTheme != toggleTheme;
}
