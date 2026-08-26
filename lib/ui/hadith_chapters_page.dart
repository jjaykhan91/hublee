/// Chapter picker shown after opening a hadith book.
///
/// Tiles are a numbered grid; tapping one opens that chapter's
/// hadiths rather than loading the whole book into the reader.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hadith/hadith_chapters.dart';
import '../hadith/hadith_repository.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_haptics.dart';
import 'widgets/arabic_text.dart';
import 'widgets/hublee_card.dart';
import 'widgets/reading_width.dart';

/// Loads a book's chapters and presents them as tappable tiles.
class HadithChaptersPage extends StatefulWidget {
  const HadithChaptersPage({
    super.key,
    required this.collectionId,
    required this.bookFile,
    required this.title,
  });

  final String collectionId;
  final String bookFile;
  final String title;

  @override
  State<HadithChaptersPage> createState() => _HadithChaptersPageState();
}

class _HadithChaptersPageState extends State<HadithChaptersPage> {
  late final Future<HadithBook> _bookFuture;
  final _searchController = TextEditingController();
  var _query = '';

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
    super.dispose();
  }

  void _openChapter(HadithBook book, HadithChapter chapter) {
    AppHaptics.selection();
    final first = firstHadithIndexForChapter(book.hadiths, chapter.id);
    context.push(
      AppRoute.hadithBook(
        collectionId: widget.collectionId,
        bookFile: widget.bookFile,
        bookTitle: book.title.isNotEmpty ? book.title : widget.title,
        chapterId: chapter.id,
        index: first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithBook>(
      future: _bookFuture,
      builder: (context, snapshot) {
        final book = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              book?.title ?? widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ConstrainedReadingBody(child: _body(context, snapshot)),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<HadithBook> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Padding(
        padding: AppSpacing.page,
        child: Text('Error: ${snapshot.error}'),
      );
    }

    final book = snapshot.data!;
    if (book.chapters.isEmpty) {
      return _EmptyChapters(
        onReadAll: () {
          AppHaptics.selection();
          context.push(
            AppRoute.hadithBook(
              collectionId: widget.collectionId,
              bookFile: widget.bookFile,
              bookTitle: book.title.isNotEmpty ? book.title : widget.title,
            ),
          );
        },
      );
    }

    final query = _query.trim().toLowerCase();
    final chapters = query.isEmpty
        ? book.chapters
        : book.chapters
              .where((chapter) {
                final english = (chapter.english ?? '').toLowerCase();
                final arabic = chapter.arabic ?? '';
                return english.contains(query) ||
                    arabic.contains(_query.trim());
              })
              .toList(growable: false);

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= ReadingLayout.railBreakpoint ? 3 : 2;

    return Column(
      children: [
        if (book.chapters.length > 8)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search chapters',
              leading: const Icon(Icons.search_rounded),
              onChanged: (value) => setState(() => _query = value),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${book.chapters.length} chapters',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        Expanded(
          child: chapters.isEmpty
              ? const Center(child: Text('No matching chapters'))
              : HadithChapterGrid(
                  chapters: chapters,
                  hadiths: book.hadiths,
                  onSelect: (chapter) => _openChapter(book, chapter),
                  crossAxisCount: columns,
                ),
        ),
      ],
    );
  }
}

/// Numbered chapter tiles. Public so tests can pump it without assets.
class HadithChapterGrid extends StatelessWidget {
  const HadithChapterGrid({
    super.key,
    required this.chapters,
    required this.hadiths,
    required this.onSelect,
    this.crossAxisCount = 2,
  });

  final List<HadithChapter> chapters;
  final List<Hadith> hadiths;
  final ValueChanged<HadithChapter> onSelect;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('hadith-chapter-grid'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final number = chapter.id ?? (index + 1);
        return _ChapterTile(
          number: number,
          chapter: chapter,
          hadithCount: hadithCountForChapter(hadiths, chapter.id),
          onTap: () => onSelect(chapter),
        );
      },
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  const _EmptyChapters({required this.onReadAll});

  final VoidCallback onReadAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This book has no chapter list.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onReadAll, child: const Text('Read book')),
          ],
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.number,
    required this.chapter,
    required this.hadithCount,
    required this.onTap,
  });

  final int number;
  final HadithChapter chapter;
  final int hadithCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final english = chapter.english?.trim();
    final arabic = chapter.arabic?.trim();

    return HubleeCard(
      key: Key('hadith-chapter-$number'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: AppRadius.badge,
                ),
                child: Text(
                  '$number',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (english != null && english.isNotEmpty)
              Text(
                english,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (arabic != null && arabic.isNotEmpty) ...[
              const SizedBox(height: 4),
              ArabicText(
                arabic,
                tajweed: false,
                fontSize: 16,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                align: TextAlign.right,
              ),
            ],
            const Spacer(),
            Text(
              hadithCount == 1 ? '1 hadith' : '$hadithCount hadiths',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
