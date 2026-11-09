/// Sheet listing one surah's bookmarks, opened from its surah card.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../quran/models.dart';
import '../../router_paths.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_tokens.dart';

/// "1 bookmark" or "N bookmarks".
String bookmarkCountLabel(int count) =>
    '$count bookmark${count == 1 ? '' : 's'}';

/// Shows [bookmarks] for [chapter]; tapping one opens the reader there.
Future<void> showSurahBookmarksSheet(
  BuildContext context,
  ChapterMeta chapter,
  List<Bookmark> bookmarks,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${chapter.nameSimple} · ${bookmarkCountLabel(bookmarks.length)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: bookmarks.length,
                itemBuilder: (_, index) {
                  final bookmark = bookmarks[index];
                  final snippet = bookmark.snippet;
                  return ListTile(
                    key: Key('surah-bookmark-${chapter.id}-${bookmark.ayah}'),
                    minTileHeight: AppSpacing.minTouchTarget,
                    leading: Icon(
                      Icons.bookmark_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Ayah ${bookmark.ayah}'),
                    subtitle: snippet == null
                        ? null
                        : Text(
                            snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        AppRoute.surah(chapter.id, ayah: bookmark.ayah),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
