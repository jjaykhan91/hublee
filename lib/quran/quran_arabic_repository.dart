/// Loads Arabic ayah text from the unified KFGQPC Mushaf Smart v8
/// dataset.
///
/// Supports two text columns:
/// - `aya_text`        — Uthmanic Hafs Smart glyphs (for rendering
///                        with the KFGQPC font and tajweed colours).
/// - `aya_text_emlaey` — Plain/Imla'i Arabic (better for search).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Provides Arabic text for a single surah, keyed by ayah number.
class QuranArabicRepository {
  const QuranArabicRepository();

  /// Returns a map of `{ ayahNumber: arabicText }` for [surahId].
  ///
  /// When [useGlyphText] is `true` (the default) the Uthmanic glyph
  /// column (`aya_text`) is used. Set it to `false` to get the
  /// Imla'i column (`aya_text_emlaey`) which is suited for search.
  Future<Map<String, String>> loadArabicSurah(
    int surahId, {
    bool useGlyphText = true,
  }) async {
    final rawJson = await rootBundle.loadString(
      AssetPaths.kfgqpcQuranMushafSmartV8,
    );
    final List<dynamic> rows = json.decode(rawJson);

    final column = useGlyphText ? 'aya_text' : 'aya_text_emlaey';
    final ayahMap = <String, String>{};

    for (final row in rows) {
      if (row['sura_no'] == surahId) {
        final ayahNumber = row['aya_no'];
        final text = (row[column] as String?)?.trim();
        if (text != null && text.isNotEmpty) {
          ayahMap['$ayahNumber'] = text;
        }
      }
    }

    return ayahMap;
  }
}
