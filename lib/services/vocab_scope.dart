/// Provides [VocabService] to the widget tree.
library;

import 'package:flutter/widgets.dart';

import 'vocab_service.dart';

/// Scoped access to saved learning words.
class VocabScope extends InheritedNotifier<VocabService> {
  const VocabScope({
    super.key,
    required VocabService service,
    required super.child,
  }) : super(notifier: service);

  static VocabService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VocabScope>();
    assert(
      scope != null,
      'VocabScope.of() called with no VocabScope in context.',
    );
    return scope!.notifier!;
  }
}
