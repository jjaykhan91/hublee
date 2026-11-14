/// Displays saved ayahs, notes, hadiths, and Quranic words.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router_paths.dart';
import '../services/bookmark_scope.dart';
import '../services/bookmark_service.dart';
import '../services/vocab_scope.dart';
import '../services/vocab_service.dart';
import '../theme/app_tokens.dart';
import 'widgets/fade_slide_in.dart';
import 'widgets/arabic_text.dart';
import 'widgets/note_sheet.dart';

/// Bookmarks tab: shows all saved items or an empty-state message.
class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkScope.of(context);
    final vocab = VocabScope.of(context);
    final bookmarks = bookmarkService.bookmarks;
    final ayahs = bookmarks.where((b) => b.type == 'quran').toList();
    final hadiths = bookmarks.where((b) => b.type == 'hadith').toList();
    final notes = bookmarkService.notes;
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ayahs'),
              Tab(text: 'Notes'),
              Tab(text: 'Hadith'),
              Tab(text: 'Words'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ayahs.isEmpty
                ? _empty(
                    context,
                    colorScheme,
                    icon: Icons.menu_book_outlined,
                    title: 'No saved ayahs yet',
                    subtitle:
                        'Tap the bookmark icon on any ayah to save it here',
                  )
                : _buildBookmarkList(
                    context,
                    bookmarkService,
                    ayahs,
                    colorScheme,
                  ),
            notes.isEmpty
                ? _empty(
                    context,
                    colorScheme,
                    icon: Icons.sticky_note_2_outlined,
                    title: 'No notes yet',
                    subtitle:
                        'Tap the note icon on an ayah or hadith to write one',
                  )
                : _noteList(context, bookmarkService, notes, colorScheme),
            hadiths.isEmpty
                ? _empty(
                    context,
                    colorScheme,
                    icon: Icons.library_books_outlined,
                    title: 'No saved hadiths yet',
                    subtitle: 'Bookmark a hadith while reading to save it here',
                  )
                : _buildBookmarkList(
                    context,
                    bookmarkService,
                    hadiths,
                    colorScheme,
                  ),
            vocab.entries.isEmpty
                ? _empty(
                    context,
                    colorScheme,
                    icon: Icons.star_outline_rounded,
                    title: 'No saved words yet',
                    subtitle:
                        'Turn on word-by-word, tap a word, and star it to learn it',
                  )
                : _wordList(context, vocab, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _empty(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of bookmark cards.
  Widget _buildBookmarkList(
    BuildContext context,
    BookmarkService bookmarkService,
    List<Bookmark> bookmarks,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        final isQuran = bookmark.type == 'quran';
        final badgeColor = isQuran
            ? AppColors.verseOfDayTint
            : AppColors.hadithOfDayTint;

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
          onDismissed: (_) =>
              _removeWithUndo(context, bookmarkService, bookmark, index),
          child: Card(
            child: ListTile(
              leading: Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
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
                    : _hadithTitle(bookmark),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                    onPressed: () => _removeWithUndo(
                      context,
                      bookmarkService,
                      bookmark,
                      index,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _navigateToBookmark(context, bookmark, isQuran),
            ),
          ),
        ).entrance(index: index, axis: Axis.horizontal);
      },
    );
  }

  Widget _noteList(
    BuildContext context,
    BookmarkService bookmarkService,
    List<ReadingNote> notes,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        final target = note.target;
        final isQuran = target.type == 'quran';
        final title = isQuran
            ? '${target.surahName} ${target.surahId}:${target.ayah}'
            : _hadithTitle(target);
        return Dismissible(
          key: ValueKey('note-${note.id}'),
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
          onDismissed: (_) =>
              _removeNoteWithUndo(context, bookmarkService, note),
          child: Card(
            child: ListTile(
              key: Key('saved-${note.id}'),
              leading: Icon(
                isQuran ? Icons.menu_book_rounded : Icons.library_books_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                note.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Edit note',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showNoteSheet(
                  context,
                  service: bookmarkService,
                  target: target,
                  title: title,
                ),
              ),
              onTap: () => _navigateToBookmark(context, target, isQuran),
            ),
          ),
        );
      },
    );
  }

  void _removeNoteWithUndo(
    BuildContext context,
    BookmarkService bookmarkService,
    ReadingNote note,
  ) {
    bookmarkService.deleteNote(note.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => bookmarkService.restoreNote(note),
        ),
      ),
    );
  }

  Widget _wordList(
    BuildContext context,
    VocabService vocab,
    ColorScheme colorScheme,
  ) {
    final entries = vocab.entries;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      scrollCacheExtent: AppSpacing.listCache,
      addAutomaticKeepAlives: false,
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: ValueKey(entry.id),
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
          onDismissed: (_) => _removeWordWithUndo(context, vocab, entry, index),
          child: Card(
            child: ListTile(
              title: ArabicText(
                entry.arabic,
                tajweed: false,
                fontSize: 22,
                weight: FontWeight.w700,
              ),
              subtitle: Text(
                '${entry.gloss} · ${entry.surahName} ${entry.surahId}:${entry.ayah}',
              ),
              trailing: IconButton(
                tooltip: 'Remove from learning list',
                icon: Icon(Icons.star_rounded, color: colorScheme.primary),
                onPressed: () =>
                    _removeWordWithUndo(context, vocab, entry, index),
              ),
              onTap: () =>
                  context.push(AppRoute.surah(entry.surahId, ayah: entry.ayah)),
            ),
          ),
        );
      },
    );
  }

  void _removeWordWithUndo(
    BuildContext context,
    VocabService vocab,
    VocabEntry entry,
    int index,
  ) {
    vocab.remove(entry.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Word removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => vocab.restore(entry, index: index),
        ),
      ),
    );
  }

  /// Removes [bookmark] and offers an Undo snackbar.
  void _removeWithUndo(
    BuildContext context,
    BookmarkService bookmarkService,
    Bookmark bookmark,
    int index,
  ) {
    bookmarkService.removeBookmark(bookmark.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Bookmark removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            bookmarkService.restoreBookmark(bookmark, index: index);
          },
        ),
      ),
    );
  }

  String _hadithTitle(Bookmark bookmark) {
    final book = bookmark.bookTitle ?? 'Hadith';
    final index = bookmark.hadithIndex;
    if (index != null) return hadithNoteTitle(book, index, bookmark.idInBook);
    if (bookmark.idInBook != null) return '$book · #${bookmark.idInBook}';
    return book;
  }

  /// Routes the user to the bookmarked ayah or hadith.
  void _navigateToBookmark(
    BuildContext context,
    Bookmark bookmark,
    bool isQuran,
  ) {
    if (isQuran) {
      context.push(AppRoute.surah(bookmark.surahId!, ayah: bookmark.ayah));
    } else {
      context.push(
        AppRoute.hadithBook(
          collectionId: bookmark.collectionId!,
          bookFile: bookmark.bookFile!,
          bookTitle: bookmark.bookTitle ?? '',
          index: bookmark.hadithIndex,
        ),
      );
    }
  }
}
