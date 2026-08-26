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

  /// Catalog number within the book, when the source provides it.
  final int? idInBook;

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
    this.idInBook,
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
    'idInBook': idInBook,
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
    idInBook: json['idInBook'] as int?,
    snippet: json['snippet'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// Parses [json] or returns null when the row is corrupt.
  static Bookmark? tryFromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'];
      if (type != 'quran' && type != 'hadith') return null;
      return Bookmark.fromJson(json);
    } catch (_) {
      return null;
    }
  }

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
    int? idInBook,
    String? snippet,
  }) => Bookmark(
    type: 'hadith',
    collectionId: collectionId,
    bookFile: bookFile,
    bookTitle: bookTitle,
    hadithIndex: hadithIndex,
    idInBook: idInBook,
    snippet: snippet,
    createdAt: DateTime.now(),
  );
}

// ────────────────────────────────────────────────────────────────
//  Per-surah reading pin
// ────────────────────────────────────────────────────────────────

/// One intentional resume marker in a surah. Distinct from a favorite
/// [Bookmark] and from automatic [BookmarkService.lastReadQuran].
@immutable
class QuranPin {
  const QuranPin({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.updatedAt,
  });

  final int surahId;
  final int ayah;
  final String surahName;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'ayah': ayah,
    'surahName': surahName,
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Parses [json] or returns null when the row is corrupt.
  static QuranPin? tryFromJson(Map<String, dynamic> json) {
    try {
      final surahId = json['surahId'];
      final ayah = json['ayah'];
      final name = json['surahName'];
      if (surahId is! int || ayah is! int || name is! String) {
        return null;
      }
      if (surahId < 1 || surahId > 114 || ayah < 1) return null;
      return QuranPin(
        surahId: surahId,
        ayah: ayah,
        surahName: name,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of [BookmarkService.toggleQuranPin].
enum QuranPinChange { pinned, moved, cleared }

/// Ayah to open in a surah. An explicit request (search, last-read
/// continue, a bookmark) wins; otherwise the per-surah pin.
int? quranOpenAyah({int? requestedAyah, int? pinnedAyah}) {
  if (requestedAyah != null && requestedAyah >= 1) return requestedAyah;
  if (pinnedAyah != null && pinnedAyah >= 1) return pinnedAyah;
  return null;
}

// ────────────────────────────────────────────────────────────────
//  Bookmark service
// ────────────────────────────────────────────────────────────────

/// Manages bookmarks, last-read positions, and per-surah Quran pins.
///
/// Persists all data as JSON strings in [SharedPreferences].
/// Call [load] once at startup to restore saved state.
class BookmarkService extends ChangeNotifier {
  /// SharedPreferences keys.
  static const _kBookmarks = 'bookmarks';
  static const _kLastReadQuran = 'last_read_quran';
  static const _kLastReadHadith = 'last_read_hadith';
  static const _kQuranPins = 'quran_pins';

  List<Bookmark> _bookmarks = [];
  final Set<String> _bookmarkIds = {};
  Map<String, dynamic>? _lastReadQuran;
  Map<String, dynamic>? _lastReadHadith;
  final Map<int, QuranPin> _pins = {};

  /// An unmodifiable view of the current bookmarks list.
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// Last-read Quran position: `{surahId, ayah, surahName, timestamp}`.
  Map<String, dynamic>? get lastReadQuran => _lastReadQuran;

  /// Last-read Hadith position:
  /// `{collectionId, bookFile, bookTitle, hadithIndex, timestamp}`.
  Map<String, dynamic>? get lastReadHadith => _lastReadHadith;

  /// Unmodifiable view of per-surah pins, keyed by surah id.
  Map<int, QuranPin> get quranPins => Map.unmodifiable(_pins);

  /// Pin for [surahId], if the user set one.
  QuranPin? pinFor(int surahId) => _pins[surahId];

  /// Whether [surahId]:[ayah] is this surah's pin.
  bool isAyahPinned(int surahId, int ayah) {
    final pin = _pins[surahId];
    return pin != null && pin.ayah == ayah;
  }

  /// Restores bookmarks, last-read, and per-surah pins from disk.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Decode bookmarks list; skip corrupt rows so a bad prefs write
    // cannot brick launch.
    final rawBookmarks = prefs.getString(_kBookmarks);
    if (rawBookmarks != null) {
      _bookmarks = _decodeBookmarks(rawBookmarks);
    } else {
      _bookmarks = [];
    }
    _rebuildIdSet();

    _lastReadQuran = _decodeLastReadMap(prefs.getString(_kLastReadQuran));
    _lastReadHadith = _decodeLastReadMap(prefs.getString(_kLastReadHadith));
    _pins
      ..clear()
      ..addAll(_decodeQuranPins(prefs.getString(_kQuranPins)));

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

  /// Re-inserts [bookmark] after an accidental delete.
  ///
  /// [index] is clamped to the current list so undo still works if
  /// other bookmarks changed while the snackbar was visible.
  Future<void> restoreBookmark(Bookmark bookmark, {int? index}) async {
    if (_bookmarkIds.contains(bookmark.id)) return;
    final insertAt = (index ?? 0).clamp(0, _bookmarks.length);
    _bookmarks.insert(insertAt, bookmark);
    _bookmarkIds.add(bookmark.id);
    await _persistBookmarks();
    notifyListeners();
  }

  /// Saves the user's last-read Quran position.
  ///
  /// Pass [notify] false while the reader is scrolling so the page does
  /// not rebuild on every persist. Call again with [notify] true on
  /// dispose so the Quran tab continue banner refreshes.
  Future<void> saveLastReadQuran({
    required int surahId,
    required int ayah,
    required String surahName,
    bool notify = true,
  }) async {
    final unchanged =
        _lastReadQuran != null &&
        _lastReadQuran!['surahId'] == surahId &&
        _lastReadQuran!['ayah'] == ayah;
    if (!unchanged) {
      _lastReadQuran = {
        'surahId': surahId,
        'ayah': ayah,
        'surahName': surahName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastReadQuran, json.encode(_lastReadQuran));
    }
    if (notify) notifyListeners();
  }

  /// Saves the user's last-read Hadith position.
  ///
  /// See [saveLastReadQuran] for [notify].
  Future<void> saveLastReadHadith({
    required String collectionId,
    required String bookFile,
    required String bookTitle,
    required int hadithIndex,
    bool notify = true,
  }) async {
    final unchanged =
        _lastReadHadith != null &&
        _lastReadHadith!['collectionId'] == collectionId &&
        _lastReadHadith!['bookFile'] == bookFile &&
        _lastReadHadith!['hadithIndex'] == hadithIndex;
    if (!unchanged) {
      _lastReadHadith = {
        'collectionId': collectionId,
        'bookFile': bookFile,
        'bookTitle': bookTitle,
        'hadithIndex': hadithIndex,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastReadHadith, json.encode(_lastReadHadith));
    }
    if (notify) notifyListeners();
  }

  /// Sets or moves the pin in [surahId]. One pin per surah.
  ///
  /// Tapping the already-pinned ayah clears it. Tapping another ayah
  /// in the same surah replaces the pin (quran.com reading-bookmark).
  Future<QuranPinChange> toggleQuranPin({
    required int surahId,
    required int ayah,
    required String surahName,
  }) async {
    final existing = _pins[surahId];
    if (existing != null && existing.ayah == ayah) {
      _pins.remove(surahId);
      await _persistPins();
      notifyListeners();
      return QuranPinChange.cleared;
    }
    final change = existing == null
        ? QuranPinChange.pinned
        : QuranPinChange.moved;
    _pins[surahId] = QuranPin(
      surahId: surahId,
      ayah: ayah,
      surahName: surahName,
      updatedAt: DateTime.now(),
    );
    await _persistPins();
    notifyListeners();
    return change;
  }

  /// Removes the pin for [surahId], if any.
  Future<void> clearQuranPin(int surahId) async {
    if (_pins.remove(surahId) == null) return;
    await _persistPins();
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

  Future<void> _persistPins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kQuranPins,
      json.encode(_pins.values.map((pin) => pin.toJson()).toList()),
    );
  }
}

List<Bookmark> _decodeBookmarks(String raw) {
  try {
    final decoded = json.decode(raw);
    if (decoded is! List) return [];
    final bookmarks = <Bookmark>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final bookmark = Bookmark.tryFromJson(Map<String, dynamic>.from(item));
      if (bookmark != null) bookmarks.add(bookmark);
    }
    return bookmarks;
  } catch (_) {
    return [];
  }
}

Map<String, dynamic>? _decodeLastReadMap(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = json.decode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
}

Map<int, QuranPin> _decodeQuranPins(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = json.decode(raw);
    if (decoded is! List) return {};
    final pins = <int, QuranPin>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final pin = QuranPin.tryFromJson(Map<String, dynamic>.from(item));
      if (pin != null) pins[pin.surahId] = pin;
    }
    return pins;
  } catch (_) {
    return {};
  }
}
