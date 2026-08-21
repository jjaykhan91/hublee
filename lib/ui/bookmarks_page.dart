/// Displays the user's saved bookmarks for Quran ayahs and Hadith
/// entries.
///
/// Supports swipe-to-delete via [Dismissible] and one-tap
/// navigation back to the bookmarked content.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
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
              context,
              bookmarkService,
              bookmarks,
              colorScheme,
            ),
    );
  }

  /// Shown when no bookmarks exist yet.
  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
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
            'Tap the bookmark icon on any ayah or hadith to save it',
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        final isQuran = bookmark.type == 'quran';
        final badgeColor = isQuran
            ? const Color(0xFF4338CA)
            : const Color(0xFF047857);

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
                child: Icon(Icons.delete_outline, color: colorScheme.error),
              ),
              onDismissed: (_) => bookmarkService.removeBookmark(bookmark.id),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          badgeColor.withValues(alpha: 0.15),
                          badgeColor.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isQuran
                          ? Icons.menu_book_rounded
                          : Icons.library_books_rounded,
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isQuran
                        ? '${bookmark.surahName} - Ayah ${bookmark.ayah}'
                        : '${bookmark.bookTitle}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_remove_rounded,
                          color: colorScheme.error,
                        ),
                        tooltip: 'Remove bookmark',
                        onPressed: () =>
                            bookmarkService.removeBookmark(bookmark.id),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _navigateToBookmark(context, bookmark, isQuran),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: (30 * index).clamp(0, 600).ms)
            .slideX(
              begin: 0.03,
              end: 0,
              duration: 400.ms,
              delay: (30 * index).clamp(0, 600).ms,
              curve: Curves.easeOut,
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
        AppRoute.surah(bookmark.surahId as int, ayah: bookmark.ayah as int?),
      );
    } else {
      context.push(
        AppRoute.hadithBook(
          collectionId: bookmark.collectionId as String,
          bookFile: bookmark.bookFile as String,
          bookTitle: bookmark.bookTitle as String? ?? '',
          index: bookmark.hadithIndex as int?,
        ),
      );
    }
  }
}
