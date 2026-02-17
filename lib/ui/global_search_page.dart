/// Full-screen search page for Quran ayahs and Hadith text.
///
/// Uses a debounced text field to search across all surahs
/// (Arabic + English) and all hadith collections (English + Arabic).
/// Results are grouped by type (Quran / Hadith) and tapping a
/// result navigates to the detail page scrolled to the match.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_repository.dart';
import '../quran/quran_chapters_repository.dart';
import '../quran/quran_arabic_repository.dart';
import '../quran/quran_translation_repository.dart';
import '../services/search_models.dart';

/// Global search across Quran and Hadith with debounced input.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _queryController = TextEditingController();

  /// Timer for debouncing search input (300 ms delay).
  Timer? _debounceTimer;

  bool _isSearching = false;
  final List<HadithSearchHit> _hadithResults = [];
  final List<QuranSearchHit> _quranResults = [];

  @override
  void dispose() {
    _queryController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Restarts the debounce timer on each keystroke.
  void _onQueryChanged(String rawQuery) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(rawQuery),
    );
  }

  /// Runs a full-text search across both Quran and Hadith data.
  Future<void> _performSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _hadithResults.clear();
        _quranResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      // Search hadith collections.
      final hadithRepo = const HadithRepository();
      final hadithHits = await hadithRepo.searchHadith(query, limit: 100);

      // Search Quran ayahs across all surahs.
      final quranHits = await _searchQuranAyahs(query);

      if (!mounted) return;
      setState(() {
        _hadithResults
          ..clear()
          ..addAll(hadithHits);
        _quranResults
          ..clear()
          ..addAll(quranHits);
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Iterates all 114 surahs to find ayahs matching [query].
  Future<List<QuranSearchHit>> _searchQuranAyahs(
    String query,
  ) async {
    final chaptersRepo = const QuranChaptersRepository();
    final arabicRepo = const QuranArabicRepository();
    final translationRepo = const QuranTranslationRepository();

    final chapters = await chaptersRepo.loadChapters();
    final hits = <QuranSearchHit>[];
    final queryLower = query.toLowerCase();

    for (final chapter in chapters) {
      Map<String, String> arabicAyahs = const {};
      Map<String, String> englishAyahs = const {};
      try {
        arabicAyahs = await arabicRepo.loadArabicSurah(chapter.id);
        englishAyahs = await translationRepo.loadClearQuran(chapter.id);
      } catch (_) {
        continue;
      }

      for (var ayahNum = 1; ayahNum <= chapter.versesCount; ayahNum++) {
        final key = '$ayahNum';
        final arabicText = arabicAyahs[key] ?? '';
        final englishText = englishAyahs[key] ?? '';

        final isMatch = arabicText.contains(query) ||
            englishText.toLowerCase().contains(queryLower);
        if (!isMatch) continue;

        // Build a snippet around the match.
        final snippet = _buildSnippet(
          englishText,
          queryLower,
          query.length,
        );

        hits.add(QuranSearchHit(
          surahId: chapter.id,
          ayah: ayahNum,
          surahName: chapter.nameSimple,
          snippet: snippet,
        ));

        if (hits.length >= 150) return hits;
      }
      if (hits.length >= 150) break;
    }
    return hits;
  }

  /// Extracts a snippet window around the first match in [text].
  String? _buildSnippet(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalResults = _quranResults.length + _hadithResults.length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onSubmitted: _performSearch,
          decoration: const InputDecoration(
            hintText: 'Search Quran and Hadith\u2026',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : totalResults == 0
              ? _buildEmptyState(theme, colorScheme)
              : _buildResultsList(theme, colorScheme),
    );
  }

  /// Shown before any search or when there are no results.
  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Search across Quran and Hadith',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the grouped results list (Quran first, then Hadith).
  Widget _buildResultsList(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (_quranResults.isNotEmpty) ...[
          _ResultSectionHeader(
            icon: Icons.menu_book_rounded,
            label: 'Quran (${_quranResults.length})',
            colorScheme: colorScheme,
          ),
          ..._quranResults.map(
            (hit) => _QuranResultTile(hit: hit),
          ),
          const SizedBox(height: 16),
        ],
        if (_hadithResults.isNotEmpty) ...[
          _ResultSectionHeader(
            icon: Icons.library_books_rounded,
            label: 'Hadith (${_hadithResults.length})',
            colorScheme: colorScheme,
          ),
          ..._hadithResults.map(
            (hit) => _HadithResultTile(hit: hit),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Private sub-widgets
// ────────────────────────────────────────────────────────────────

/// Section header for search result groups.
class _ResultSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _ResultSectionHeader({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// A search-result tile for a hadith match.
class _HadithResultTile extends StatelessWidget {
  final HadithSearchHit hit;

  const _HadithResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(
            '/hadith/${hit.collectionId}/${hit.bookFile}'
            '?title=${Uri.encodeComponent(hit.bookTitle ?? hit.bookFile)}'
            '&index=${hit.hadithIndex}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.library_books_outlined,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.bookTitle ?? hit.bookFile}'
                      ' \u2022 Hadith ${hit.hadithIndex + 1}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hit.snippet!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// A search-result tile for a Quran ayah match.
class _QuranResultTile extends StatelessWidget {
  final QuranSearchHit hit;

  const _QuranResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/quran/${hit.surahId}?ayah=${hit.ayah}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hit.surahName} \u2022 Ayah ${hit.ayah}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (hit.snippet != null && hit.snippet!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hit.snippet!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
