import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/asset_paths.dart';

/// Loads Arabic ayat from the unified KFGQPC Mushaf Smart v8 dataset.
///
/// Per dataset guidance:
/// - `aya_text`         → Uthmanic Hafs Smart Unicode (use this for display)
/// - `aya_text_emlaey`  → Plain/“emlaey” Arabic (best for search)
class QuranArabicRepository {
  const QuranArabicRepository();

  /// Returns a map of "ayahNumber" -> "Arabic text" for [surahId].
  ///
  /// [useGlyphText] (default: true) chooses dataset column:
  ///   - true  → `aya_text`         (display with KFGQPC Hafs Smart font)
  ///   - false → `aya_text_emlaey`  (plain Arabic, good for search)
  Future<Map<String, String>> loadArabicSurah(
    int surahId, {
    bool useGlyphText = true,
  }) async {
    final raw = await rootBundle.loadString(AssetPaths.kFGQPCQuranMushafSmartV8);
    final List<dynamic> rows = json.decode(raw);

    final column = useGlyphText ? 'aya_text' : 'aya_text_emlaey';
    final out = <String, String>{};

    for (final row in rows) {
      if (row['sura_no'] == surahId) {
        final ayahNo = row['aya_no'];
        final text = (row[column] as String?)?.trim();
        if (text != null && text.isNotEmpty) {
          out['$ayahNo'] = text;
        }
      }
    }
    return out;
  }
}
