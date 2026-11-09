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

/// Ayah to open in a surah. An explicit request (search, continue, a
/// bookmark) wins; otherwise where the reader last stopped in it.
int? quranOpenAyah({int? requestedAyah, int? savedAyah}) {
  if (requestedAyah != null && requestedAyah >= 1) return requestedAyah;
  if (savedAyah != null && savedAyah >= 1) return savedAyah;
  return null;
}

// ────────────────────────────────────────────────────────────────
//  Bookmark service
// ────────────────────────────────────────────────────────────────

/// Manages bookmarks, last-read positions, and where the reader stopped
/// in each surah.
///
/// Persists all data as JSON strings in [SharedPreferences].
/// Call [load] once at startup to restore saved state.
class BookmarkService extends ChangeNotifier {
  /// SharedPreferences keys.
  static const _kBookmarks = 'bookmarks';
  static const _kLastReadQuran = 'last_read_quran';
  static const _kLastReadHadith = 'last_read_hadith';
  static const _kQuranPositions = 'quran_positions';

  /// Per-surah pins from 1.0.6 and earlier. Read once to migrate them.
  static const _kLegacyQuranPins = 'quran_pins';

  List<Bookmark> _bookmarks = [];
  final Set<String> _bookmarkIds = {};
  Map<String, dynamic>? _lastReadQuran;
  Map<String, dynamic>? _lastReadHadith;
  final Map<int, int> _positions = {};

  /// An unmodifiable view of the current bookmarks list.
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// Last-read Quran position: `{surahId, ayah, surahName, timestamp}`.
  Map<String, dynamic>? get lastReadQuran => _lastReadQuran;

  /// Last-read Hadith position:
  /// `{collectionId, bookFile, bookTitle, hadithIndex, timestamp}`.
  Map<String, dynamic>? get lastReadHadith => _lastReadHadith;

  /// Ayah the reader last stopped at in [surahId], if it has been opened.
  int? positionFor(int surahId) => _positions[surahId];

  /// Quran bookmarks in [surahId], in ayah order.
  List<Bookmark> quranBookmarksIn(int surahId) =>
      _bookmarks
          .where((b) => b.type == 'quran' && b.surahId == surahId)
          .toList()
        ..sort((a, b) => (a.ayah ?? 0).compareTo(b.ayah ?? 0));

  /// Restores bookmarks, last-read, and per-surah positions from disk.
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
    _positions
      ..clear()
      ..addAll(_decodeQuranPositions(prefs.getString(_kQuranPositions)));
    await _migrateLegacyPins(prefs);

    notifyListeners();
  }

  /// Turns each old per-surah pin into a bookmark, and into that surah's
  /// position when it has none, then drops the pins.
  Future<void> _migrateLegacyPins(SharedPreferences prefs) async {
    final raw = prefs.getString(_kLegacyQuranPins);
    if (raw == null) return;
    for (final pin in _decodeLegacyPins(raw)) {
      _positions.putIfAbsent(pin.surahId, () => pin.ayah);
      final bookmark = Bookmark(
        type: 'quran',
        surahId: pin.surahId,
        ayah: pin.ayah,
        surahName: pin.surahName,
        createdAt: pin.updatedAt,
      );
      if (_bookmarkIds.add(bookmark.id)) _bookmarks.insert(0, bookmark);
    }
    await _persistBookmarks();
    await _persistPositions();
    await prefs.remove(_kLegacyQuranPins);
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
        _lastReadQuran!['ayah'] == ayah &&
        _positions[surahId] == ayah;
    if (!unchanged) {
      _lastReadQuran = {
        'surahId': surahId,
        'ayah': ayah,
        'surahName': surahName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _positions[surahId] = ayah;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastReadQuran, json.encode(_lastReadQuran));
      await _persistPositions();
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

  /// Tells listeners that a last-read position saved with `notify: false`
  /// has changed, such as the Quran tab's continue banner.
  void notifyLastReadChanged() => notifyListeners();

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

  Future<void> _persistPositions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kQuranPositions,
      json.encode({
        for (final entry in _positions.entries) '${entry.key}': entry.value,
      }),
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

/// Reads `{"surahId": ayah}`, skipping rows outside the Quran.
Map<int, int> _decodeQuranPositions(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = json.decode(raw);
    if (decoded is! Map) return {};
    final positions = <int, int>{};
    for (final entry in decoded.entries) {
      final surahId = int.tryParse('${entry.key}');
      final ayah = entry.value;
      if (surahId == null || surahId < 1 || surahId > 114) continue;
      if (ayah is! int || ayah < 1) continue;
      positions[surahId] = ayah;
    }
    return positions;
  } catch (_) {
    return {};
  }
}

typedef _LegacyPin = ({
  int surahId,
  int ayah,
  String surahName,
  DateTime updatedAt,
});

/// Reads the 1.0.6 pin list, skipping corrupt rows.
List<_LegacyPin> _decodeLegacyPins(String raw) {
  try {
    final decoded = json.decode(raw);
    if (decoded is! List) return [];
    final pins = <_LegacyPin>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final surahId = item['surahId'];
      final ayah = item['ayah'];
      final name = item['surahName'];
      if (surahId is! int || ayah is! int || name is! String) continue;
      if (surahId < 1 || surahId > 114 || ayah < 1) continue;
      final updatedAt =
          DateTime.tryParse('${item['updatedAt']}') ?? DateTime.now();
      pins.add((
        surahId: surahId,
        ayah: ayah,
        surahName: name,
        updatedAt: updatedAt,
      ));
    }
    return pins;
  } catch (_) {
    return [];
  }
}
