import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/asset_paths.dart';
import 'models.dart';

/// Loads chapter metadata directly from the unified Hafs Smart v8 JSON.
///
/// The file contains a flat list of ayat; we group by `sura_no` to build
/// chapter metadata (names + verse counts).
class QuranChaptersRepository {
  const QuranChaptersRepository();

  /// Loads all chapters (1–114) with names and verse counts.
  Future<List<ChapterMeta>> loadChapters() async {
    final raw = await rootBundle.loadString(AssetPaths.kFGQPCQuranMushafSmartV8);
    final List<dynamic> list = json.decode(raw);

    // Group: sura_no -> {name_en, name_ar, count}
    final Map<int, _Accumulator> acc = {};

    for (final item in list) {
      final int sura = item['sura_no'] as int;
      final String nameEn = (item['sura_name_en'] as String).trim();
      final String nameAr = (item['sura_name_ar'] as String).trim();

      final bucket = acc.putIfAbsent(sura, () => _Accumulator(nameEn, nameAr));
      bucket.count++;
    }

    final chapters = <ChapterMeta>[];
    for (final entry in acc.entries) {
      chapters.add(
        ChapterMeta(
          id: entry.key,
          nameSimple: entry.value.nameEn,
          nameArabic: entry.value.nameAr,
          versesCount: entry.value.count,
        ),
      );
    }

    // Ensure ordered by sura id.
    chapters.sort((a, b) => a.id.compareTo(b.id));
    return chapters;
  }
}

class _Accumulator {
  final String nameEn;
  final String nameAr;
  int count = 0;
  _Accumulator(this.nameEn, this.nameAr);
}
