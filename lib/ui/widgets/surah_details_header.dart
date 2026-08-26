/// Surah identity card shown above the first ayah in the reader.
library;

import 'package:flutter/material.dart';

import '../../quran/models.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'reading_width.dart';

/// Header: Arabic name, English title, Listen / Info, Meccan/Medinan.
class SurahDetailsHeader extends StatelessWidget {
  const SurahDetailsHeader({
    super.key,
    required this.chapter,
    required this.onInfo,
    this.onListen,
    this.onTranslation,
  });

  final ChapterMeta chapter;
  final VoidCallback onInfo;
  final VoidCallback? onListen;
  final VoidCallback? onTranslation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final meaning = chapter.nameTranslated;
    final accent = chapter.isMeccan
        ? AppColors.meccanAccent
        : AppColors.medinanAccent;
    final juz = chapter.startJuz == chapter.endJuz
        ? 'Juz ${chapter.startJuz}'
        : 'Juz ${chapter.startJuz}–${chapter.endJuz}';
    final ligature = 'surah${chapter.id.toString().padLeft(3, '0')}';

    final compact = ReadingLayout.compactChrome(MediaQuery.sizeOf(context));
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Surah ${chapter.id}, ${chapter.nameSimple}',
          child: ExcludeSemantics(
            child: Text(
              ligature,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: AppFonts.surahName,
                fontWeight: FontWeight.bold,
                color: accent,
                height: 1.3,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${chapter.id}. Surah ${chapter.nameSimple}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (meaning != null && meaning.isNotEmpty)
          Text(
            meaning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${chapter.versesCount} ayahs · $juz',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            _RevelationChip(isMeccan: chapter.isMeccan, accent: accent),
          ],
        ),
      ],
    );
    final actions = _HeaderActions(onListen: onListen, onInfo: onInfo);

    return Material(
      key: const Key('surah-details-header'),
      color: colorScheme.surfaceContainerHighest,
      elevation: dark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: accent.withValues(alpha: dark ? 0.4 : 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact) ...[
              identity,
              const SizedBox(height: 12),
              actions,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 8),
                  actions,
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'Read and listen to Surah ${chapter.nameSimple} with '
              'translation, tajweed colouring, word-by-word meaning, '
              'and optional recitation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
            if (onTranslation != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                onPressed: () {
                  AppHaptics.selection();
                  onTranslation!();
                },
                avatar: Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: const Text('Translation: ClearQuran'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevelationChip extends StatelessWidget {
  const _RevelationChip({required this.isMeccan, required this.accent});

  final bool isMeccan;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        color: accent.withValues(alpha: 0.12),
      ),
      child: Text(
        isMeccan ? 'Meccan' : 'Medinan',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.onInfo, this.onListen});

  final VoidCallback onInfo;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onListen != null)
          FilledButton.tonalIcon(
            key: const Key('surah-header-listen'),
            onPressed: () {
              AppHaptics.selection();
              onListen!();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Listen'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        OutlinedButton.icon(
          key: const Key('surah-header-info'),
          onPressed: () {
            AppHaptics.selection();
            onInfo();
          },
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('Info'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
