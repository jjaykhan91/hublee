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

import '../router_paths.dart';
import '../services/hadith_search_service.dart';
import '../services/quran_search_service.dart';
import '../services/search_models.dart';
import '../theme/app_tokens.dart';
import 'widgets/section_header.dart';
import 'widgets/hublee_card.dart';

/// Global search across Quran and Hadith with debounced input.
class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.quranSearch = const QuranSearchService(),
    this.hadithSearch = const HadithSearchService(),
  });

  /// Injected in tests so a slower query cannot overwrite a newer one.
  final QuranSearchService quranSearch;
  final HadithSearchService hadithSearch;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _queryController = TextEditingController();

  /// Timer for debouncing search input (300 ms delay).
  Timer? _debounceTimer;

  /// Incremented on every search so late responses from an older
  /// query are dropped instead of replacing newer results.
  int _searchGeneration = 0;

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
    final generation = ++_searchGeneration;
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _hadithResults.clear();
        _quranResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final hadithFuture = widget.hadithSearch.search(query, limit: 100);
      final quranFuture = widget.quranSearch.search(query, limit: 150);
      final hadithHits = await hadithFuture;
      final quranHits = await quranFuture;
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _hadithResults
          ..clear()
          ..addAll(hadithHits);
        _quranResults
          ..clear()
          ..addAll(quranHits);
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _isSearching = false);
    }
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
  Widget _buildResultsList(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.list,
      children: [
        if (_quranResults.isNotEmpty) ...[
          SectionHeader(
            'Quran (${_quranResults.length})',
            icon: Icons.menu_book_rounded,
          ),
          ..._quranResults.map((hit) => _QuranResultTile(hit: hit)),
          const SizedBox(height: 16),
        ],
        if (_hadithResults.isNotEmpty) ...[
          SectionHeader(
            'Hadith (${_hadithResults.length})',
            icon: Icons.library_books_rounded,
          ),
          ..._hadithResults.map((hit) => _HadithResultTile(hit: hit)),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Private result tiles
// ────────────────────────────────────────────────────────────────

/// A search-result tile for a hadith match.
class _HadithResultTile extends StatelessWidget {
  final HadithSearchHit hit;

  const _HadithResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HubleeCard(
      onTap: () {
        context.push(
          AppRoute.hadithBook(
            collectionId: hit.collectionId,
            bookFile: hit.bookFile,
            bookTitle: hit.bookTitle ?? hit.bookFile,
            index: hit.hadithIndex,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.library_books_outlined, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hit.bookTitle ?? hit.bookFile}'
                  ' \u2022 Hadith ${hit.hadithIndex + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
    );
  }
}

/// A search-result tile for a Quran ayah match.
class _QuranResultTile extends StatelessWidget {
  final QuranSearchHit hit;

  const _QuranResultTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    return HubleeCard(
      onTap: () => context.push(AppRoute.surah(hit.surahId, ayah: hit.ayah)),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
    );
  }
}
