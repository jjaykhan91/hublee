/// Loads surah metadata (names, verse counts, juz, revelation info)
/// from the KFGQPC Mushaf dataset merged with static metadata.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'models.dart';

/// Builds a list of all 114 [ChapterMeta] objects by scanning the
/// full ayah dataset and merging with the static surah metadata
/// file for revelation type, revelation order, and juz ranges.
class QuranChaptersRepository {
  const QuranChaptersRepository();

  static Future<List<ChapterMeta>>? _chaptersCache;

  /// Loads all 114 chapters sorted by surah number.
  /// Result is cached for the app session so Quran tab and reader reuse it.
  ///
  /// Merges per-ayah name/verse data with static metadata for
  /// revelation type, revelation order, and juz ranges.
  Future<List<ChapterMeta>> loadChapters() async {
    _chaptersCache ??= _loadChaptersImpl();
    return _chaptersCache!;
  }

  static Future<List<ChapterMeta>> _loadChaptersImpl() async {
    // Load all sources in parallel.
    final results = await Future.wait([
      rootBundle.loadString(AssetPaths.kfgqpcQuranMushafSmartV8),
      rootBundle.loadString(AssetPaths.surahMetadata),
      rootBundle.loadString(AssetPaths.surahTranslatedNames),
      rootBundle.loadString(AssetPaths.surahArabicVowelled),
    ]);

    final List<dynamic> rows = json.decode(results[0]);
    final List<dynamic> metaRows = json.decode(results[1]);
    final List<dynamic> translatedRows = json.decode(results[2]);
    final List<dynamic> vowelledRows = json.decode(results[3]);

    // Index static metadata by surah id.
    final metaById = <int, Map<String, dynamic>>{};
    for (final row in metaRows) {
      final map = row as Map<String, dynamic>;
      metaById[map['id'] as int] = map;
    }

    // Index translated names (English meaning) by surah id.
    final translatedByNameById = <int, String>{};
    for (final row in translatedRows) {
      final map = row as Map<String, dynamic>;
      translatedByNameById[map['id'] as int] = map['name'] as String;
    }

    // Index Arabic names with tashkeel (vowelled) by surah id.
    final vowelledByNameById = <int, String>{};
    for (final row in vowelledRows) {
      final map = row as Map<String, dynamic>;
      vowelledByNameById[map['id'] as int] = map['name'] as String;
    }

    // Accumulate verse counts and names per surah from ayah data.
    final Map<int, _SurahAccumulator> accumulator = {};
    for (final row in rows) {
      final int surahNumber = row['sura_no'] as int;
      final String nameEn = (row['sura_name_en'] as String).trim();
      final String nameAr = (row['sura_name_ar'] as String).trim();

      final bucket = accumulator.putIfAbsent(
        surahNumber,
        () => _SurahAccumulator(nameEn, nameAr),
      );
      bucket.verseCount++;
    }

    // Merge all sources into ChapterMeta objects.
    final chapters = accumulator.entries.map((entry) {
      final meta = metaById[entry.key];
      return ChapterMeta(
        id: entry.key,
        nameSimple: entry.value.nameEn,
        nameTranslated: translatedByNameById[entry.key],
        nameArabic: entry.value.nameAr,
        nameArabicVowelled: vowelledByNameById[entry.key],
        versesCount: entry.value.verseCount,
        revelationType: (meta?['revelationType'] as String?) ?? 'Meccan',
        revelationOrder: (meta?['revelationOrder'] as int?) ?? 0,
        startJuz: (meta?['startJuz'] as int?) ?? 1,
        endJuz: (meta?['endJuz'] as int?) ?? 1,
      );
    }).toList();

    chapters.sort((a, b) => a.id.compareTo(b.id));
    return chapters;
  }
}

/// Temporary helper to tally verses while iterating the JSON rows.
class _SurahAccumulator {
  final String nameEn;
  final String nameAr;
  int verseCount = 0;

  _SurahAccumulator(this.nameEn, this.nameAr);
}
