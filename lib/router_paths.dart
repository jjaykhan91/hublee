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
  static const String learn = '/learn';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';

  // ── Full-screen (no bottom nav) ───────────────────────────────
  static const String search = '/search';
  static const String onboarding = '/onboarding';
  static const String tajweedGuide = '/tajweed-guide';
  static const String diagnostics = '/diagnostics';
  static const String privacy = '/privacy';
  static const String dictionary = '/dictionary';
  static const String learnQuranic = '/learn/quranic';
  static const String quranReview = '/learn/review';
  static const String arabicHub = '/arabic';
  static const String msaDictionary = '/arabic/dictionary';
  static const String grammar = '/arabic/grammar';
  static const String arabicReview = '/arabic/review';

  static String grammarLesson(String id) =>
      '/arabic/grammar/${Uri.encodeComponent(id)}';

  /// Path to surah reader, optionally with ayah to scroll to.
  static String surah(int surahId, {int? ayah}) {
    if (ayah == null) return '/quran/$surahId';
    return '/quran/$surahId?ayah=$ayah';
  }

  /// Canonical Quran range.
  static const int minSurahId = 1;
  static const int maxSurahId = 114;

  /// Parses a path parameter as a surah id, or `null` if it is missing
  /// or outside 1–114.
  static int? tryParseSurahId(String? raw) {
    final id = int.tryParse(raw ?? '');
    if (id == null || id < minSurahId || id > maxSurahId) return null;
    return id;
  }

  /// Path to hadith book reader, optionally with hadith index
  /// and/or chapter id.
  static String hadithBook({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
    int? index,
    int? chapterId,
  }) {
    final base =
        '/hadith/$collectionId/$bookFile?title=${Uri.encodeComponent(bookTitle)}';
    final withIndex = index == null ? base : '$base&index=$index';
    return chapterId == null ? withIndex : '$withIndex&chapter=$chapterId';
  }

  /// Path to the chapter tile grid for a hadith book.
  static String hadithChapters({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
  }) {
    return '/hadith/$collectionId/$bookFile/chapters'
        '?title=${Uri.encodeComponent(bookTitle)}';
  }
}
