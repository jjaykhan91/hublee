/// Orchestrates full-text search across all Quran surahs (Arabic + English).
///
/// Builds a session-cached ayah index on first search so later queries
/// scan memory instead of walking 114 asset files sequentially.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../quran/arabic_fold.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/surah_ayah_parser.dart';
import 'app_metrics.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_translation_repository.dart';
import 'search_models.dart';
import 'search_match.dart';

/// How many surahs to decode in parallel while building the index.
const _kIndexBatchSize = 24;

/// Service that searches Quran ayahs by Arabic or English text.
class QuranSearchService {
  const QuranSearchService({
    QuranChaptersRepository? chaptersRepo,
    QuranArabicRepository? arabicRepo,
    QuranTranslationRepository? translationRepo,
  }) : _chaptersRepo = chaptersRepo ?? const QuranChaptersRepository(),
       _arabicRepo = arabicRepo ?? const QuranArabicRepository(),
       _translationRepo = translationRepo ?? const QuranTranslationRepository();

  final QuranChaptersRepository _chaptersRepo;
  final QuranArabicRepository _arabicRepo;
  final QuranTranslationRepository _translationRepo;

  /// Session cache of every searchable ayah. Shared so opening Search
  /// twice in one launch does not rebuild the corpus.
  static Future<List<_QuranIndexRow>>? _indexFuture;

  /// Repos that produced [_indexFuture]. A different stub in tests must
  /// not reuse an index built from another repository.
  static QuranSearchService? _indexOwner;

  /// Clears the session index. Tests only.
  @visibleForTesting
  static void resetCache() {
    _indexFuture = null;
    _indexOwner = null;
  }

  /// Builds the session index if needed. Safe to call from splash warmup.
  Future<void> warmIndex() async {
    await _ensureIndex();
  }

  /// Searches all surahs for ayahs matching [query]. Returns up to [limit] hits.
  Future<QuranSearchResult> search(String query, {int limit = 150}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const QuranSearchResult();
    final queryLower = trimmed.toLowerCase();
    final foldedQuery = foldArabicForSearch(trimmed);

    final indexWait = Stopwatch()..start();
    final index = await _ensureIndex();
    final indexElapsed = indexWait.elapsed;
    final scan = Stopwatch()..start();
    final pending = <({_QuranIndexRow row, int score, bool arabicMatch})>[];

    String? invalidJumpHint;
    _QuranIndexRow? jumpRow;
    final parsed = tryParseSurahAyah(trimmed);
    if (parsed != null) {
      _QuranIndexRow? chapterRow;
      for (final row in index) {
        if (row.surahId != parsed.surahId) continue;
        chapterRow ??= row;
        if (row.ayah == parsed.ayah) {
          jumpRow = row;
          break;
        }
      }
      final versesCount = chapterRow?.versesCount ?? 0;
      if (!ayahExistsInChapter(parsed.ayah, versesCount)) {
        final name = chapterRow?.surahName ?? 'Surah ${parsed.surahId}';
        invalidJumpHint =
            '$name has $versesCount ayahs, so '
            '${parsed.surahId}:${parsed.ayah} is not a verse';
      }
    }

    if (jumpRow != null) {
      pending.add((row: jumpRow, score: 0, arabicMatch: false));
    }

    for (final row in index) {
      if (jumpRow != null &&
          row.surahId == jumpRow.surahId &&
          row.ayah == jumpRow.ayah) {
        continue;
      }
      final arabicMatch =
          foldedQuery.isNotEmpty && row.arabicFold.contains(foldedQuery);
      final englishMatch = row.englishLower.contains(queryLower);
      if (!arabicMatch && !englishMatch) continue;

      final score = englishExactWordMatch(row.englishLower, queryLower) ? 1 : 2;
      pending.add((row: row, score: score, arabicMatch: arabicMatch));
    }

    pending.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      final bySurah = a.row.surahId.compareTo(b.row.surahId);
      if (bySurah != 0) return bySurah;
      return a.row.ayah.compareTo(b.row.ayah);
    });

    final totalCount = pending.length;
    final ranked = pending.take(limit).toList(growable: false);

    final needUthmani = <int>{
      for (final hit in ranked)
        if (hit.score == 0 || hit.arabicMatch) hit.row.surahId,
    };
    final uthmaniBySurah = <int, Map<String, String>>{};
    if (needUthmani.isNotEmpty) {
      await Future.wait(
        needUthmani.map((id) async {
          try {
            uthmaniBySurah[id] = await _arabicRepo.loadUthmaniStandard(id);
          } catch (_) {}
        }),
      );
    }

    final hits = [
      for (final hit in ranked)
        _hitFromRow(
          hit.row,
          queryLower,
          trimmed,
          isJump: hit.score == 0,
          arabicMatch: hit.arabicMatch,
          uthmani: uthmaniBySurah[hit.row.surahId]?['${hit.row.ayah}'],
        ),
    ];
    _recordQuery(scan.elapsed, indexElapsed, hits.length);
    return QuranSearchResult(
      hits: hits,
      totalCount: totalCount,
      invalidJumpHint: invalidJumpHint,
    );
  }

  void _recordQuery(Duration scan, Duration indexWait, int hits) {
    AppMetrics.instance.recordTiming(
      'search.quran',
      scan,
      detail: {'hits': '$hits', 'indexWaitMs': '${indexWait.inMilliseconds}'},
    );
  }

  Future<List<_QuranIndexRow>> _ensureIndex() {
    if (!identical(_indexOwner, this)) {
      _indexFuture = null;
    }
    _indexOwner = this;
    return _indexFuture ??= _buildIndex();
  }

  Future<List<_QuranIndexRow>> _buildIndex() {
    return AppMetrics.instance.time('search.quranIndex', () async {
      final chapters = await _chaptersRepo.loadChapters();
      final emlaeyAll = await _arabicRepo.loadAllEmlaey();
      final rows = <_QuranIndexRow>[];

      for (var i = 0; i < chapters.length; i += _kIndexBatchSize) {
        final end = i + _kIndexBatchSize < chapters.length
            ? i + _kIndexBatchSize
            : chapters.length;
        final batch = chapters.sublist(i, end);
        final loaded = await Future.wait(
          batch.map((chapter) async {
            try {
              final englishAyahs = await _translationRepo.loadClearQuran(
                chapter.id,
              );
              return (chapter, englishAyahs);
            } catch (_) {
              return null;
            }
          }),
        );

        for (final item in loaded) {
          if (item == null) continue;
          final (chapter, englishAyahs) = item;
          final arabicAyahs = emlaeyAll[chapter.id] ?? const <String, String>{};
          for (var ayahNum = 1; ayahNum <= chapter.versesCount; ayahNum++) {
            final key = '$ayahNum';
            final english = englishAyahs[key] ?? '';
            final arabic = arabicAyahs[key] ?? '';
            rows.add(
              _QuranIndexRow(
                surahId: chapter.id,
                ayah: ayahNum,
                surahName: chapter.nameSimple,
                versesCount: chapter.versesCount,
                arabic: arabic,
                arabicFold: foldArabicForSearch(arabic),
                english: english,
                englishLower: english.toLowerCase(),
              ),
            );
          }
        }
        // Let a frame run so splash/onboarding stay responsive.
        await Future<void>.delayed(Duration.zero);
      }
      return rows;
    });
  }

  static String? _buildSnippet(
    String text,
    String queryLower,
    int queryLength,
  ) {
    if (text.isEmpty) return null;
    final matchIndex = text.toLowerCase().indexOf(queryLower);
    if (matchIndex >= 0) {
      final start = (matchIndex - 40).clamp(0, text.length);
      final end = (matchIndex + queryLength + 60).clamp(0, text.length);
      var snippet = text.substring(start, end).trim();
      if (start > 0) snippet = '\u2026$snippet';
      if (end < text.length) snippet = '$snippet\u2026';
      return snippet;
    }
    return text;
  }

  static QuranSearchHit _hitFromRow(
    _QuranIndexRow row,
    String queryLower,
    String trimmed, {
    bool isJump = false,
    bool arabicMatch = false,
    String? uthmani,
  }) {
    return QuranSearchHit(
      surahId: row.surahId,
      ayah: row.ayah,
      surahName: row.surahName,
      snippet: isJump || row.english.isNotEmpty
          ? _buildSnippet(row.english, queryLower, trimmed.length)
          : null,
      arabicSnippet: (isJump || arabicMatch)
          ? _arabicSnippet(uthmani ?? '')
          : null,
    );
  }

  /// Truncates Uthmani text at a word boundary. Never used for search
  /// matching — [arabic] (emlaey) is the index field.
  static String? _arabicSnippet(String uthmani) {
    final trimmed = uthmani.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 120) return trimmed;
    final cut = trimmed.substring(0, 120);
    final lastSpace = cut.lastIndexOf(' ');
    final body = lastSpace > 40 ? cut.substring(0, lastSpace) : cut;
    return '$body\u2026';
  }
}

/// One searchable ayah in the session index.
class _QuranIndexRow {
  const _QuranIndexRow({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.versesCount,
    required this.arabic,
    required this.arabicFold,
    required this.english,
    required this.englishLower,
  });

  final int surahId;
  final int ayah;
  final String surahName;
  final int versesCount;
  final String arabic;
  final String arabicFold;
  final String english;
  final String englishLower;
}
