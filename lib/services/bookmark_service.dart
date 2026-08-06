/// Defines the [Bookmark] data model and [BookmarkService] which
/// manages saving, loading, and toggling bookmarks for Quran ayahs
/// and Hadith entries.  Also tracks last-read positions.
///
/// All data is persisted in [SharedPreferences] as JSON strings.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ────────────────────────────────────────────────────────────────
//  Bookmark model
// ────────────────────────────────────────────────────────────────

/// Represents a saved bookmark for either a Quran ayah or a Hadith.
///
/// Each bookmark carries enough context (surah name, collection ID,
/// etc.) to navigate back and display a meaningful preview.
@immutable
class Bookmark {
  /// Either `'quran'` or `'hadith'`.
  final String type;

  // ── Quran-specific fields ─────────────────────────────────────
  final int? surahId;
  final int? ayah;
  final String? surahName;

  // ── Hadith-specific fields ────────────────────────────────────
  final String? collectionId;
  final String? bookFile;
  final String? bookTitle;

  /// Zero-based index of the hadith within its book.
  final int? hadithIndex;

  /// Short Arabic or English preview text for display in lists.
  final String? snippet;

  /// When this bookmark was created.
  final DateTime createdAt;

  const Bookmark({
    required this.type,
    this.surahId,
    this.ayah,
    this.surahName,
    this.collectionId,
    this.bookFile,
    this.bookTitle,
    this.hadithIndex,
    this.snippet,
    required this.createdAt,
  });

  /// Unique identifier used for equality checks and storage keys.
  ///
  /// Format: `quran:<surahId>:<ayah>` or
  ///         `hadith:<collectionId>:<bookFile>:<hadithIndex>`
  String get id {
    if (type == 'quran') return 'quran:$surahId:$ayah';
    return 'hadith:$collectionId:$bookFile:$hadithIndex';
  }

  /// Serializes this bookmark to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'type': type,
    'surahId': surahId,
    'ayah': ayah,
    'surahName': surahName,
    'collectionId': collectionId,
    'bookFile': bookFile,
    'bookTitle': bookTitle,
    'hadithIndex': hadithIndex,
    'snippet': snippet,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Deserializes a bookmark from a JSON map.
  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    type: json['type'] as String,
    surahId: json['surahId'] as int?,
    ayah: json['ayah'] as int?,
    surahName: json['surahName'] as String?,
    collectionId: json['collectionId'] as String?,
    bookFile: json['bookFile'] as String?,
    bookTitle: json['bookTitle'] as String?,
    hadithIndex: json['hadithIndex'] as int?,
    snippet: json['snippet'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// Creates a Quran ayah bookmark.
  factory Bookmark.quran({
    required int surahId,
    required int ayah,
    required String surahName,
    String? snippet,
  }) => Bookmark(
    type: 'quran',
    surahId: surahId,
    ayah: ayah,
    surahName: surahName,
    snippet: snippet,
    createdAt: DateTime.now(),
  );

  /// Creates a Hadith bookmark.
  factory Bookmark.hadith({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
    required int hadithIndex,
    String? snippet,
  }) => Bookmark(
    type: 'hadith',
    collectionId: collectionId,
    bookFile: bookFile,
    bookTitle: bookTitle,
    hadithIndex: hadithIndex,
    snippet: snippet,
    createdAt: DateTime.now(),
  );
}

// ────────────────────────────────────────────────────────────────
//  Bookmark service
// ────────────────────────────────────────────────────────────────

/// Manages the user's bookmarks and last-read positions.
///
/// Persists all data as JSON strings in [SharedPreferences].
/// Call [load] once at startup to restore saved state.
class BookmarkService extends ChangeNotifier {
  /// SharedPreferences keys.
  static const _kBookmarks = 'bookmarks';
  static const _kLastReadQuran = 'last_read_quran';
  static const _kLastReadHadith = 'last_read_hadith';

  List<Bookmark> _bookmarks = [];
  final Set<String> _bookmarkIds = {};
  Map<String, dynamic>? _lastReadQuran;
  Map<String, dynamic>? _lastReadHadith;

  /// An unmodifiable view of the current bookmarks list.
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// Last-read Quran position: `{surahId, ayah, surahName, timestamp}`.
  Map<String, dynamic>? get lastReadQuran => _lastReadQuran;

  /// Last-read Hadith position:
  /// `{collectionId, bookFile, bookTitle, hadithIndex, timestamp}`.
  Map<String, dynamic>? get lastReadHadith => _lastReadHadith;

  /// Restores bookmarks and last-read positions from disk.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Decode bookmarks list
    final rawBookmarks = prefs.getString(_kBookmarks);
    if (rawBookmarks != null) {
      final List<dynamic> decoded = json.decode(rawBookmarks);
      _bookmarks = decoded
          .whereType<Map<String, dynamic>>()
          .map(Bookmark.fromJson)
          .toList();
    } else {
      _bookmarks = [];
    }
    _rebuildIdSet();

    // Decode last-read positions
    final rawQuran = prefs.getString(_kLastReadQuran);
    if (rawQuran != null) _lastReadQuran = json.decode(rawQuran);

    final rawHadith = prefs.getString(_kLastReadHadith);
    if (rawHadith != null) _lastReadHadith = json.decode(rawHadith);

    notifyListeners();
  }

  /// Returns `true` if a bookmark with the given [id] exists.
  bool isBookmarked(String id) => _bookmarkIds.contains(id);

  /// Adds or removes [bookmark] (toggle behaviour).
  ///
  /// If a bookmark with the same [Bookmark.id] already exists it is
  /// removed; otherwise the new bookmark is inserted at the top.
  Future<void> toggleBookmark(Bookmark bookmark) async {
    final existingIndex = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      _bookmarkIds.remove(bookmark.id);
    } else {
      _bookmarks.insert(0, bookmark);
      _bookmarkIds.add(bookmark.id);
    }
    await _persistBookmarks();
    notifyListeners();
  }

  /// Removes the bookmark matching [id], if any.
  Future<void> removeBookmark(String id) async {
    _bookmarks.removeWhere((bookmark) => bookmark.id == id);
    _bookmarkIds.remove(id);
    await _persistBookmarks();
    notifyListeners();
  }

  /// Saves the user's last-read Quran position.
  Future<void> saveLastReadQuran({
    required int surahId,
    required int ayah,
    required String surahName,
  }) async {
    _lastReadQuran = {
      'surahId': surahId,
      'ayah': ayah,
      'surahName': surahName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastReadQuran, json.encode(_lastReadQuran));
    notifyListeners();
  }

  /// Saves the user's last-read Hadith position.
  Future<void> saveLastReadHadith({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
    required int hadithIndex,
  }) async {
    _lastReadHadith = {
      'collectionId': collectionId,
      'bookFile': bookFile,
      'bookTitle': bookTitle,
      'hadithIndex': hadithIndex,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastReadHadith, json.encode(_lastReadHadith));
    notifyListeners();
  }

  /// Writes the current bookmarks list to SharedPreferences.
  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBookmarks,
      json.encode(_bookmarks.map((bookmark) => bookmark.toJson()).toList()),
    );
  }

  void _rebuildIdSet() {
    _bookmarkIds
      ..clear()
      ..addAll(_bookmarks.map((b) => b.id));
  }
}
