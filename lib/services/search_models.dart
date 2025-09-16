// lib/search/search_models.dart

class QuranSearchHit {
  final int surahId;
  final int ayah;
  final String surahName;
  final String? snippet;

  const QuranSearchHit({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    this.snippet,
  });
}

class HadithSearchHit {
  final String collectionId;
  final String bookFile;
  final String? bookTitle;
  final int hadithIndex; // 0-based
  final String? snippet;

  const HadithSearchHit({
    required this.collectionId,
    required this.bookFile,
    this.bookTitle,
    required this.hadithIndex,
    this.snippet,
  });
}
