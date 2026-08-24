/// Provides [RecitationService] to the widget tree.
library;

import 'package:flutter/widgets.dart';

import 'recitation_service.dart';

/// Scoped access to ayah recitation playback.
class RecitationScope extends InheritedNotifier<RecitationService> {
  const RecitationScope({
    super.key,
    required RecitationService service,
    required super.child,
  }) : super(notifier: service);

  /// Retrieves the nearest [RecitationService], or throws.
  static RecitationService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecitationScope>();
    assert(
      scope != null,
      'RecitationScope.of() called with no RecitationScope in context.',
    );
    return scope!.notifier!;
  }

  /// Like [of], or null when a test mounts a page without recitation.
  static RecitationService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RecitationScope>()
        ?.notifier;
  }
}
