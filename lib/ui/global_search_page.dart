/// Full-screen search page for Quran ayahs and Hadith text.
///
/// Uses a debounced text field to search across all surahs
/// (Arabic + English) and all hadith collections (English + Arabic).
/// Scope chips pin Quran and Hadith above the list so a long Quran
/// hit list does not bury hadith matches. Tapping a result opens
/// the reader scrolled to the match.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/hadith_search_service.dart';
import '../services/quran_search_service.dart';
import '../services/app_metrics.dart';
import '../services/search_models.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_haptics.dart';
import 'widgets/section_header.dart';
import 'widgets/hublee_card.dart';
import 'widgets/search_highlight.dart';
import 'widgets/reading_width.dart';
import 'widgets/arabic_text.dart';

enum _SearchScope { all, quran, hadith }

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
  String _activeQuery = '';
  _SearchScope _scope = _SearchScope.all;
  final List<HadithSearchHit> _hadithResults = [];
  final List<QuranSearchHit> _quranResults = [];

  @override
  void initState() {
    super.initState();
    unawaited(_warmIndexes());
  }

  Future<void> _warmIndexes() async {
    try {
      await Future.wait([
        widget.quranSearch.warmIndex(),
        widget.hadithSearch.warmIndex(),
      ]);
    } catch (_) {
      // Query-time search will build the index if warmup fails.
    }
  }

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
        _activeQuery = '';
        _hadithResults.clear();
        _quranResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      await AppMetrics.instance.time('search.global', () async {
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
          _activeQuery = query;
          _isSearching = false;
          _clampScope();
        });
      }, detail: {'queryLen': '${query.length}'});
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
      body: ConstrainedReadingBody(
        child: totalResults == 0
            ? (_isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _buildEmptyState(theme, colorScheme))
            : Column(
                children: [
                  if (_isSearching) const LinearProgressIndicator(),
                  _buildScopeChips(),
                  Expanded(child: _buildResultsList()),
                ],
              ),
      ),
    );
  }

  /// Idle hint versus a completed search with zero hits.
  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    final idle = _activeQuery.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              idle ? Icons.search_rounded : Icons.search_off_rounded,
              size: 48,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              idle
                  ? 'Search across Quran and Hadith'
                  : 'No verses or hadiths match “$_activeQuery”',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (idle) ...[
              const SizedBox(height: 8),
              Text(
                'Try a word, or jump with 2:255',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// If the selected source has no hits, fall back so the list is not empty.
  void _clampScope() {
    final hasQuran = _quranResults.isNotEmpty;
    final hasHadith = _hadithResults.isNotEmpty;
    switch (_scope) {
      case _SearchScope.quran:
        if (!hasQuran) {
          _scope = hasHadith ? _SearchScope.hadith : _SearchScope.all;
        }
      case _SearchScope.hadith:
        if (!hasHadith) {
          _scope = hasQuran ? _SearchScope.quran : _SearchScope.all;
        }
      case _SearchScope.all:
        break;
    }
  }

  void _selectScope(_SearchScope scope) {
    if (_scope == scope) return;
    AppHaptics.selection();
    setState(() => _scope = scope);
  }

  Widget _buildScopeChips() {
    final quranCount = _quranResults.length;
    final hadithCount = _hadithResults.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _ScopeChip(
            label: 'All',
            selected: _scope == _SearchScope.all,
            onSelected: () => _selectScope(_SearchScope.all),
          ),
          _ScopeChip(
            label: 'Quran ($quranCount)',
            selected: _scope == _SearchScope.quran,
            enabled: quranCount > 0,
            onSelected: () => _selectScope(_SearchScope.quran),
          ),
          _ScopeChip(
            label: 'Hadith ($hadithCount)',
            selected: _scope == _SearchScope.hadith,
            enabled: hadithCount > 0,
            onSelected: () => _selectScope(_SearchScope.hadith),
          ),
        ],
      ),
    );
  }

  /// Builds the grouped results list (Quran first, then Hadith).
  Widget _buildResultsList() {
    final showQuran = _scope != _SearchScope.hadith && _quranResults.isNotEmpty;
    final showHadith =
        _scope != _SearchScope.quran && _hadithResults.isNotEmpty;
    final quranCount = showQuran ? _quranResults.length : 0;
    final hadithCount = showHadith ? _hadithResults.length : 0;
    final grouped = _scope == _SearchScope.all;
    final quranHeader = showQuran && grouped ? 1 : 0;
    final hadithHeader = showHadith && grouped ? 1 : 0;
    final itemCount = quranHeader + quranCount + hadithHeader + hadithCount;

    return ListView.builder(
      key: ValueKey(_scope),
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.list,
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        var cursor = index;
        if (quranHeader == 1) {
          if (cursor == 0) {
            return const SectionHeader('Quran', icon: Icons.menu_book_rounded);
          }
          cursor--;
        }
        if (showQuran && cursor < quranCount) {
          return _QuranResultTile(
            hit: _quranResults[cursor],
            query: _activeQuery,
          );
        }
        if (showQuran) cursor -= quranCount;
        if (hadithHeader == 1) {
          if (cursor == 0) {
            return const SectionHeader(
              'Hadith',
              icon: Icons.library_books_rounded,
            );
          }
          cursor--;
        }
        if (showHadith && cursor < hadithCount) {
          return _HadithResultTile(
            hit: _hadithResults[cursor],
            query: _activeQuery,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: enabled ? (_) => onSelected() : null,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Private result tiles
// ────────────────────────────────────────────────────────────────

/// A search-result tile for a hadith match.
class _HadithResultTile extends StatelessWidget {
  final HadithSearchHit hit;
  final String query;

  const _HadithResultTile({required this.hit, required this.query});

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
                  HighlightedSnippet(
                    hit.snippet!,
                    query: query,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
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
  final String query;

  const _QuranResultTile({required this.hit, required this.query});

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
                if (hit.arabicSnippet != null &&
                    hit.arabicSnippet!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ArabicText(
                    hit.arabicSnippet!,
                    tajweed: false,
                    fontSize: 18,
                    maxLines: 2,
                    highlightQuery: query,
                  ),
                ],
                if (hit.snippet != null && hit.snippet!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  HighlightedSnippet(
                    hit.snippet!,
                    query: query,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
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
