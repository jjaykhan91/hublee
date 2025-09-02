class AssetPaths {
  // ===== Hadith =====
  static const hadithRoot = 'assets/hadith';
  static String hadith(String collectionId, String fileName) =>
      '$hadithRoot/$collectionId/$fileName';

  // ===== Qur'an =====
  static const quranRoot = 'assets/quran';

  // Arabic: assets/quran/ar/<surahId>.json
  static String quranArabic(int surahId) => '$quranRoot/ar/$surahId.json';

  // ClearQuran English: assets/quran/en.clearquran/<surahId>.json
  static String quranClearQuran(int surahId) =>
      '$quranRoot/en.clearquran/$surahId.json';

  // Chapters list: assets/quran/translations/chapters.min.json
  static String get quranChapters =>
      '$quranRoot/chapters.min.json';

  // Optional: manifest if you add one later
  static String get quranManifest => '$quranRoot/manifest.json';
}
