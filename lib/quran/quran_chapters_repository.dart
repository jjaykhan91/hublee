/// Loads surah metadata (names and verse counts) from the unified
/// KFGQPC Mushaf Smart v8 dataset.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'models.dart';

/// Builds a list of all 114 [ChapterMeta] objects by scanning the
/// full ayah dataset and grouping by `sura_no`.
class QuranChaptersRepository {
  const QuranChaptersRepository();

  /// Loads all 114 chapters sorted by surah number.
  ///
  /// Iterates over every ayah row to extract the surah number,
  /// English name, Arabic name, and counts the verses per surah.
  Future<List<ChapterMeta>> loadChapters() async {
    final rawJson = await rootBundle.loadString(
      AssetPaths.kfgqpcQuranMushafSmartV8,
    );
    final List<dynamic> rows = json.decode(rawJson);

    // Accumulate verse counts per surah.
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

    // Convert the map into a sorted list of ChapterMeta.
    final chapters = accumulator.entries.map((entry) {
      return ChapterMeta(
        id: entry.key,
        nameSimple: entry.value.nameEn,
        nameArabic: entry.value.nameAr,
        versesCount: entry.value.verseCount,
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
