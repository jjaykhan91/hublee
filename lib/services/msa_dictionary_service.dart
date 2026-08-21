/// Loads the bundled Modern Standard Arabic dictionary.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting, immutable;
import 'package:flutter/services.dart' show rootBundle;

import '../data/asset_paths.dart';

@immutable
class MsaEntry {
  const MsaEntry({
    required this.arabic,
    required this.english,
    required this.pos,
    this.root,
  });

  final String arabic;
  final String english;
  final String pos;
  final String? root;

  String get id => 'msa:$arabic:${english.toLowerCase()}';
}

/// English ↔ MSA lookup. Separate from the Quranic glossary.
class MsaDictionaryService {
  const MsaDictionaryService();

  static Future<List<MsaEntry>>? _cache;

  @visibleForTesting
  static void resetCache() => _cache = null;

  Future<List<MsaEntry>> load() => _cache ??= _load();

  Future<List<MsaEntry>> search(String query, {int limit = 80}) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final folded = _foldArabic(query.trim());
    final index = await load();
    final scored = <({MsaEntry entry, int rank})>[];
    for (final entry in index) {
      final en = entry.english.toLowerCase();
      final tokens = en
          .replaceAll(RegExp(r'[^a-z]+'), ' ')
          .split(RegExp(r'\s+'))
          .where((token) => token.length > 1);
      var rank = 99;
      if (tokens.contains(needle) || en == needle) {
        rank = 0;
      } else if (en.startsWith(needle) ||
          tokens.any((token) => token.startsWith(needle))) {
        rank = 1;
      } else if (en.contains(needle)) {
        rank = 2;
      } else if (folded.isNotEmpty &&
          _foldArabic(entry.arabic).contains(folded)) {
        rank = 3;
      } else if (entry.root != null &&
          _foldArabic(entry.root!).contains(folded)) {
        rank = 4;
      }
      if (rank == 99) continue;
      scored.add((entry: entry, rank: rank));
    }
    scored.sort((a, b) => a.rank.compareTo(b.rank));
    return [for (final hit in scored.take(limit)) hit.entry];
  }

  static Future<List<MsaEntry>> _load() async {
    final raw = await rootBundle.loadString(AssetPaths.msaDictionary);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rows = decoded['entries'] as List<dynamic>;
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          MsaEntry(
            arabic: row['ar'] as String,
            english: row['en'] as String,
            pos: row['pos'] as String? ?? '',
            root: row['root'] as String?,
          ),
    ];
  }
}

String _foldArabic(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x064B && rune <= 0x065F) continue;
    if (rune == 0x0670 || rune == 0x0640) continue;
    if (rune >= 0x06D6 && rune <= 0x06ED) continue;
    if (rune == 0x0622 || rune == 0x0623 || rune == 0x0625 || rune == 0x0671) {
      buffer.writeCharCode(0x0627);
      continue;
    }
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}
