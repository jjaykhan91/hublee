/// Typed route paths and helpers for navigation.
///
/// Use [AppRoute] instead of hard-coded path strings so that
/// route changes are made in one place.
library;

/// Central place for all route path construction.
abstract final class AppRoute {
  AppRoute._();

  // ── Tab roots ─────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String home = '/home';
  static const String quran = '/quran';
  static const String hadith = '/hadith';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';

  // ── Full-screen (no bottom nav) ───────────────────────────────
  static const String search = '/search';
  static const String tajweedGuide = '/tajweed-guide';

  /// Path to surah reader, optionally with ayah to scroll to.
  static String surah(int surahId, {int? ayah}) {
    if (ayah == null) return '/quran/$surahId';
    return '/quran/$surahId?ayah=$ayah';
  }

  /// Path to hadith book reader, optionally with hadith index.
  static String hadithBook({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
    int? index,
  }) {
    final base =
        '/hadith/$collectionId/$bookFile?title=${Uri.encodeComponent(bookTitle)}';
    return index == null ? base : '$base&index=$index';
  }
}
