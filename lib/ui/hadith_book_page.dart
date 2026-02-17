/// Full-screen reading view for a single hadith book.
///
/// Displays each hadith with its number, optional narrator,
/// Arabic text (no tajweed), English translation, and a bookmark
/// toggle. Supports scroll-to-index via query parameter.
library;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../hadith/hadith_repository.dart';
import '../services/settings_scope.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import 'widgets/arabic_text.dart';

/// Loads and renders all hadiths within a single book.
class HadithBookPage extends StatefulWidget {
  /// Collection directory ID (e.g. `"forties"`).
  final String collectionId;

  /// JSON filename of the book (e.g. `"nawawi40.json"`).
  final String bookFile;

  /// Human-readable book title for the app bar.
  final String title;

  /// If provided, the list auto-scrolls to this zero-based index.
  final int? scrollToIndex;

  const HadithBookPage({
    super.key,
    required this.collectionId,
    required this.bookFile,
    required this.title,
    this.scrollToIndex,
  });

  @override
  State<HadithBookPage> createState() => _HadithBookPageState();
}

class _HadithBookPageState extends State<HadithBookPage> {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final repository = const HadithRepository();

    return FutureBuilder<HadithBook>(
      future: repository.loadBook(
        widget.collectionId,
        widget.bookFile,
      ),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final errorMessage =
            snapshot.hasError ? snapshot.error.toString() : null;
        final book = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(book?.title ?? widget.title),
          ),
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
            return _buildHadithList(context, book!);
          }(),
        );
      },
    );
  }

  /// Builds the scrollable hadith list with auto-scroll support.
  Widget _buildHadithList(BuildContext context, HadithBook book) {
    final hadiths = book.hadiths;

    // Persist this position as last-read.
    _saveLastReadPosition(book);

    // Auto-scroll to the requested index after the frame renders.
    if (widget.scrollToIndex != null) {
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

  /// Records this book as the user's last-read hadith position.
  void _saveLastReadPosition(HadithBook book) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BookmarkScope.of(context).saveLastReadHadith(
        collectionId: widget.collectionId,
        bookFile: widget.bookFile,
        bookTitle: book.title.isNotEmpty ? book.title : widget.title,
        hadithIndex: widget.scrollToIndex ?? 0,
      );
    });
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
