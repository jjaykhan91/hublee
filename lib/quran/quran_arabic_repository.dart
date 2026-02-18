/// Loads Arabic ayah text from the unified KFGQPC Mushaf Smart v8
/// dataset and the standard Uthmanic per-surah files.
///
/// Two text sources are available:
/// - **KFGQPC PUA glyphs** (`aya_text`) — for rendering with the
///   bundled KFGQPCQuranicFontHafsSmart font. Not parseable for
///   tajweed because it uses Private Use Area characters.
/// - **Standard Uthmanic** (`assets/quran/ar/{surahId}.json`) —
///   standard Arabic Unicode with full tashkeel, downloaded from
///   the quran.com API `text_uthmani` field. Works with any Arabic
///   font (Amiri, Scheherazade, Noto Naskh) and supports tajweed
///   colour analysis.
/// - **Imla'i** (`aya_text_emlaey`) — simplified spelling for
///   search indexing only.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Provides Arabic text for a single surah, keyed by ayah number.
class QuranArabicRepository {
  const QuranArabicRepository();

  /// Returns a map of `{ ayahNumber: arabicText }` for [surahId].
  ///
  /// When [useGlyphText] is `true` (the default) the KFGQPC PUA
  /// glyph column (`aya_text`) is used. Set it to `false` to get
  /// the Imla'i column (`aya_text_emlaey`) for search.
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

  /// Loads standard Uthmanic Arabic text (full tashkeel, standard
  /// Unicode) from the per-surah JSON files in `assets/quran/ar/`.
  ///
  /// These files were downloaded from the quran.com API
  /// `text_uthmani` field and contain proper harakat for rendering
  /// with Google Fonts and tajweed colour analysis.
  Future<Map<String, String>> loadUthmaniStandard(int surahId) async {
    final rawJson = await rootBundle.loadString(
      AssetPaths.quranUthmaniStandard(surahId),
    );
    final decoded = json.decode(rawJson);

    if (decoded is Map<String, dynamic>) {
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    }

    return const {};
  }
}
