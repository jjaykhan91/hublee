/// Hadith tab: searchable catalog with collection chips, continue
/// reading, and a short-collection on-ramp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_book_summaries.dart';
import '../hadith/hadith_repository.dart';
import '../router_paths.dart';
import '../services/bookmark_scope.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_haptics.dart';
import 'widgets/hublee_card.dart';

Color _accentFor(ColorScheme colors, String collectionId) {
  return switch (collectionId) {
    'forties' => colors.primary,
    'the_9_books' => colors.secondary,
    _ => colors.tertiary,
  };
}

IconData _iconFor(String collectionId) {
  return switch (collectionId) {
    'forties' => Icons.looks_4_rounded,
    'the_9_books' => Icons.library_books_rounded,
    _ => Icons.auto_stories_rounded,
  };
}

String _shortLabel(HadithBookMeta book) {
  final file = book.file.toLowerCase();
  if (file.contains('nawawi')) return 'Nawawi';
  if (file.contains('qudsi')) return 'Qudsi';
  if (file.contains('waliullah') || file.contains('shahwali')) {
    return 'Waliullah';
  }
  final words = book.title.split(RegExp(r'\s+'));
  return words.take(2).join(' ');
}

String? _featuredBlurb(HadithBookMeta book) {
  final file = book.file.toLowerCase();
  if (file.contains('nawawi')) return 'Faith, worship, ethics';
  if (file.contains('qudsi')) return 'Sacred sayings';
  if (file.contains('waliullah') || file.contains('shahwali')) {
    return 'Everyday Sunnah';
  }
  return null;
}

void _openBook(
  BuildContext context, {
  required String collectionId,
  required HadithBookMeta book,
  int? index,
}) {
  if (index != null) {
    context.push(
      AppRoute.hadithBook(
        collectionId: collectionId,
        bookFile: book.file,
        bookTitle: book.title,
        index: index,
      ),
    );
    return;
  }
  context.push(
    AppRoute.hadithChapters(
      collectionId: collectionId,
      bookFile: book.file,
      bookTitle: book.title,
    ),
  );
}

/// Main Hadith tab: chips, search, continue, featured, compact books.
class HadithPage extends StatefulWidget {
  const HadithPage({super.key});

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  late final Future<List<_HadithRow>> _dataFuture;
  String? _collectionId;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_HadithRow>> _loadAllBooks() async {
    final repository = const HadithRepository();
    final collections = await repository.loadCollections();
    final rows = <_HadithRow>[];
    var animIndex = 0;

    for (final collection in collections) {
      try {
        final books = await repository.loadBooksForCollection(collection.id);
        var hadithTotal = 0;
        for (final book in books) {
          hadithTotal += book.length ?? 0;
        }
        rows.add(
          _HadithHeaderRow(
            collectionId: collection.id,
            title: collection.title,
            bookCount: books.length,
            hadithCount: hadithTotal == 0 ? null : hadithTotal,
          ),
        );
        var bookIndex = 0;
        for (final book in books) {
          bookIndex++;
          final fileBaseName = book.file.split('/').last.split('.').first;
          rows.add(
            _HadithBookRow(
              book: book,
              collectionId: collection.id,
              collectionTitle: collection.title,
              summary: hadithBookSummary(
                title: book.title,
                fileBaseName: fileBaseName,
              ),
              indexInCollection: bookIndex,
              animIndex: animIndex,
            ),
          );
          animIndex++;
        }
      } catch (_) {
        // Skip collections with missing index files.
      }
    }
    return rows;
  }

  List<_HadithRow> _visibleRows(List<_HadithRow> rows) {
    final needle = _query.trim().toLowerCase();
    final out = <_HadithRow>[];
    _HadithHeaderRow? pendingHeader;
    for (final row in rows) {
      switch (row) {
        case _HadithHeaderRow():
          pendingHeader = row;
        case _HadithBookRow():
          final collectionOk =
              _collectionId == null || row.collectionId == _collectionId;
          final queryOk =
              needle.isEmpty ||
              row.book.title.toLowerCase().contains(needle) ||
              (row.summary?.toLowerCase().contains(needle) ?? false);
          if (!collectionOk || !queryOk) continue;
          if (pendingHeader != null &&
              pendingHeader.collectionId == row.collectionId) {
            out.add(pendingHeader);
            pendingHeader = null;
          }
          out.add(row);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hadith')),
      body: FutureBuilder<List<_HadithRow>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('No hadith books found.'));
          }

          final collections = rows.whereType<_HadithHeaderRow>().toList();
          final visible = _visibleRows(rows);
          final featured = rows
              .whereType<_HadithBookRow>()
              .where((row) => row.collectionId == 'forties')
              .take(3)
              .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Find a book',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                  onChanged: (value) => setState(() => _query = value),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest,
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              _CollectionChips(
                collections: collections,
                selectedId: _collectionId,
                onSelected: (id) => setState(() => _collectionId = id),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          'No books match that filter',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                        ),
                      )
                    : _buildBookList(visible: visible, featured: featured),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookList({
    required List<_HadithRow> visible,
    required List<_HadithBookRow> featured,
  }) {
    final bookmarks = BookmarkScope.maybeOf(context);
    final lastRead = bookmarks?.lastReadHadith;
    final savedKeys = <String>{
      if (bookmarks != null)
        for (final bookmark in bookmarks.bookmarks)
          if (bookmark.type == 'hadith')
            '${bookmark.collectionId}|${bookmark.bookFile}',
    };
    final showContinue = lastRead != null;
    final showFeatured =
        _collectionId == null && _query.trim().isEmpty && featured.isNotEmpty;
    final extra = (showContinue ? 1 : 0) + (showFeatured ? 1 : 0);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: visible.length + extra,
      itemBuilder: (context, index) {
        var cursor = index;
        if (showContinue) {
          if (cursor == 0) {
            return _ContinueCard(lastRead: lastRead);
          }
          cursor--;
        }
        if (showFeatured) {
          if (cursor == 0) {
            return _StartHereRow(books: featured);
          }
          cursor--;
        }
        final row = visible[cursor];
        return switch (row) {
          _HadithHeaderRow(
            :final collectionId,
            :final title,
            :final bookCount,
            :final hadithCount,
          ) =>
            _CollectionHeader(
              collectionId: collectionId,
              title: title,
              bookCount: bookCount,
              hadithCount: hadithCount,
            ),
          _HadithBookRow(
            :final book,
            :final collectionId,
            :final collectionTitle,
            :final summary,
            :final indexInCollection,
            :final animIndex,
          ) =>
            _animateBookTile(
              animIndex,
              _BookTile(
                book: book,
                collectionId: collectionId,
                collectionTitle: collectionTitle,
                summary: summary,
                indexInCollection: indexInCollection,
                isSaved: savedKeys.contains('$collectionId|${book.file}'),
                resumeIndex:
                    lastRead != null &&
                        lastRead['collectionId'] == collectionId &&
                        lastRead['bookFile'] == book.file
                    ? lastRead['hadithIndex'] as int?
                    : null,
              ),
            ),
        };
      },
    );
  }

  Widget _animateBookTile(int animIndex, Widget tile) {
    if (animIndex >= 25) return tile;
    final delay = (30 * animIndex).clamp(0, 600);
    return tile
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideX(
          begin: 0.03,
          end: 0,
          duration: 400.ms,
          delay: delay.ms,
          curve: Curves.easeOut,
        );
  }
}

sealed class _HadithRow {
  const _HadithRow();
}

class _HadithHeaderRow extends _HadithRow {
  final String collectionId;
  final String title;
  final int bookCount;
  final int? hadithCount;

  const _HadithHeaderRow({
    required this.collectionId,
    required this.title,
    required this.bookCount,
    this.hadithCount,
  });
}

class _HadithBookRow extends _HadithRow {
  final HadithBookMeta book;
  final String collectionId;
  final String collectionTitle;
  final String? summary;
  final int indexInCollection;
  final int animIndex;

  const _HadithBookRow({
    required this.book,
    required this.collectionId,
    required this.collectionTitle,
    required this.summary,
    required this.indexInCollection,
    required this.animIndex,
  });
}

class _CollectionChips extends StatelessWidget {
  const _CollectionChips({
    required this.collections,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_HadithHeaderRow> collections;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedId == null,
              showCheckmark: false,
              onSelected: (_) {
                AppHaptics.selection();
                onSelected(null);
              },
            ),
          ),
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(collection.title),
                selected: selectedId == collection.collectionId,
                showCheckmark: false,
                onSelected: (_) {
                  AppHaptics.selection();
                  onSelected(
                    selectedId == collection.collectionId
                        ? null
                        : collection.collectionId,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lastRead});

  final Map<String, dynamic> lastRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = lastRead['bookTitle'] as String? ?? 'Hadith';
    final index = lastRead['hadithIndex'] as int? ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HubleeCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          context.push(
            AppRoute.hadithBook(
              collectionId: lastRead['collectionId'] as String,
              bookFile: lastRead['bookFile'] as String,
              bookTitle: title,
              index: index,
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: AppRadius.chip,
              ),
              child: Icon(
                Icons.play_circle_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue reading',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$title · Hadith ${index + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _StartHereRow extends StatelessWidget {
  const _StartHereRow({required this.books});

  final List<_HadithBookRow> books;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start here',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '40-hadith collections',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final row = books[index];
                return _FeaturedBookCard(row: row);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBookCard extends StatelessWidget {
  const _FeaturedBookCard({required this.row});

  final _HadithBookRow row;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(colorScheme, row.collectionId);
    final blurb = _featuredBlurb(row.book);
    final count = row.book.length;

    return SizedBox(
      width: 148,
      child: HubleeCard(
        padding: const EdgeInsets.all(12),
        onTap: () =>
            _openBook(context, collectionId: row.collectionId, book: row.book),
        onLongPress: row.summary == null
            ? null
            : () => _showBookAbout(
                context,
                book: row.book,
                collectionId: row.collectionId,
                collectionTitle: row.collectionTitle,
                summary: row.summary,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: AppRadius.badge,
              ),
              child: Icon(_iconFor(row.collectionId), color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              _shortLabel(row.book),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              count == null ? row.collectionTitle : '$count hadith',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (blurb != null) ...[
              const SizedBox(height: 4),
              Text(
                blurb,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  final String collectionId;
  final String title;
  final int bookCount;
  final int? hadithCount;

  const _CollectionHeader({
    required this.collectionId,
    required this.title,
    required this.bookCount,
    this.hadithCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(colorScheme, collectionId);
    final countLabel = hadithCount == null
        ? '$bookCount books'
        : '$bookCount books · $hadithCount hadith';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(collectionId), size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          Text(
            countLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final HadithBookMeta book;
  final String collectionId;
  final String collectionTitle;
  final String? summary;
  final int indexInCollection;
  final bool isSaved;
  final int? resumeIndex;

  const _BookTile({
    required this.book,
    required this.collectionId,
    required this.collectionTitle,
    this.summary,
    required this.indexInCollection,
    required this.isSaved,
    this.resumeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentFor(colorScheme, collectionId);
    final count = book.length;
    final semantics = [
      book.title,
      if (count != null) '$count hadith',
      collectionTitle,
      if (isSaved) 'bookmarked',
      if (resumeIndex != null) 'resume at hadith ${resumeIndex! + 1}',
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: semantics,
        child: HubleeCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          onTap: () =>
              _openBook(context, collectionId: collectionId, book: book),
          onLongPress: summary == null
              ? null
              : () => _showBookAbout(
                  context,
                  book: book,
                  collectionId: collectionId,
                  collectionTitle: collectionTitle,
                  summary: summary,
                  resumeIndex: resumeIndex,
                ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.badge,
                  ),
                  child: Text(
                    '$indexInCollection',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            count == null ? collectionTitle : '$count hadith',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          if (resumeIndex != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: AppRadius.badge,
                              ),
                              child: Text(
                                'Resume · ${resumeIndex! + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (isSaved)
                            Icon(
                              Icons.bookmark_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (summary != null)
                  IconButton(
                    tooltip: 'About this book',
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: () => _showBookAbout(
                      context,
                      book: book,
                      collectionId: collectionId,
                      collectionTitle: collectionTitle,
                      summary: summary,
                      resumeIndex: resumeIndex,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showBookAbout(
  BuildContext context, {
  required HadithBookMeta book,
  required String collectionId,
  required String collectionTitle,
  String? summary,
  int? resumeIndex,
}) {
  AppHaptics.selection();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                book.title,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (book.length != null) '${book.length} hadith',
                  collectionTitle,
                ].join(' · '),
                style: Theme.of(sheetContext).textTheme.labelMedium?.copyWith(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openBook(context, collectionId: collectionId, book: book);
                },
                child: const Text('Open book'),
              ),
              if (resumeIndex != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openBook(
                      context,
                      collectionId: collectionId,
                      book: book,
                      index: resumeIndex,
                    );
                  },
                  child: Text('Continue at hadith ${resumeIndex + 1}'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
