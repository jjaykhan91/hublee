import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/asset_paths.dart';

class QuranTranslationRepository {
  const QuranTranslationRepository();

  /// ClearQuran English per surah: `assets/quran/en.clearquran/<surahId>.json`
  Future<Map<String, String>> loadClearQuran(int surahId) async {
    final raw = await rootBundle.loadString(AssetPaths.quranClearQuran(surahId));
    final decoded = json.decode(raw);
    if (decoded is! Map) {
      throw const FormatException('English surah JSON must be a Map');
    }
    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
