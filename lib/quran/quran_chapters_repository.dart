/// Loads surah metadata (names, verse counts, juz, revelation info)
/// from the compact chapters index merged with static metadata.
///
/// Does **not** decode the 4.3 MB mushaf — verse counts and base names
/// come from [AssetPaths.quranChapters] (`chapters.min.json`).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'models.dart';

/// Builds a list of all 114 [ChapterMeta] objects.
///
/// Results are cached for the session so the Quran tab and surah
/// reader share one decode.
class QuranChaptersRepository {
  const QuranChaptersRepository();

  static Future<List<ChapterMeta>>? _cacheFuture;

  /// Loads all 114 chapters sorted by surah number.
  ///
  /// Merges `chapters.min.json` with static metadata for revelation
  /// type, revelation order, juz ranges, translated names, and
  /// vowelled Arabic names.
  Future<List<ChapterMeta>> loadChapters() {
    return _cacheFuture ??= _loadChaptersUncached();
  }

  static Future<List<ChapterMeta>> _loadChaptersUncached() async {
    final results = await Future.wait([
      rootBundle.loadString(AssetPaths.quranChapters),
      rootBundle.loadString(AssetPaths.surahMetadata),
      rootBundle.loadString(AssetPaths.surahTranslatedNames),
      rootBundle.loadString(AssetPaths.surahArabicVowelled),
    ]);

    final List<dynamic> chapterRows = json.decode(results[0]);
    final List<dynamic> metaRows = json.decode(results[1]);
    final List<dynamic> translatedRows = json.decode(results[2]);
    final List<dynamic> vowelledRows = json.decode(results[3]);

    final metaById = <int, Map<String, dynamic>>{};
    for (final row in metaRows) {
      final map = row as Map<String, dynamic>;
      metaById[map['id'] as int] = map;
    }

    final translatedByNameById = <int, String>{};
    for (final row in translatedRows) {
      final map = row as Map<String, dynamic>;
      translatedByNameById[map['id'] as int] = map['name'] as String;
    }

    final vowelledByNameById = <int, String>{};
    for (final row in vowelledRows) {
      final map = row as Map<String, dynamic>;
      vowelledByNameById[map['id'] as int] = map['name'] as String;
    }

    final chapters = chapterRows.map((row) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as int;
      final meta = metaById[id];
      final place = (map['revelation_place'] as String?)?.toLowerCase();
      final fromPlace = place == 'madinah'
          ? 'Medinan'
          : place == 'makkah'
          ? 'Meccan'
          : null;

      return ChapterMeta(
        id: id,
        nameSimple: (map['name_simple'] as String).trim(),
        nameTranslated: translatedByNameById[id],
        nameArabic: (map['name_arabic'] as String).trim(),
        nameArabicVowelled: vowelledByNameById[id],
        versesCount: map['verses_count'] as int,
        revelationType:
            (meta?['revelationType'] as String?) ?? fromPlace ?? 'Meccan',
        revelationOrder: (meta?['revelationOrder'] as int?) ?? 0,
        startJuz: (meta?['startJuz'] as int?) ?? 1,
        endJuz: (meta?['endJuz'] as int?) ?? 1,
      );
    }).toList();

    chapters.sort((a, b) => a.id.compareTo(b.id));
    return chapters;
  }
}
