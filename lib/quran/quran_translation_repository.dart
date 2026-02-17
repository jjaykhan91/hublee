/// Loads ClearQuran English translations on a per-surah basis.
///
/// Each surah's translation lives in a separate JSON file at
/// `assets/quran/en.clearquran/<surahId>.json`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Provides English translations keyed by ayah number.
class QuranTranslationRepository {
  const QuranTranslationRepository();

  /// Returns a map of `{ ayahNumber: englishText }` for [surahId].
  ///
  /// The JSON file is expected to be a flat `Map<String, String>`.
  /// Throws [FormatException] if the JSON shape is unexpected.
  Future<Map<String, String>> loadClearQuran(int surahId) async {
    final rawJson = await rootBundle.loadString(
      AssetPaths.quranClearQuran(surahId),
    );
    final decoded = json.decode(rawJson);
    if (decoded is! Map) {
      throw const FormatException(
        'English surah JSON must be a Map',
      );
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}
