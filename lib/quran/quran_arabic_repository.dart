import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/asset_paths.dart';

class QuranArabicRepository {
  const QuranArabicRepository();

  /// Arabic text JSON per surah: `assets/quran/ar/<surahId>.json`
  Future<Map<String, String>> loadArabicSurah(int surahId) async {
    final raw = await rootBundle.loadString(AssetPaths.quranArabic(surahId));
    final decoded = json.decode(raw);
    if (decoded is! Map) {
      throw const FormatException('Arabic surah JSON must be a Map');
    }
    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
