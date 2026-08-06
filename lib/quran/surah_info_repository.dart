/// Repository for loading per-surah background information.
///
/// Data is sourced from `assets/quran/surah_info.json`, which is
/// downloaded from the quran.com API `/chapters/{id}/info` endpoint
/// via `tools/build_surah_info.dart`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

/// Immutable data class holding the summary/info for one surah.
class SurahInfo {
  final int id;

  /// Short plain-text summary (1-3 sentences).
  final String shortText;

  /// Full description as HTML (with `<h2>`, `<p>`, `<ol>`, etc.).
  final String fullText;

  /// Attribution source for the commentary.
  final String source;

  const SurahInfo({
    required this.id,
    required this.shortText,
    required this.fullText,
    required this.source,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      id: json['id'] as int,
      shortText: (json['short_text'] as String?) ?? '',
      fullText: (json['text'] as String?) ?? '',
      source: (json['source'] as String?) ?? '',
    );
  }
}

/// Loads surah information from the bundled JSON asset.
///
/// Uses a static cache so the JSON is parsed only once per session.
class SurahInfoRepository {
  const SurahInfoRepository();

  static List<SurahInfo>? _cache;

  /// Loads all 114 surah info entries.
  Future<List<SurahInfo>> loadAll() async {
    if (_cache != null) return _cache!;

    final rawJson = await rootBundle.loadString(AssetPaths.surahInfo);
    final List<dynamic> list = json.decode(rawJson);
    _cache = list.map((e) => SurahInfo.fromJson(e)).toList();
    return _cache!;
  }

  /// Loads info for a specific surah by [surahId] (1-based).
  ///
  /// Returns an empty [SurahInfo] if the id is not found.
  Future<SurahInfo> loadBySurahId(int surahId) async {
    final all = await loadAll();
    return all.firstWhere(
      (info) => info.id == surahId,
      orElse: () =>
          SurahInfo(id: surahId, shortText: '', fullText: '', source: ''),
    );
  }
}
