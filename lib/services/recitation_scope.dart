/// Provides [RecitationService] to the widget tree.
library;

import 'package:flutter/widgets.dart';

import 'recitation_service.dart';

/// Scoped access to ayah recitation playback.
///
/// This is a plain [InheritedWidget], not [InheritedNotifier], so play
/// and download ticks do not rebuild the whole surah. Listen to
/// [RecitationService.playback] or the service itself where needed.
class RecitationScope extends InheritedWidget {
  const RecitationScope({
    super.key,
    required this.service,
    required super.child,
  });

  /// Ayah player for this app session.
  final RecitationService service;

  /// Retrieves the nearest [RecitationService], or throws.
  static RecitationService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecitationScope>();
    assert(
      scope != null,
      'RecitationScope.of() called with no RecitationScope in context.',
    );
    return scope!.service;
  }

  /// Like [of], or null when a test mounts a page without recitation.
  static RecitationService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RecitationScope>()
        ?.service;
  }

  @override
  bool updateShouldNotify(RecitationScope oldWidget) {
    return oldWidget.service != service;
  }
}
