/// Displays the user's saved bookmarks for Quran ayahs and Hadith
/// entries.
///
/// Supports swipe-to-delete via [Dismissible] and one-tap
/// navigation back to the bookmarked content.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/bookmark_scope.dart';

/// Bookmarks tab: shows all saved items or an empty-state message.
class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkScope.of(context);
    final bookmarks = bookmarkService.bookmarks;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarks.isEmpty
          ? _buildEmptyState(context, colorScheme)
          : _buildBookmarkList(
              context, bookmarkService, bookmarks, colorScheme),
    );
  }

  /// Shown when no bookmarks exist yet.
  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline_rounded,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Long-press any ayah or hadith to bookmark it',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of bookmark cards.
  Widget _buildBookmarkList(
    BuildContext context,
    dynamic bookmarkService,
    List bookmarks,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        final isQuran = bookmark.type == 'quran';

        return Dismissible(
          key: ValueKey(bookmark.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
            ),
          ),
          onDismissed: (_) => bookmarkService.removeBookmark(bookmark.id),
          child: Card(
            child: ListTile(
              leading: Icon(
                isQuran ? Icons.menu_book_rounded : Icons.library_books_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                isQuran
                    ? '${bookmark.surahName} - Ayah ${bookmark.ayah}'
                    : '${bookmark.bookTitle}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: bookmark.snippet != null
                  ? Text(
                      bookmark.snippet!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Text(
                      isQuran ? 'Quran' : 'Hadith',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToBookmark(
                context,
                bookmark,
                isQuran,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Routes the user to the bookmarked ayah or hadith.
  void _navigateToBookmark(
    BuildContext context,
    dynamic bookmark,
    bool isQuran,
  ) {
    if (isQuran) {
      context.push(
        '/quran/${bookmark.surahId}?ayah=${bookmark.ayah}',
      );
    } else {
      context.push(
        '/hadith/${bookmark.collectionId}/${bookmark.bookFile}'
        '?title=${Uri.encodeComponent(bookmark.bookTitle ?? '')}'
        '&index=${bookmark.hadithIndex}',
      );
    }
  }
}
