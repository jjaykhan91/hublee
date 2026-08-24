/// Loads Arabic ayah text from the unified KFGQPC Mushaf Smart v8
/// dataset and the standard Uthmanic per-surah files.
///
/// Two text sources are available:
/// - **KFGQPC PUA glyphs** (`aya_text`) — for rendering with the
///   bundled KFGQPCQuranicFontHafsSmart font. Not parseable for
///   tajweed because it uses Private Use Area characters.
/// - **Standard Uthmanic** (`assets/quran/ar/{surahId}.json`) —
///   standard Arabic Unicode with full tashkeel. Works with any
///   Arabic font and supports tajweed colour analysis.
/// - **Imla'i** (`aya_text_emlaey`) — simplified spelling for
///   search indexing only.
///
/// The mushaf JSON is decoded at most once per session and shared
/// across glyph, emlaey, and search loads.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Provides Arabic text for a single surah, keyed by ayah number.
class QuranArabicRepository {
  const QuranArabicRepository();

  /// Shared in-flight / completed decode of the full mushaf rows.
  static Future<List<dynamic>>? _mushafRowsFuture;

  /// Per-surah caches: surahId → ayahNumber → text.
  static final Map<int, Map<String, String>> _glyphCache = {};
  static final Map<int, Map<String, String>> _emlaeyCache = {};
  static final Map<int, Map<String, String>> _uthmaniCache = {};

  /// Returns a map of `{ ayahNumber: arabicText }` for [surahId].
  ///
  /// When [useGlyphText] is `true` (the default) the KFGQPC PUA
  /// glyph column (`aya_text`) is used. Set it to `false` to get
  /// the Imla'i column (`aya_text_emlaey`) for search.
  Future<Map<String, String>> loadArabicSurah(
    int surahId, {
    bool useGlyphText = true,
  }) async {
    final cache = useGlyphText ? _glyphCache : _emlaeyCache;
    final cached = cache[surahId];
    if (cached != null) return cached;

    final rows = await _loadMushafRows();
    final column = useGlyphText ? 'aya_text' : 'aya_text_emlaey';
    final ayahMap = <String, String>{};

    for (final row in rows) {
      if (row['sura_no'] == surahId) {
        final ayahNumber = row['aya_no'];
        final text = (row[column] as String?)?.trim();
        if (text != null && text.isNotEmpty) {
          ayahMap['$ayahNumber'] = text;
        }
      }
    }

    cache[surahId] = ayahMap;
    return ayahMap;
  }

  /// Walks the mushaf once and returns Imla'i text for every surah.
  ///
  /// Search used to call [loadArabicSurah] 114 times, each of which
  /// scanned all 6,236 rows. One pass fills [_emlaeyCache] so later
  /// per-surah loads hit memory.
  Future<Map<int, Map<String, String>>> loadAllEmlaey() async {
    if (_emlaeyCache.length >= 114) {
      return _emlaeyCache;
    }
    final rows = await _loadMushafRows();
    for (final row in rows) {
      if (row is! Map) continue;
      final surahId = _asInt(row['sura_no']);
      final ayahNumber = _asInt(row['aya_no']);
      if (surahId == null || ayahNumber == null) continue;
      final text = (row['aya_text_emlaey'] as String?)?.trim();
      if (text == null || text.isEmpty) continue;
      (_emlaeyCache[surahId] ??= <String, String>{})['$ayahNumber'] = text;
    }
    return _emlaeyCache;
  }

  /// Loads standard Uthmanic Arabic text (full tashkeel, standard
  /// Unicode) from the per-surah JSON files in `assets/quran/ar/`.
  ///
  /// These files were downloaded from the quran.com API
  /// `text_uthmani` field and contain proper harakat for rendering
  /// with bundled fonts and tajweed colour analysis.
  Future<Map<String, String>> loadUthmaniStandard(int surahId) async {
    final cached = _uthmaniCache[surahId];
    if (cached != null) return cached;

    final rawJson = await rootBundle.loadString(
      AssetPaths.quranUthmaniStandard(surahId),
    );
    final decoded = json.decode(rawJson);

    final Map<String, String> ayahMap;
    if (decoded is Map<String, dynamic>) {
      ayahMap = decoded.map((key, value) => MapEntry(key, value.toString()));
    } else {
      ayahMap = const {};
    }

    _uthmaniCache[surahId] = ayahMap;
    return ayahMap;
  }

  /// Decodes the mushaf JSON once; concurrent callers share the same Future.
  static Future<List<dynamic>> _loadMushafRows() {
    return _mushafRowsFuture ??= () async {
      final rawJson = await rootBundle.loadString(
        AssetPaths.kfgqpcQuranMushafSmartV8,
      );
      return json.decode(rawJson) as List<dynamic>;
    }();
  }

  /// Clears the session caches. Tests only.
  ///
  /// Each widget test runs in its own fake-async zone, and a `Future` cached
  /// in one zone never delivers in the next — a page would sit on its loading
  /// spinner forever. Call this between tests that pump a page.
  @visibleForTesting
  static void resetCache() {
    _mushafRowsFuture = null;
    _glyphCache.clear();
    _emlaeyCache.clear();
    _uthmaniCache.clear();
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
