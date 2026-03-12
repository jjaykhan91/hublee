/// Loads word-by-word translation data for Quran verses.
///
/// Uses plain English WBW JSON with keys "s:a:w" (e.g. "2:2:6") and
/// string values for each word translation.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// One word in a verse with its translation.
/// [color] is set when using Colored English wbw translation (e.g. part-of-speech).
class WordByWordItem {
  const WordByWordItem({
    required this.position,
    required this.arabic,
    required this.translation,
  });

  final int position;
  final String arabic;
  final String translation;
}

/// Provides word-by-word translation per verse.
class WordByWordRepository {
  WordByWordRepository();

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>?> _load() async {
    if (_cache != null) return _cache;
    try {
      final raw =
          await rootBundle.loadString(AssetPaths.quranWordByWordTranslation);
      final decoded = json.decode(raw) as Map<String, dynamic>?;
      _cache = decoded;
      return _cache;
    } catch (_) {
      return null;
    }
  }

  /// Returns word-by-word for every ayah in the surah.
  /// Key = ayah number (1-based), value = list of words.
  Future<Map<int, List<WordByWordItem>>> loadSurah(int surahId) async {
    final data = await _load();
    if (data == null || data.isEmpty) return const {};

    final result = <int, List<WordByWordItem>>{};
    final basePrefix = '$surahId:';
    // Base English WBW: "s:a:w" -> plain English word/phrase.
    for (final entry in data.entries) {
      final key = entry.key;
      if (!key.startsWith(basePrefix)) continue;
      final rest = key.substring(basePrefix.length);
      final parts = rest.split(':');
      if (parts.length != 2) continue;
      final ayah = int.tryParse(parts[0]);
      final wordPos = int.tryParse(parts[1]);
      if (ayah == null || ayah < 1 || wordPos == null || wordPos < 1) {
        continue;
      }
      final text = entry.value?.toString().trim();
      if (text == null || text.isEmpty) continue;
      final bucket = result.putIfAbsent(ayah, () => <WordByWordItem>[]);
      bucket.add(WordByWordItem(
        position: wordPos,
        arabic: '',
        translation: text,
      ));
    }
    for (final list in result.values) {
      list.sort((a, b) => a.position.compareTo(b.position));
    }
    return result;
  }

  /// Convenience helper used by tests: just returns WBW list for one verse.
  Future<List<WordByWordItem>> loadVerse(int surahId, int ayahNumber) async {
    final map = await loadSurah(surahId);
    return map[ayahNumber] ?? const [];
  }
}
