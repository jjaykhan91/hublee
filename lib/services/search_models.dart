/// Data models returned by the global search feature.
///
/// Each "hit" carries enough context to navigate directly to the
/// matched ayah or hadith and to show a preview snippet in search
/// results.
library;

/// A single Quran search result.
///
/// [surahId] and [ayah] identify the exact verse; [surahName]
/// provides the human-readable surah label for display.
class QuranSearchHit {
  final int surahId;
  final int ayah;
  final String surahName;

  /// Optional preview text from the matched ayah (usually English).
  final String? snippet;

  /// Optional Uthmani preview when the query matched Arabic.
  final String? arabicSnippet;

  const QuranSearchHit({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    this.snippet,
    this.arabicSnippet,
  });
}

/// A single Hadith search result.
///
/// [collectionId] and [bookFile] locate the book; [hadithIndex]
/// is the zero-based position within that book.
class HadithSearchHit {
  final String collectionId;
  final String bookFile;
  final String? bookTitle;

  /// Zero-based index of the hadith within its book.
  final int hadithIndex;

  /// Optional preview text from the matched hadith.
  final String? snippet;

  const HadithSearchHit({
    required this.collectionId,
    required this.bookFile,
    this.bookTitle,
    required this.hadithIndex,
    this.snippet,
  });
}
