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

  /// Loads all 114 chapters sorted by surah number.
  ///
  /// Merges per-ayah name/verse data with static metadata for
  /// revelation type, revelation order, and juz ranges.
  Future<List<ChapterMeta>> loadChapters() async {
    // Load both sources in parallel.
    final results = await Future.wait([
      rootBundle.loadString(AssetPaths.kfgqpcQuranMushafSmartV8),
      rootBundle.loadString(AssetPaths.surahMetadata),
    ]);

    final List<dynamic> rows = json.decode(results[0]);
    final List<dynamic> metaRows = json.decode(results[1]);

    // Index static metadata by surah id.
    final metaById = <int, Map<String, dynamic>>{};
    for (final row in metaRows) {
      final map = row as Map<String, dynamic>;
      metaById[map['id'] as int] = map;
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

    // Merge both sources into ChapterMeta objects.
    final chapters = accumulator.entries.map((entry) {
      final meta = metaById[entry.key];
      return ChapterMeta(
        id: entry.key,
        nameSimple: entry.value.nameEn,
        nameArabic: entry.value.nameAr,
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
