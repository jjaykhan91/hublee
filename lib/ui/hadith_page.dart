/// Hadith tab: shows all books from all collections in a single
/// scrollable list, grouped by collection with section headers.
///
/// Tapping a book navigates directly to the [HadithReaderPage].
/// No intermediate collections grid — the user sees all available
/// books immediately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_book_summaries.dart';
import '../hadith/hadith_repository.dart';
import '../router_paths.dart';

/// Main Hadith tab displaying all hadith books grouped by
/// collection.
class HadithPage extends StatefulWidget {
  const HadithPage({super.key});

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  /// Cached future to avoid re-fetching on rebuild.
  late final Future<List<_HadithRow>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllBooks();
  }

  /// Loads all collections and flattens them into lazy-list rows.
  ///
  /// Summaries are resolved here so [_BookTile] never re-runs the
  /// string-matching table on every rebuild.
  Future<List<_HadithRow>> _loadAllBooks() async {
    final repository = const HadithRepository();
    final collections = await repository.loadCollections();
    final rows = <_HadithRow>[];
    var animIndex = 0;

    for (final collection in collections) {
      try {
        final books = await repository.loadBooksForCollection(collection.id);
        rows.add(
          _HadithHeaderRow(title: collection.title, bookCount: books.length),
        );
        for (final book in books) {
          final fileBaseName = book.file.split('/').last.split('.').first;
          rows.add(
            _HadithBookRow(
              book: book,
              collectionId: collection.id,
              summary: hadithBookSummary(
                title: book.title,
                fileBaseName: fileBaseName,
              ),
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

  @override
  Widget build(BuildContext context) {
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

          return _buildBookList(rows);
        },
      ),
    );
  }

  /// Lazy list of collection headers and book tiles.
  Widget _buildBookList(List<_HadithRow> rows) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          _HadithHeaderRow(:final title, :final bookCount) => _CollectionHeader(
            title: title,
            bookCount: bookCount,
          ),
          _HadithBookRow(
            :final book,
            :final collectionId,
            :final summary,
            :final animIndex,
          ) =>
            _animateBookTile(
              animIndex,
              _BookTile(
                book: book,
                collectionId: collectionId,
                summary: summary,
              ),
            ),
        };
      },
    );
  }

  /// Entry animation for the first screenful of tiles only.
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
  final String title;
  final int bookCount;

  const _HadithHeaderRow({required this.title, required this.bookCount});
}

class _HadithBookRow extends _HadithRow {
  final HadithBookMeta book;
  final String collectionId;
  final String? summary;
  final int animIndex;

  const _HadithBookRow({
    required this.book,
    required this.collectionId,
    required this.summary,
    required this.animIndex,
  });
}

/// Section header for a hadith collection group.
class _CollectionHeader extends StatelessWidget {
  final String title;
  final int bookCount;

  const _CollectionHeader({required this.title, required this.bookCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.tertiary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.collections_bookmark_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '$bookCount books',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single hadith book tile with title, subtitle, optional
/// summary, and navigation.
class _BookTile extends StatelessWidget {
  final HadithBookMeta book;
  final String collectionId;
  final String? summary;

  const _BookTile({
    required this.book,
    required this.collectionId,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build subtitle from hadith count + filename.
    final subtitleParts = <String>[];
    if (book.length != null) {
      subtitleParts.add('${book.length} hadith');
    }
    final fileBaseName = book.file.split('/').last.split('.').first;
    subtitleParts.add(fileBaseName);
    final subtitle = subtitleParts
        .where((part) => part.isNotEmpty)
        .join(' \u2022 ');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(
            AppRoute.hadithBook(
              collectionId: collectionId,
              bookFile: book.file,
              bookTitle: book.title,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.menu_book_outlined, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.9,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
