/// Maps `hublee://` launcher-widget taps to in-app routes.
library;

import 'package:flutter/foundation.dart';

import '../router_paths.dart';

/// Holds a widget tap that arrived before the router left splash.
abstract final class WidgetLaunch {
  WidgetLaunch._();

  static Uri? _pending;

  /// Drops a held tap. Tests only.
  @visibleForTesting
  static void reset() => _pending = null;

  /// Stores [uri] to open after splash.
  static void hold(Uri? uri) {
    if (uri != null) _pending = uri;
  }

  /// Returns an in-app path and clears the pending tap.
  static String? takePath() {
    final uri = _pending;
    _pending = null;
    return uri == null ? null : pathForWidgetUri(uri);
  }
}

/// Maps a `hublee://` widget tap to an [AppRoute] path.
String? pathForWidgetUri(Uri uri) {
  if (uri.scheme != 'hublee') return null;
  switch (uri.host) {
    case 'ayah':
      final surah = AppRoute.tryParseSurahId(uri.queryParameters['surah']);
      if (surah == null) return null;
      final ayah = int.tryParse(uri.queryParameters['ayah'] ?? '');
      return AppRoute.surah(surah, ayah: ayah);
    case 'hadith':
      final collection = uri.queryParameters['collection'] ?? 'forties';
      final book = uri.queryParameters['book'] ?? 'nawawi40.json';
      final title = uri.queryParameters['title'] ?? 'Nawawi 40';
      final index = int.tryParse(uri.queryParameters['index'] ?? '');
      return AppRoute.hadithBook(
        collectionId: collection,
        bookFile: book,
        bookTitle: title,
        index: index,
      );
    case 'arabic':
      return AppRoute.msaDictionary;
    default:
      return null;
  }
}
