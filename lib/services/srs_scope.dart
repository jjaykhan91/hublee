/// Provides [SrsService] to the widget tree.
library;

import 'package:flutter/widgets.dart';

import 'srs_service.dart';

class SrsScope extends InheritedNotifier<SrsService> {
  const SrsScope({super.key, required SrsService service, required super.child})
    : super(notifier: service);

  static SrsService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SrsScope>();
    assert(scope != null, 'SrsScope.of() called with no SrsScope in context.');
    return scope!.notifier!;
  }
}
