/// Loads QPC V4 Tajweed script (glyph text + page per verse).
///
/// The script is from Tarteel QUL: V4 Glyphs (With Tajweed), word-by-word
/// (https://qul.tarteel.ai/resources/quran-script/47). When used with the
/// QPC V4 Tajweed font (page-by-page, https://qul.tarteel.ai/resources/font/240),
/// tajweed is rendered by the font — no software colour engine.
///
/// Supports two JSON formats:
/// - Verse-level: keys "1:1", "1:2", ... with { "text", "page_number" }.
/// - Word-level: keys "1:1:1", "1:1:2", ... with { "text", "word", ... }; verse
///   text is built by concatenating words; page comes from KFGQPC mushaf.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Decode JSON string to Map (for use in compute isolate).
Map<String, dynamic> _decodeScriptJson(String raw) =>
    json.decode(raw) as Map<String, dynamic>? ?? {};

/// Per-verse data from the V4 Tajweed script.
class V4VerseData {
  const V4VerseData({
    required this.text,
    required this.pageNumber,
  });

  final String text;
  final int pageNumber;
}

/// Provides V4 glyph text and mushaf page number per verse.
///
/// Returns empty data when the V4 script asset is not present (e.g. before
/// running the download tool).
class QuranV4TajweedRepository {
  QuranV4TajweedRepository();

  /// App-level cache so the 7MB+ script is parsed only once per session.
  static Map<String, dynamic>? _cachedScript;
  /// App-level cache for verse→page map (from KFGQPC mushaf).
  static Map<String, int>? _cachedMushafPageByVerse;

  /// Loads the full V4 script once per app session (static cache).
  /// Decodes JSON in an isolate to avoid blocking the UI thread.
  Future<Map<String, dynamic>?> _loadScript() async {
    if (_cachedScript != null) return _cachedScript;
    try {
      final raw = await rootBundle.loadString(AssetPaths.quranV4TajweedScript);
      final decoded = await compute(_decodeScriptJson, raw);
      if (decoded.isEmpty) return null;
      QuranV4TajweedRepository._cachedScript = decoded;
      return _cachedScript;
    } catch (_) {
      return null;
    }
  }

  /// True if script keys are word-level (e.g. "1:1:1") rather than verse-level ("1:1").
  bool _isWordLevelScript(Map<String, dynamic> script) {
    final firstKey = script.keys.isNotEmpty ? script.keys.first : '';
    final parts = firstKey.split(':');
    return parts.length >= 3;
  }

  /// Loads (surahId, ayahNumber) -> page from KFGQPC mushaf (static cache).
  Future<Map<String, int>> _loadMushafPageMap() async {
    if (QuranV4TajweedRepository._cachedMushafPageByVerse != null) {
      return QuranV4TajweedRepository._cachedMushafPageByVerse!;
    }
    final map = <String, int>{};
    try {
      final raw = await rootBundle.loadString(AssetPaths.kfgqpcQuranMushafSmartV8);
      final rows = json.decode(raw) as List<dynamic>?;
      if (rows == null) return map;
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final surah = row['sura_no'];
        final ayah = row['aya_no'];
        final page = row['page'] ?? row['page_number'];
        if (surah == null || ayah == null) continue;
        final pageNum = page is int
            ? page
            : (page is num ? page.toInt() : int.tryParse(page.toString()));
        if (pageNum != null && pageNum >= 1 && pageNum <= 604) {
          map['$surah:$ayah'] = pageNum;
        }
      }
      QuranV4TajweedRepository._cachedMushafPageByVerse = map;
    } catch (_) {}
    return map;
  }

  /// Returns V4 text and page for each ayah in [surahId].
  /// Keys are ayah numbers (1-based). Missing or invalid script returns {}.
  Future<Map<int, V4VerseData>> loadV4Surah(int surahId) async {
    final script = await _loadScript();
    if (script == null || script.isEmpty) return const {};

    if (_isWordLevelScript(script)) {
      return _loadV4SurahWordLevel(surahId, script);
    }
    return _loadV4SurahVerseLevel(surahId, script);
  }

  /// Verse-level format: keys "surah:ayah" with { "text", "page_number" }.
  Future<Map<int, V4VerseData>> _loadV4SurahVerseLevel(
    int surahId,
    Map<String, dynamic> script,
  ) async {
    final prefix = '$surahId:';
    final result = <int, V4VerseData>{};
    for (final key in script.keys) {
      if (!key.startsWith(prefix)) continue;
      final ayahStr = key.substring(prefix.length).split(':').first;
      final ayah = int.tryParse(ayahStr);
      if (ayah == null || ayah < 1) continue;
      final verse = script[key];
      if (verse is! Map<String, dynamic>) continue;
      final text = verse['text'] as String?;
      final page = verse['page_number'];
      if (text == null || text.isEmpty) continue;
      final pageNumber = page is int
          ? page
          : (page is num
              ? page.toInt()
              : (int.tryParse(page.toString()) ?? 1));
      result[ayah] = V4VerseData(text: text, pageNumber: pageNumber);
    }
    return result;
  }

  /// Word-level format: keys "surah:ayah:word", aggregate words into verse text; page from mushaf.
  Future<Map<int, V4VerseData>> _loadV4SurahWordLevel(
    int surahId,
    Map<String, dynamic> script,
  ) async {
    final pageMap = await _loadMushafPageMap();
    final prefix = '$surahId:';
    // Collect words per ayah: ayah -> list of (wordIndex, glyphText)
    final ayahWords = <int, List<MapEntry<int, String>>>{};
    for (final key in script.keys) {
      if (!key.startsWith(prefix)) continue;
      final parts = key.substring(prefix.length).split(':');
      if (parts.isEmpty) continue;
      final ayah = int.tryParse(parts[0]);
      if (ayah == null || ayah < 1) continue;
      final verse = script[key];
      if (verse is! Map<String, dynamic>) continue;
      final text = verse['text'] as String?;
      if (text == null) continue;
      final list = ayahWords.putIfAbsent(ayah, () => []);
      final wordStr = verse['word']?.toString();
      final wordIndex = int.tryParse(wordStr ?? '') ?? list.length;
      list.add(MapEntry(wordIndex, text));
    }
    final result = <int, V4VerseData>{};
    for (final entry in ayahWords.entries) {
      final ayah = entry.key;
      final words = entry.value..sort((a, b) => a.key.compareTo(b.key));
      final text = words.map((e) => e.value).join(' ');
      if (text.isEmpty) continue;
      final pageNumber = pageMap['$surahId:$ayah'] ?? 1;
      result[ayah] = V4VerseData(text: text, pageNumber: pageNumber);
    }
    return result;
  }
}
