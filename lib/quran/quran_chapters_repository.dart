import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';
import 'models.dart';

class QuranChaptersRepository {
  const QuranChaptersRepository();

  Future<List<ChapterMeta>> loadChapters() async {
    // Try the declared path first
    late String raw;
    try {
      raw = await rootBundle.loadString(AssetPaths.quranChapters);
    } catch (_) {
      // Fallback: sometimes files are named chapters.json instead of chapters.min.json
      raw = await rootBundle.loadString('assets/quran/chapters.min.json');
    }

    final decoded = json.decode(raw);

    // Support both: a top-level List OR { "chapters": [ ... ] }
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['chapters'] is List) {
      list = decoded['chapters'];
    } else {
      throw const FormatException('chapters JSON must be a List or a Map with "chapters" List');
    }

    return list.whereType<Map<String, dynamic>>().map(ChapterMeta.fromJson).toList(growable: false);
  }
}
