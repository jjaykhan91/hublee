/// Loads ClearQuran English translations on a per-surah basis.
///
/// Each surah's translation lives in a separate JSON file at
/// `assets/quran/en.clearquran/<surahId>.json`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Provides English translations keyed by ayah number.
class QuranTranslationRepository {
  const QuranTranslationRepository();

  static final Map<int, Future<Map<String, String>>> _cache = {};

  /// Clears the session cache. Tests only.
  @visibleForTesting
  static void resetCache() => _cache.clear();

  /// Returns a map of `{ ayahNumber: englishText }` for [surahId].
  ///
  /// The JSON file is expected to be a flat `Map<String, String>`.
  /// Throws [FormatException] if the JSON shape is unexpected.
  Future<Map<String, String>> loadClearQuran(int surahId) {
    return _cache.putIfAbsent(surahId, () => _loadUncached(surahId));
  }

  Future<Map<String, String>> _loadUncached(int surahId) async {
    final rawJson = await rootBundle.loadString(
      AssetPaths.quranClearQuran(surahId),
    );
    final decoded = json.decode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('English surah JSON must be a Map');
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}
