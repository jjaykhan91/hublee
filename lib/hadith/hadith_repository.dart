/// Loads hadith collections, book indexes, individual books,
/// and supports full-text search across all hadith data.
///
/// The hadith asset layout is:
/// ```
/// assets/hadith/
///   <collectionId>/        (e.g. "forties", "the_9_books")
///     index.json           — list of books in this collection
///     <book>.json          — individual book with chapters & hadiths
/// ```
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import '../services/app_metrics.dart';
import '../services/search_models.dart';

// ────────────────────────────────────────────────────────────────
//  Core repository
// ────────────────────────────────────────────────────────────────

/// Loads individual hadith book JSON files and parses them into
/// strongly-typed [HadithBook] objects.
class HadithRepository {
  const HadithRepository();

  static final Map<String, Future<HadithBook>> _bookCache = {};
  static Future<List<_HadithIndexRow>>? _searchIndexFuture;

  /// Clears session caches. Tests only — cached [Future]s from one
  /// fake-async zone never complete in the next.
  @visibleForTesting
  static void resetCache() {
    _bookCache.clear();
    _searchIndexFuture = null;
  }

  /// Loads and parses a single hadith book.
  ///
  /// [collectionId] identifies the collection directory (e.g. `"forties"`).
  /// [bookFile] is the filename within that directory (e.g. `"nawawi40.json"`).
  Future<HadithBook> loadBook(String collectionId, String bookFile) {
    final key = '$collectionId/$bookFile';
    return _bookCache.putIfAbsent(
      key,
      () => _loadBookUncached(collectionId, bookFile),
    );
  }

  Future<HadithBook> _loadBookUncached(
    String collectionId,
    String bookFile,
  ) async {
    final path = AssetPaths.hadith(collectionId, bookFile);
    final rawJson = await rootBundle.loadString(path);
    final root = json.decode(rawJson);

    if (root is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected top-level Map for hadith book JSON.',
      );
    }

    // Resolve the display title by checking multiple JSON shapes.
    final title = _resolveBookTitle(root, bookFile);

    final chapters =
        (root['chapters'] is List
                ? root['chapters'] as List
                : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map<HadithChapter>(HadithChapter.fromJson)
            .toList(growable: false);

    final hadiths =
        (root['hadiths'] is List ? root['hadiths'] as List : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map<Hadith>(Hadith.fromJson)
            .toList(growable: false);

    return HadithBook(title: title, chapters: chapters, hadiths: hadiths);
  }

  /// Attempts to extract a book title from the JSON root using
  /// several common key paths. Falls back to a title derived
  /// from the file name.
  String _resolveBookTitle(Map<String, dynamic> root, String bookFile) {
    // Try root.english.title
    final english = root['english'];
    if (english is Map<String, dynamic>) {
      final title = english['title'] as String?;
      if (title != null) return title;
    }

    // Try root.metadata.english.title
    final metadata = root['metadata'];
    if (metadata is Map<String, dynamic>) {
      final metaEnglish = metadata['english'];
      if (metaEnglish is Map<String, dynamic>) {
        final title = metaEnglish['title'] as String?;
        if (title != null) return title;
      }
    }

    return _titleFromFileName(bookFile);
  }

  /// Derives a human-readable title from a file name.
  ///
  /// Example: `"nawawi40.json"` → `"Nawawi40"`
  String _titleFromFileName(String file) {
    final baseName = file.split('/').last.split('.').first;
    return baseName
        .replaceAll('_', ' ')
        .replaceFirstMapped(
          RegExp(r'^\w'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }
}

// ────────────────────────────────────────────────────────────────
//  Collection & book metadata
// ────────────────────────────────────────────────────────────────

/// Lightweight descriptor for a hadith collection directory.
@immutable
class HadithCollectionMeta {
  /// Directory name under `assets/hadith/` (e.g. `"forties"`).
  final String id;

  /// Human-readable title (e.g. `"Forties"`).
  final String title;

  /// Number of books in this collection, if known.
  final int? count;

  const HadithCollectionMeta({
    required this.id,
    required this.title,
    this.count,
  });
}

/// Lightweight descriptor for a single hadith book within a
/// collection.
@immutable
class HadithBookMeta {
  /// JSON filename (e.g. `"nawawi40.json"`).
  final String file;

  /// Display title from `index.json`.
  final String title;

  /// Number of hadiths in this book, if provided by the index.
  final int? length;

  const HadithBookMeta({required this.file, required this.title, this.length});
}

// ────────────────────────────────────────────────────────────────
//  Collection/book listing extension
// ────────────────────────────────────────────────────────────────

/// Extends [HadithRepository] with methods to discover available
/// collections and their books.
extension HadithRepositoryListing on HadithRepository {
  /// Returns metadata for all known hadith collections.
  ///
  /// Currently hard-coded to three top-level directories. The
  /// book count is resolved lazily from each collection's
  /// `index.json`.
  Future<List<HadithCollectionMeta>> loadCollections() async {
    const knownCollections = <HadithCollectionMeta>[
      HadithCollectionMeta(id: 'forties', title: 'Forties'),
      HadithCollectionMeta(id: 'the_9_books', title: 'The Nine Books'),
      HadithCollectionMeta(id: 'other_books', title: 'Other Books'),
    ];

    final results = <HadithCollectionMeta>[];
    for (final collection in knownCollections) {
      try {
        final books = await loadBooksForCollection(collection.id);
        results.add(
          HadithCollectionMeta(
            id: collection.id,
            title: collection.title,
            count: books.length,
          ),
        );
      } catch (_) {
        // If the index is missing, keep the collection without a count.
        results.add(collection);
      }
    }
    return results;
  }

  /// Reads `assets/hadith/<collectionId>/index.json` and returns
  /// the list of books.
  ///
  /// Supports multiple JSON shapes:
  /// - **Array of maps**: `[{ "file": "...", "bookName": "..." }]`
  /// - **Map with nested array**: `{ "books": [...] }`
  /// - **Flat map**: `{ "file.json": "Title", ... }`
  Future<List<HadithBookMeta>> loadBooksForCollection(
    String collectionId,
  ) async {
    final path = 'assets/hadith/$collectionId/index.json';
    final rawJson = await rootBundle.loadString(path);
    final decoded = json.decode(rawJson);

    List<dynamic> bookList;

    if (decoded is List) {
      bookList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Try a nested array first.
      final nested = decoded['books'] ?? decoded['items'];
      if (nested is List) {
        bookList = nested;
      } else {
        // Flat map: { "filename.json": "Display title", ... }
        return decoded.entries
            .where((entry) => entry.value is String)
            .map(
              (entry) => HadithBookMeta(
                file: entry.key.toString(),
                title: entry.value as String,
              ),
            )
            .toList(growable: false);
      }
    } else {
      throw const FormatException('Unsupported index.json shape');
    }

    return bookList
        .whereType<Map<String, dynamic>>()
        .map<HadithBookMeta>((map) {
          final file = (map['file'] ?? map['path'] ?? map['name']).toString();
          final title =
              (map['bookName'] ??
                      map['title'] ??
                      map['english'] ??
                      map['label'] ??
                      map['name'] ??
                      file)
                  .toString();
          final length = _toInt(map['length']);
          return HadithBookMeta(file: file, title: title, length: length);
        })
        .toList(growable: false);
  }
}

// ────────────────────────────────────────────────────────────────
//  Full-text search extension
// ────────────────────────────────────────────────────────────────

/// Extends [HadithRepository] with full-text search across all collections.
extension HadithSearchExtension on HadithRepository {
  /// Builds the session index if needed. Safe to call from splash warmup.
  Future<void> warmSearchIndex() async {
    await _ensureSearchIndex();
  }

  /// Searches all hadith text (English and Arabic) for [query].
  ///
  /// Returns up to [limit] matching [HadithSearchHit] results.
  /// The search is case-insensitive for English text and exact
  /// for Arabic text. The first call builds a session index.
  Future<List<HadithSearchHit>> searchHadith(
    String query, {
    int limit = 100,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final queryLower = trimmed.toLowerCase();

    final index = await _ensureSearchIndex();
    final hits = <HadithSearchHit>[];

    for (final row in index) {
      final isMatch =
          row.englishLower.contains(queryLower) || row.arabic.contains(trimmed);
      if (!isMatch) continue;

      hits.add(
        HadithSearchHit(
          collectionId: row.collectionId,
          bookFile: row.bookFile,
          bookTitle: row.bookTitle,
          hadithIndex: row.hadithIndex,
          snippet: _hadithSnippet(row.english, row.englishLower, queryLower),
        ),
      );
      if (hits.length >= limit) return hits;
    }
    return hits;
  }

  Future<List<_HadithIndexRow>> _ensureSearchIndex() {
    return HadithRepository._searchIndexFuture ??= _buildSearchIndex();
  }

  Future<List<_HadithIndexRow>> _buildSearchIndex() {
    return AppMetrics.instance.time('search.hadithIndex', () async {
      final collections = await loadCollections();
      const bookBatch = 6;
      final specs = <({String collectionId, HadithBookMeta meta})>[];

      for (final collection in collections) {
        late final List<HadithBookMeta> books;
        try {
          books = await loadBooksForCollection(collection.id);
        } catch (_) {
          continue;
        }
        for (final bookMeta in books) {
          specs.add((collectionId: collection.id, meta: bookMeta));
        }
      }

      final rows = <_HadithIndexRow>[];
      for (var i = 0; i < specs.length; i += bookBatch) {
        final end = i + bookBatch < specs.length ? i + bookBatch : specs.length;
        final loaded = await Future.wait(
          specs.sublist(i, end).map((spec) async {
            try {
              final book = await loadBook(spec.collectionId, spec.meta.file);
              return (spec.collectionId, spec.meta, book);
            } catch (_) {
              return null;
            }
          }),
        );
        for (final item in loaded) {
          if (item == null) continue;
          final (collectionId, bookMeta, book) = item;
          final bookTitle = book.title.isNotEmpty ? book.title : bookMeta.title;
          for (var index = 0; index < book.hadiths.length; index++) {
            final hadith = book.hadiths[index];
            final english = hadith.english ?? '';
            rows.add(
              _HadithIndexRow(
                collectionId: collectionId,
                bookFile: bookMeta.file,
                bookTitle: bookTitle,
                hadithIndex: index,
                arabic: hadith.arabic ?? '',
                english: english,
                englishLower: english.toLowerCase(),
              ),
            );
          }
        }
        await Future<void>.delayed(Duration.zero);
      }
      return rows;
    });
  }
}

String? _hadithSnippet(String english, String englishLower, String queryLower) {
  if (english.isEmpty) return null;
  final matchIndex = englishLower.indexOf(queryLower);
  if (matchIndex < 0) return english;
  final start = (matchIndex - 40).clamp(0, english.length);
  final end = (matchIndex + queryLower.length + 60).clamp(0, english.length);
  var snippet = english.substring(start, end).trim();
  if (start > 0) snippet = '…$snippet';
  if (end < english.length) snippet = '$snippet…';
  return snippet;
}

/// One searchable hadith in the session index.
class _HadithIndexRow {
  const _HadithIndexRow({
    required this.collectionId,
    required this.bookFile,
    required this.bookTitle,
    required this.hadithIndex,
    required this.arabic,
    required this.english,
    required this.englishLower,
  });

  final String collectionId;
  final String bookFile;
  final String bookTitle;
  final int hadithIndex;
  final String arabic;
  final String english;
  final String englishLower;
}

// ────────────────────────────────────────────────────────────────
//  Data models
// ────────────────────────────────────────────────────────────────

/// A fully loaded hadith book, containing its title, chapter
/// headings, and individual hadith entries.
@immutable
class HadithBook {
  final String title;
  final List<HadithChapter> chapters;
  final List<Hadith> hadiths;

  const HadithBook({
    required this.title,
    required this.chapters,
    required this.hadiths,
  });
}

/// A chapter heading within a hadith book.
@immutable
class HadithChapter {
  final int? bookId;
  final int? id;
  final String? arabic;
  final String? english;

  const HadithChapter({this.bookId, this.id, this.arabic, this.english});

  /// Parses a chapter from its JSON representation.
  factory HadithChapter.fromJson(Map<String, dynamic> json) => HadithChapter(
    bookId: _toInt(json['bookId']),
    id: _toInt(json['id']),
    arabic: json['arabic'] as String?,
    english: json['english'] as String?,
  );
}

/// A single hadith entry with Arabic text, English translation,
/// and optional narrator information.
@immutable
class Hadith {
  final int? id;

  /// The hadith number within its book.
  final int? idInBook;
  final int? chapterId;
  final int? bookId;

  /// Arabic text of the hadith (no tajweed markup).
  final String? arabic;

  /// English translation text.
  final String? english;

  /// Narrator chain (isnad), if provided separately.
  final String? narrator;

  const Hadith({
    this.id,
    this.idInBook,
    this.chapterId,
    this.bookId,
    this.arabic,
    this.english,
    this.narrator,
  });

  /// Parses a hadith from JSON.
  ///
  /// Handles two shapes for the "english" field:
  /// - A plain string: `"english": "..."`
  /// - A nested object: `"english": { "text": "...", "narrator": "..." }`
  factory Hadith.fromJson(Map<String, dynamic> json) {
    final englishField = json['english'];
    String? english;
    String? narrator;

    if (englishField is String) {
      english = englishField;
    } else if (englishField is Map<String, dynamic>) {
      english = englishField['text'] as String?;
      narrator = (englishField['narrator'] ?? json['narrator']) as String?;
    }

    return Hadith(
      id: _toInt(json['id']),
      idInBook: _toInt(json['idInBook']),
      chapterId: _toInt(json['chapterId']),
      bookId: _toInt(json['bookId']),
      arabic: json['arabic'] as String?,
      english: english,
      narrator: narrator,
    );
  }
}

/// Safely converts a dynamic value to [int], handling `null`,
/// `int`, and `String` inputs.
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}
