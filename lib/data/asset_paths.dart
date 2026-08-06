/// Centralises all bundled-asset file paths.
///
/// Every repository should reference paths through this class
/// instead of hard-coding strings, so a path change only needs
/// to happen in one place.
library;

/// Static helpers that resolve asset paths for Quran and Hadith
/// data files bundled in the `assets/` directory.
class AssetPaths {
  AssetPaths._(); // prevent instantiation

  // ── Hadith ──────────────────────────────────────────────────
  static const hadithRoot = 'assets/hadith';

  /// Path to a specific hadith book JSON file.
  ///
  /// Example: `AssetPaths.hadith('forties', 'nawawi40.json')`
  /// → `'assets/hadith/forties/nawawi40.json'`
  static String hadith(String collectionId, String fileName) =>
      '$hadithRoot/$collectionId/$fileName';

  // ── Quran ───────────────────────────────────────────────────
  static const quranRoot = 'assets/quran';

  /// Per-surah standard Uthmanic Arabic text (standard Unicode with
  /// full tashkeel): `assets/quran/ar/<surahId>.json`.
  ///
  /// Downloaded from quran.com API `text_uthmani` field. Use for
  /// non-KFGQPC fonts and tajweed colour analysis.
  static String quranUthmaniStandard(int surahId) =>
      '$quranRoot/ar/$surahId.json';

  /// ClearQuran English translation per surah.
  static String quranClearQuran(int surahId) =>
      '$quranRoot/en.clearquran/$surahId.json';

  /// Chapter metadata JSON: `assets/quran/chapters.min.json`
  static String get quranChapters => '$quranRoot/chapters.min.json';

  /// Optional manifest for future use.
  static String get quranManifest => '$quranRoot/manifest.json';

  /// Unified KFGQPC Quran Mushaf Smart v8 dataset.
  ///
  /// Contains all 6236 ayat with `aya_text` (Uthmanic glyph),
  /// `aya_text_emlaey` (plain Arabic), surah metadata, juz/page
  /// info, and tajweed colour mappings.
  static const kfgqpcQuranMushafSmartV8 =
      'assets/quran/KFGQPCQuranMushaf_smart_v8.json';

  /// Static surah metadata (revelation type, order, juz ranges).
  static const surahMetadata = 'assets/quran/surah_metadata.json';

  /// English translated names for surah titles (e.g. "The Opener"), from Quran.com.
  static const surahTranslatedNames =
      'assets/quran/surah_translated_names.json';

  /// Arabic surah names with full tashkeel (vowelled), for display like Quran.com.
  static const surahArabicVowelled = 'assets/quran/surah_arabic_vowelled.json';

  /// Surah info summaries (short_text + full text) for all 114 surahs.
  static const surahInfo = 'assets/quran/surah_info.json';
}
