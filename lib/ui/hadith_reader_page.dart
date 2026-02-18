/// Full-screen reading view for a single hadith book.
///
/// Displays each hadith with its number, optional narrator,
/// Arabic text (no tajweed), English translation, and a bookmark
/// toggle. Supports scroll-to-index and in-book search.
library;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../hadith/hadith_repository.dart';
import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import 'widgets/arabic_text.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/scroll_scrubber.dart';

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithBook>(
      future: _bookFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final errorMessage =
            snapshot.hasError ? snapshot.error.toString() : null;
        final book = snapshot.data;

        return Scaffold(
          appBar: _isSearching
              ? _buildSearchAppBar(context)
              : _buildNormalAppBar(context, book),
          body: () {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
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
      title: Text(book?.title ?? widget.title),
      actions: [
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
  Widget _buildSearchResults(
    BuildContext context,
    HadithBook book,
  ) {
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching hadiths found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                  bookmarkService.toggleBookmark(
                    Bookmark.hadith(
                      collectionId: widget.collectionId,
                      bookFile: widget.bookFile,
                      bookTitle:
                          book.title.isNotEmpty ? book.title : widget.title,
                      hadithIndex: hadithIndex,
                      snippet: hadith.english,
                    ),
                  );
                },
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

    // Persist last-read position only once.
    if (!_hasPersistedLastRead) {
      _hasPersistedLastRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        BookmarkScope.of(context).saveLastReadHadith(
          collectionId: widget.collectionId,
          bookFile: widget.bookFile,
          bookTitle: book.title.isNotEmpty ? book.title : widget.title,
          hadithIndex: widget.scrollToIndex ?? 0,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: hadiths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hadith = hadiths[index];
        final bookmarkId =
            'hadith:${widget.collectionId}:${widget.bookFile}:$index';
        final isBookmarked = bookmarkService.isBookmarked(bookmarkId);
        final colorScheme = Theme.of(context).colorScheme;

        return _HadithCard(
          hadith: hadith,
          displayIndex: index + 1,
          colorScheme: colorScheme,
          arabicZoom: settings.arabicZoom,
          englishZoom: settings.englishZoom,
          isBookmarked: isBookmarked,
          onBookmarkToggle: () {
            bookmarkService.toggleBookmark(
              Bookmark.hadith(
                collectionId: widget.collectionId,
                bookFile: widget.bookFile,
                bookTitle: book.title.isNotEmpty ? book.title : widget.title,
                hadithIndex: index,
                snippet: hadith.english,
              ),
            );
          },
        );
      },
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

  const _HadithCard({
    required this.hadith,
    required this.displayIndex,
    required this.colorScheme,
    required this.arabicZoom,
    required this.englishZoom,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: hadith number badge + bookmark icon
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
                  visualDensity: VisualDensity.compact,
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Narrator (isnad) label
            if (hadith.narrator?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
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

            // Arabic text (no tajweed for hadith)
            if (hadith.arabic?.isNotEmpty == true)
              ArabicText(
                hadith.arabic!,
                fontSize: 34 * arabicZoom,
                weight: FontWeight.w800,
                tajweed: false,
              ),
            if (hadith.arabic?.isNotEmpty == true) const SizedBox(height: 14),

            // English translation
            if (hadith.english?.isNotEmpty == true)
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
    );
  }
}
