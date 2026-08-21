/// Bottom sheet listing hadith chapters for jump-to navigation.
library;

import 'package:flutter/material.dart';

import '../../hadith/hadith_chapters.dart';
import '../../hadith/hadith_repository.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';

/// Shows a scrollable chapter list. Tapping a row calls [onJump]
/// with the first hadith index of that chapter.
void showHadithChapterSheet({
  required BuildContext context,
  required List<HadithChapter> chapters,
  required List<Hadith> hadiths,
  required void Function(int hadithIndex) onJump,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => HadithChapterSheet(
      chapters: chapters,
      hadiths: hadiths,
      onJump: (index) {
        Navigator.of(sheetContext).pop();
        onJump(index);
      },
    ),
  );
}

/// Chapter table of contents. Public so tests can pump it without a sheet.
class HadithChapterSheet extends StatelessWidget {
  final List<HadithChapter> chapters;
  final List<Hadith> hadiths;
  final void Function(int hadithIndex) onJump;

  const HadithChapterSheet({
    super.key,
    required this.chapters,
    required this.hadiths,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.sheetTop,
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chapters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final jumpIndex = firstHadithIndexForChapter(
                    hadiths,
                    chapter.id,
                  );
                  final count = hadithCountForChapter(hadiths, chapter.id);
                  final english = chapter.english?.trim();
                  final arabic = chapter.arabic?.trim();
                  final title = (english != null && english.isNotEmpty)
                      ? english
                      : (arabic != null && arabic.isNotEmpty)
                      ? arabic
                      : 'Chapter ${chapter.id ?? index + 1}';

                  return ListTile(
                    key: Key('hadith-chapter-${chapter.id ?? index}'),
                    title: Text(title),
                    subtitle: count > 0
                        ? Text(count == 1 ? '1 hadith' : '$count hadiths')
                        : null,
                    trailing:
                        arabic != null && arabic.isNotEmpty && arabic != title
                        ? SizedBox(
                            width: 140,
                            child: ArabicText(
                              arabic,
                              fontSize: 16,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                    enabled: jumpIndex != null,
                    onTap: jumpIndex == null
                        ? null
                        : () {
                            AppHaptics.selection();
                            onJump(jumpIndex);
                          },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
