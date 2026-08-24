/// Session-cached dictionary of every Quranic word-by-word gloss.
///
/// This is a Quranic vocabulary index, not a general Arabic–English
/// dictionary. Glosses come from the bundled Shaikh/Khatri word-by-word
/// assets. Hans Wehr and similar modern lexicons cannot be redistributed.
library;

import 'package:flutter/foundation.dart' show visibleForTesting, immutable;

import '../quran/arabic_fold.dart';
import '../quran/arabic_word_segmenter.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/word_by_word_repository.dart';
import 'app_metrics.dart';
import 'vocab_service.dart';

const _kBatchSize = 16;
const _kMaxSamples = 8;

/// One occurrence of a dictionary headword.
@immutable
class DictionaryOccurrence {
  const DictionaryOccurrence({
    required this.surahId,
    required this.ayah,
    required this.surahName,
  });

  final int surahId;
  final int ayah;
  final String surahName;
}

/// A searchable Quranic word or phrase.
@immutable
class DictionaryEntry {
  const DictionaryEntry({
    required this.arabic,
    required this.gloss,
    required this.count,
    required this.samples,
  });

  final String arabic;
  final String gloss;
  final int count;
  final List<DictionaryOccurrence> samples;

  String get id => VocabEntry.vocabId(arabic, gloss);
}

/// Builds and queries the Quranic word index.
class QuranDictionaryService {
  const QuranDictionaryService({
    this.maxSurahId = 114,
    QuranChaptersRepository? chaptersRepo,
    QuranArabicRepository? arabicRepo,
    WordByWordRepository? wordByWordRepo,
  }) : _chaptersRepo = chaptersRepo ?? const QuranChaptersRepository(),
       _arabicRepo = arabicRepo ?? const QuranArabicRepository(),
       _wordByWordRepo = wordByWordRepo ?? const WordByWordRepository();

  /// Tests can limit the corpus to one surah.
  final int maxSurahId;

  final QuranChaptersRepository _chaptersRepo;
  final QuranArabicRepository _arabicRepo;
  final WordByWordRepository _wordByWordRepo;

  static Future<List<DictionaryEntry>>? _indexFuture;
  static QuranDictionaryService? _indexOwner;

  @visibleForTesting
  static void resetCache() {
    _indexFuture = null;
    _indexOwner = null;
  }

  Future<List<DictionaryEntry>> search(String query, {int limit = 80}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final needle = trimmed.toLowerCase();
    final foldedNeedle = foldArabicForSearch(trimmed);
    final needles = <String>{needle, ...?_englishAliases[needle]};

    final index = await _ensureIndex();
    final scored = <({DictionaryEntry entry, int rank})>[];
    for (final entry in index) {
      final rank = _matchRank(
        entry,
        needles: needles,
        foldedNeedle: foldedNeedle,
      );
      if (rank == null) continue;
      scored.add((entry: entry, rank: rank));
    }
    scored.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      return b.entry.count.compareTo(a.entry.count);
    });
    return [for (final hit in scored.take(limit)) hit.entry];
  }

  /// Highest-frequency entries, for a starter learning deck.
  Future<List<DictionaryEntry>> frequent({int limit = 20}) async {
    final index = await _ensureIndex();
    return index.take(limit).toList();
  }

  Future<List<DictionaryEntry>> _ensureIndex() {
    if (!identical(_indexOwner, this)) {
      _indexFuture = null;
    }
    _indexOwner = this;
    return _indexFuture ??= AppMetrics.instance.time(
      'dictionary.index',
      _buildIndex,
    );
  }

  Future<List<DictionaryEntry>> _buildIndex() async {
    final chapters = await _chaptersRepo.loadChapters();
    final names = {
      for (final chapter in chapters) chapter.id: chapter.nameSimple,
    };
    final buckets = <String, _Bucket>{};

    final last = maxSurahId < 114 ? maxSurahId : 114;
    for (var start = 1; start <= last; start += _kBatchSize) {
      final end = (start + _kBatchSize - 1).clamp(1, last);
      final batch = [for (var id = start; id <= end; id++) id];
      await Future.wait(
        batch.map((surahId) => _indexSurah(surahId, names, buckets)),
      );
    }

    final entries =
        buckets.values
            .map(
              (bucket) => DictionaryEntry(
                arabic: bucket.arabic,
                gloss: bucket.gloss,
                count: bucket.count,
                samples: List.unmodifiable(bucket.samples),
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }

  Future<void> _indexSurah(
    int surahId,
    Map<int, String> names,
    Map<String, _Bucket> buckets,
  ) async {
    final arabicAyahs = await _arabicRepo.loadUthmaniStandard(surahId);
    final glossAyahs = await _wordByWordRepo.loadSurah(surahId);
    if (glossAyahs.isEmpty) return;

    final surahName = names[surahId] ?? 'Surah $surahId';

    for (final entry in glossAyahs.entries) {
      final ayah = entry.key;
      final glosses = entry.value;
      final arabic = arabicAyahs['$ayah'];
      if (arabic == null || arabic.isEmpty) continue;

      final words = segmentArabicWords(arabic);
      if (words.length != glosses.length) continue;

      for (var i = 0; i < words.length; i++) {
        final phrase = glossPhraseAt(glosses, i);
        if (phrase == null || phrase.firstWord != i) continue;

        final arabicPhrase = words
            .sublist(phrase.firstWord, phrase.lastWord + 1)
            .map((w) => w.text)
            .join(' ');
        if (arabicPhrase.isEmpty || phrase.gloss.isEmpty) continue;

        final key = VocabEntry.vocabId(arabicPhrase, phrase.gloss);
        final bucket = buckets.putIfAbsent(
          key,
          () => _Bucket(arabic: arabicPhrase, gloss: phrase.gloss),
        );
        bucket.count++;
        if (bucket.samples.length < _kMaxSamples) {
          bucket.samples.add(
            DictionaryOccurrence(
              surahId: surahId,
              ayah: ayah,
              surahName: surahName,
            ),
          );
        }
      }
    }
  }
}

class _Bucket {
  _Bucket({required this.arabic, required this.gloss});

  final String arabic;
  final String gloss;
  int count = 0;
  final List<DictionaryOccurrence> samples = [];
}

/// Extra English queries that should also look up a Quranic gloss.
///
/// These are search helpers only — they do not add meanings that are not
/// already in the word-by-word glossary.
const _englishAliases = <String, List<String>>{
  'god': ['allah'],
  'gods': ['allah'],
};

const _englishStopwords = {
  'a',
  'an',
  'and',
  'as',
  'be',
  'for',
  'from',
  'in',
  'is',
  'not',
  'of',
  'on',
  'or',
  'the',
  'to',
  'we',
  'who',
  'with',
  'you',
};

/// 0 exact English word, 1 prefix, 2 related stem, 3 Arabic, 4 gloss substring.
int? _matchRank(
  DictionaryEntry entry, {
  required Set<String> needles,
  required String foldedNeedle,
}) {
  var best = 99;
  final gloss = entry.gloss.toLowerCase();
  final tokens = _englishTokens(entry.gloss);
  final arabicHit =
      foldedNeedle.isNotEmpty &&
      foldArabicForSearch(entry.arabic).contains(foldedNeedle);

  if (arabicHit) best = 3;

  for (final needle in needles) {
    if (needle.isEmpty) continue;
    if (tokens.contains(needle)) {
      best = 0;
      break;
    }
    if (tokens.any((token) => _isPrefixMatch(token, needle))) {
      best = best < 1 ? best : 1;
      continue;
    }
    if (needle.length >= 4 &&
        tokens.any((token) => _sharesStem(token, needle))) {
      best = best < 2 ? best : 2;
      continue;
    }
    if (gloss.contains(needle)) {
      best = best < 4 ? best : 4;
    }
  }

  return best == 99 ? null : best;
}

List<String> _englishTokens(String gloss) {
  return gloss
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1 && !_englishStopwords.contains(token))
      .toList();
}

bool _isPrefixMatch(String token, String needle) {
  if (needle.length < 3 || token.length < 3) return false;
  return token.startsWith(needle) || needle.startsWith(token);
}

bool _sharesStem(String token, String needle) {
  return token.length >= 4 &&
      needle.length >= 4 &&
      token.substring(0, 4) == needle.substring(0, 4);
}
