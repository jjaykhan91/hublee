/// Full-screen reading view for a single hadith book.
///
/// Displays each hadith with its number, optional narrator,
/// Arabic text (no tajweed), English translation, and a bookmark
/// toggle. Supports scroll-to-index, chapter jump, and in-book search.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../hadith/hadith_chapters.dart';
import '../hadith/hadith_repository.dart';
import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';
import 'widgets/hadith_chapter_sheet.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/scroll_scrubber.dart';
import 'widgets/passage_actions.dart';
import 'widgets/reading_width.dart';

/// Loads and renders all hadiths within a single book.
class HadithReaderPage extends StatefulWidget {
  /// Collection directory ID (e.g. `"forties"`).
  final String collectionId;

  /// JSON filename of the book (e.g. `"nawawi40.json"`).
  final String bookFile;

  /// Human-readable book title for the app bar.
  final String title;

  /// If provided, the list auto-scrolls to this zero-based index.
  final int? scrollToIndex;

  const HadithReaderPage({
    super.key,
    required this.collectionId,
    required this.bookFile,
    required this.title,
    this.scrollToIndex,
  });

  @override
  State<HadithReaderPage> createState() => _HadithReaderPageState();
}

class _HadithReaderPageState extends State<HadithReaderPage> {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  /// Cached future so rebuilds don't re-fetch data.
  late final Future<HadithBook> _bookFuture;

  /// Ensures last-read is saved only once per page visit.
  bool _hasPersistedLastRead = false;

  /// Ensures scroll-to-index fires only once.
  bool _hasScrolledToIndex = false;

  Timer? _lastReadTimer;
  BookmarkService? _bookmarks;
  String? _bookTitle;
  int? _visibleIndex;

  // ── In-book search state ───────────────────────────────────
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _bookFuture = const HadithRepository().loadBook(
      widget.collectionId,
      widget.bookFile,
    );
    _positionsListener.itemPositions.addListener(_onScrollPositions);
  }

  void _onScrollPositions() {
    if (!mounted || _isSearching || _bookTitle == null) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final visible = positions.where(
      (position) =>
          position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
    );
    if (visible.isEmpty) return;
    final top = visible.reduce(
      (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
    );
    if (_visibleIndex == top.index) return;
    _visibleIndex = top.index;
    _lastReadTimer?.cancel();
    _lastReadTimer = Timer(const Duration(milliseconds: 400), () {
      final index = _visibleIndex;
      final title = _bookTitle;
      if (index == null || title == null) return;
      _bookmarks?.saveLastReadHadith(
        collectionId: widget.collectionId,
        bookFile: widget.bookFile,
        bookTitle: title,
        hadithIndex: index,
        notify: false,
      );
    });
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScrollPositions);
    _lastReadTimer?.cancel();
    final title = _bookTitle;
    final index = _visibleIndex ?? widget.scrollToIndex ?? 0;
    if (title != null) {
      _bookmarks?.saveLastReadHadith(
        collectionId: widget.collectionId,
        bookFile: widget.bookFile,
        bookTitle: title,
        hadithIndex: index,
      );
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Opens the in-book search bar.
  void _openSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.requestFocus();
  }

  /// Closes the in-book search bar and shows all hadiths.
  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _showChapters(HadithBook book) {
    showHadithChapterSheet(
      context: context,
      chapters: book.chapters,
      hadiths: book.hadiths,
      onJump: (index) {
        if (!_scrollController.isAttached) return;
        _scrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 280),
          alignment: 0.08,
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithBook>(
      future: _bookFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final errorMessage = snapshot.hasError
            ? snapshot.error.toString()
            : null;
        final book = snapshot.data;

        return Scaffold(
          appBar: _isSearching
              ? _buildSearchAppBar(context)
              : _buildNormalAppBar(context, book),
          body: ConstrainedReadingBody(
            child: () {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $errorMessage'),
                );
              }

              if (_isSearching && _searchQuery.isNotEmpty) {
                return _buildSearchResults(context, book!);
              }

              final loadedBook = book!;
              return Stack(
                children: [
                  _buildHadithList(context, loadedBook),
                  ScrollScrubber(
                    itemCount: loadedBook.hadiths.length,
                    labelBuilder: (index) =>
                        'Hadith ${index + 1} of ${loadedBook.hadiths.length}',
                    scrollController: _scrollController,
                    positionsListener: _positionsListener,
                  ),
                ],
              );
            }(),
          ),
        );
      },
    );
  }

  /// Normal app bar with title and search icon.
  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    HadithBook? book,
  ) {
    return AppBar(
      title: Text(
        book?.title ?? widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (book != null && book.chapters.length > 1)
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Chapters',
            onPressed: () => _showChapters(book),
          ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search in this book',
          onPressed: _openSearch,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Reader settings',
          onPressed: () => showReaderSettingsSheet(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Search app bar with text field and close button.
  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search in this book\u2026',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
      ],
    );
  }

  /// Shows filtered hadith results matching the search query.
  Widget _buildSearchResults(BuildContext context, HadithBook book) {
    final queryLower = _searchQuery.toLowerCase();
    final settings = SettingsScope.of(context);
    final bookmarkService = BookmarkScope.of(context);

    // Find matching hadith indices (0-based).
    final matches = <int>[];
    for (var i = 0; i < book.hadiths.length; i++) {
      final hadith = book.hadiths[i];
      final english = (hadith.english ?? '').toLowerCase();
      final arabic = hadith.arabic ?? '';
      final narrator = (hadith.narrator ?? '').toLowerCase();
      if (english.contains(queryLower) ||
          arabic.contains(_searchQuery) ||
          narrator.contains(queryLower)) {
        matches.add(i);
      }
    }

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching hadiths found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match count header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            '${matches.length} result${matches.length == 1 ? '' : 's'} found',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Matching hadiths list
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final hadithIndex = matches[index];
              final hadith = book.hadiths[hadithIndex];
              final bookmarkId =
                  'hadith:${widget.collectionId}:${widget.bookFile}:$hadithIndex';
              final isBookmarked = bookmarkService.isBookmarked(bookmarkId);
              final colorScheme = Theme.of(context).colorScheme;

              return _HadithCard(
                hadith: hadith,
                displayIndex: hadithIndex + 1,
                colorScheme: colorScheme,
                arabicZoom: settings.arabicZoom,
                englishZoom: settings.englishZoom,
                isBookmarked: isBookmarked,
                onBookmarkToggle: () {
                  AppHaptics.lightImpact();
                  bookmarkService.toggleBookmark(
                    Bookmark.hadith(
                      collectionId: widget.collectionId,
                      bookFile: widget.bookFile,
                      bookTitle: book.title.isNotEmpty
                          ? book.title
                          : widget.title,
                      hadithIndex: hadithIndex,
                      snippet: hadith.english,
                    ),
                  );
                },
                bookTitle: book.title.isNotEmpty ? book.title : widget.title,
                showTranslation: settings.showTranslation,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable hadith list with auto-scroll support.
  Widget _buildHadithList(BuildContext context, HadithBook book) {
    final hadiths = book.hadiths;
    _bookTitle = book.title.isNotEmpty ? book.title : widget.title;
    _visibleIndex ??= widget.scrollToIndex ?? 0;
    _bookmarks = BookmarkScope.of(context);

    if (!_hasPersistedLastRead) {
      _hasPersistedLastRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bookmarks?.saveLastReadHadith(
          collectionId: widget.collectionId,
          bookFile: widget.bookFile,
          bookTitle: _bookTitle!,
          hadithIndex: _visibleIndex ?? 0,
          notify: false,
        );
      });
    }

    // Auto-scroll to the requested index only once.
    if (!_hasScrolledToIndex && widget.scrollToIndex != null) {
      _hasScrolledToIndex = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetIndex = widget.scrollToIndex!.clamp(0, hadiths.length - 1);
        if (_scrollController.isAttached) {
          _scrollController.jumpTo(index: targetIndex);
          _scrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 200),
            alignment: 0.08,
            curve: Curves.easeInOut,
          );
        }
      });
    }

    final settings = SettingsScope.of(context);
    final bookmarkService = BookmarkScope.of(context);

    return ScrollablePositionedList.separated(
      itemScrollController: _scrollController,
      itemPositionsListener: _positionsListener,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, ScrollScrubber.gutter, 24),
      minCacheExtent: AppSpacing.cacheExtent,
      itemCount: hadiths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hadith = hadiths[index];
        final bookmarkId =
            'hadith:${widget.collectionId}:${widget.bookFile}:$index';
        final isBookmarked = bookmarkService.isBookmarked(bookmarkId);
        final colorScheme = Theme.of(context).colorScheme;
        final chapter = isChapterStart(hadiths, index)
            ? chapterById(book.chapters, hadith.chapterId)
            : null;

        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (chapter != null) _HadithChapterDivider(chapter: chapter),
              _HadithCard(
                hadith: hadith,
                displayIndex: index + 1,
                colorScheme: colorScheme,
                arabicZoom: settings.arabicZoom,
                englishZoom: settings.englishZoom,
                isBookmarked: isBookmarked,
                onBookmarkToggle: () {
                  AppHaptics.lightImpact();
                  bookmarkService.toggleBookmark(
                    Bookmark.hadith(
                      collectionId: widget.collectionId,
                      bookFile: widget.bookFile,
                      bookTitle: book.title.isNotEmpty
                          ? book.title
                          : widget.title,
                      hadithIndex: index,
                      snippet: hadith.english,
                    ),
                  );
                },
                bookTitle: book.title.isNotEmpty ? book.title : widget.title,
                showTranslation: settings.showTranslation,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chapter heading shown above the first hadith of that chapter.
class _HadithChapterDivider extends StatelessWidget {
  final HadithChapter chapter;

  const _HadithChapterDivider({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final english = chapter.english?.trim();
    final arabic = chapter.arabic?.trim();
    final settings = SettingsScope.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (english != null && english.isNotEmpty)
            Text(
              english,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (arabic != null && arabic.isNotEmpty) ...[
            const SizedBox(height: 4),
            ArabicText(
              arabic,
              fontSize: 20 * settings.arabicZoom,
              color: colorScheme.primary,
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: colorScheme.outline.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// A single hadith card with number badge, narrator, Arabic text,
/// English translation, and bookmark toggle.
class _HadithCard extends StatelessWidget {
  final Hadith hadith;

  /// 1-based display number for the hadith.
  final int displayIndex;
  final ColorScheme colorScheme;
  final double arabicZoom;
  final double englishZoom;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final String bookTitle;
  final bool showTranslation;

  const _HadithCard({
    required this.hadith,
    required this.displayIndex,
    required this.colorScheme,
    required this.arabicZoom,
    required this.englishZoom,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.bookTitle,
    required this.showTranslation,
  });

  String get _reference => '$bookTitle, Hadith $displayIndex';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => showPassageActionsSheet(
          context,
          reference: _reference,
          arabic: hadith.arabic,
          english: hadith.english,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Hadith $displayIndex'
                      '${hadith.idInBook != null ? ' \u2022 #${hadith.idInBook}' : ''}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PassageActionsButton(
                    reference: _reference,
                    arabic: hadith.arabic,
                    english: hadith.english,
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isBookmarked
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 22,
                    ),
                    onPressed: onBookmarkToggle,
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (hadith.narrator?.isNotEmpty == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hadith.narrator!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (hadith.arabic?.isNotEmpty == true)
                ArabicText(
                  hadith.arabic!,
                  fontSize: 34 * arabicZoom,
                  weight: FontWeight.w800,
                  tajweed: false,
                ),
              if (hadith.arabic?.isNotEmpty == true) const SizedBox(height: 14),
              if (showTranslation && hadith.english?.isNotEmpty == true)
                Text(
                  hadith.english!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15 * englishZoom,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
