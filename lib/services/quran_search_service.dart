/// Orchestrates full-text search across all Quran surahs (Arabic + English).
///
/// Builds a session-cached ayah index on first search so later queries
/// scan memory instead of walking 114 asset files sequentially.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../quran/quran_arabic_repository.dart';
import 'app_metrics.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_translation_repository.dart';
import 'search_models.dart';

/// How many surahs to decode in parallel while building the index.
const _kIndexBatchSize = 8;

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

  /// Searches all surahs for ayahs matching [query]. Returns up to [limit] hits.
  Future<List<QuranSearchHit>> search(String query, {int limit = 150}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final queryLower = trimmed.toLowerCase();

    final indexWait = Stopwatch()..start();
    final index = await _ensureIndex();
    final indexElapsed = indexWait.elapsed;
    final scan = Stopwatch()..start();
    final hits = <QuranSearchHit>[];

    for (final row in index) {
      final isMatch =
          row.arabic.contains(trimmed) || row.englishLower.contains(queryLower);
      if (!isMatch) continue;

      hits.add(
        QuranSearchHit(
          surahId: row.surahId,
          ayah: row.ayah,
          surahName: row.surahName,
          snippet: _buildSnippet(row.english, queryLower, trimmed.length),
        ),
      );
      if (hits.length >= limit) {
        _recordQuery(scan.elapsed, indexElapsed, hits.length);
        return hits;
      }
    }
    _recordQuery(scan.elapsed, indexElapsed, hits.length);
    return hits;
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
      final rows = <_QuranIndexRow>[];

      for (var i = 0; i < chapters.length; i += _kIndexBatchSize) {
        final end = i + _kIndexBatchSize < chapters.length
            ? i + _kIndexBatchSize
            : chapters.length;
        final batch = chapters.sublist(i, end);
        final loaded = await Future.wait(
          batch.map((chapter) async {
            try {
              final arabicAyahs = await _arabicRepo.loadArabicSurah(
                chapter.id,
                useGlyphText: false, // aya_text_emlaey — searchable Imla'i
              );
              final englishAyahs = await _translationRepo.loadClearQuran(
                chapter.id,
              );
              return (chapter, arabicAyahs, englishAyahs);
            } catch (_) {
              return null;
            }
          }),
        );

        for (final item in loaded) {
          if (item == null) continue;
          final (chapter, arabicAyahs, englishAyahs) = item;
          for (var ayahNum = 1; ayahNum <= chapter.versesCount; ayahNum++) {
            final key = '$ayahNum';
            final english = englishAyahs[key] ?? '';
            rows.add(
              _QuranIndexRow(
                surahId: chapter.id,
                ayah: ayahNum,
                surahName: chapter.nameSimple,
                arabic: arabicAyahs[key] ?? '',
                english: english,
                englishLower: english.toLowerCase(),
              ),
            );
          }
        }
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
}

/// One searchable ayah in the session index.
class _QuranIndexRow {
  const _QuranIndexRow({
    required this.surahId,
    required this.ayah,
    required this.surahName,
    required this.arabic,
    required this.english,
    required this.englishLower,
  });

  final int surahId;
  final int ayah;
  final String surahName;
  final String arabic;
  final String english;
  final String englishLower;
}
