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

/// Ranked Quran hits plus metadata for the search UI.
class QuranSearchResult {
  const QuranSearchResult({
    this.hits = const [],
    this.totalCount = 0,
    this.invalidJumpHint,
  });

  final List<QuranSearchHit> hits;

  /// Matches before the result cap, used for "150 of 400" chips.
  final int totalCount;

  /// Set when the query looks like `2:999` but that ayah does not exist.
  final String? invalidJumpHint;
}

/// A single Hadith search result.
///
/// [collectionId] and [bookFile] locate the book; [hadithIndex]
/// is the zero-based position within that book (used to scroll).
class HadithSearchHit {
  final String collectionId;
  final String bookFile;
  final String? bookTitle;

  /// Zero-based index of the hadith within its book.
  final int hadithIndex;

  /// Catalog number within the book, when the source JSON provides it.
  final int? idInBook;

  /// Optional preview text from the matched hadith.
  final String? snippet;

  const HadithSearchHit({
    required this.collectionId,
    required this.bookFile,
    this.bookTitle,
    required this.hadithIndex,
    this.idInBook,
    this.snippet,
  });

  /// Number shown in search tiles: catalog `#n` when known.
  String get numberLabel =>
      idInBook != null ? '#$idInBook' : 'Hadith ${hadithIndex + 1}';
}

/// Ranked hadith hits plus the uncapped match count.
class HadithSearchResult {
  const HadithSearchResult({this.hits = const [], this.totalCount = 0});

  final List<HadithSearchHit> hits;
  final int totalCount;
}
