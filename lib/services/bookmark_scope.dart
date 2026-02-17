/// Provides [BookmarkService] to the widget tree via
/// [InheritedNotifier], so descendants auto-rebuild when
/// bookmarks change.
library;

import 'package:flutter/widgets.dart';

import 'bookmark_service.dart';

/// Scoped access to the app's [BookmarkService].
///
/// Usage:
/// ```dart
/// final bookmarks = BookmarkScope.of(context);
/// final isMarked = bookmarks.isBookmarked('quran:1:3');
/// ```
class BookmarkScope extends InheritedNotifier<BookmarkService> {
  const BookmarkScope({
    super.key,
    required BookmarkService service,
    required super.child,
  }) : super(notifier: service);

  /// Retrieves the nearest [BookmarkService] from the tree.
  static BookmarkService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BookmarkScope>();
    assert(
      scope != null,
      'BookmarkScope.of() called with no BookmarkScope in context.',
    );
    return scope!.notifier!;
  }
}
