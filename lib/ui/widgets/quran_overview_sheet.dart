/// Slide-up overview of the Quran for the Quran tab.
///
/// Covers what the Quran is, its well-known names, and how the mushaf
/// is arranged so a reader can orient themselves before opening a
/// surah. This is not tafsir.
library;

import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';
import 'quran_reading_guide_sheet.dart';

/// Names of the Quran that appear in the text itself.
const _kQuranNames = <({String arabic, String english, String meaning})>[
  (
    arabic: '\u0627\u0644\u0652\u0642\u064F\u0631\u0652\u0622\u0646',
    english: 'Al-Qur\u2019an',
    meaning: 'The Recitation',
  ),
  (
    arabic: '\u0627\u0644\u0652\u0643\u0650\u062A\u064E\u0627\u0628',
    english: 'Al-Kitab',
    meaning: 'The Book',
  ),
  (
    arabic:
        '\u0627\u0644\u0652\u0641\u064F\u0631\u0652\u0642\u064E\u0627\u0646',
    english: 'Al-Furqan',
    meaning: 'The Criterion',
  ),
  (
    arabic: '\u0627\u0644\u0630\u0650\u0651\u0643\u0652\u0631',
    english: 'Adh-Dhikr',
    meaning: 'The Reminder',
  ),
  (
    arabic:
        '\u0627\u0644\u062A\u064E\u0651\u0646\u0652\u0632\u0650\u064A\u0644',
    english: 'At-Tanzil',
    meaning: 'The Revelation',
  ),
];

/// Opens a draggable sheet with a short orientation to the Quran.
void showQuranOverviewSheet(BuildContext context) {
  AppHaptics.selection();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return _QuranOverviewBody(
            scrollController: scrollController,
            onOpenReadingGuide: () {
              Navigator.of(sheetContext).pop();
              showQuranReadingGuideSheet(context);
            },
          );
        },
      );
    },
  );
}

class _QuranOverviewBody extends StatelessWidget {
  const _QuranOverviewBody({
    required this.scrollController,
    required this.onOpenReadingGuide,
  });

  final ScrollController scrollController;
  final VoidCallback onOpenReadingGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.55);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const ArabicText(
          '\u0627\u0644\u0652\u0642\u064F\u0631\u0652\u0622\u0646',
          fontOverride: ArabicFontOption.amiri,
          fontSize: 28,
          align: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'About the Quran',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A short orientation before you open a surah.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'What it is'),
                const SizedBox(height: 8),
                Text(
                  'The Quran is the word of Allah, revealed to Prophet Muhammad '
                  '(peace be upon him) over about twenty-three years. Muslims '
                  'regard reciting it as worship. Hublee displays the Hafs '
                  '\u2018an \u2018Asim reading in Uthmani script \u2014 the '
                  'same reading most printed mushafs use today.',
                  style: body,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Names'),
                const SizedBox(height: 8),
                Text(
                  'The Quran names itself in several ways. These are among '
                  'the best known:',
                  style: body,
                ),
                const SizedBox(height: 14),
                for (final name in _kQuranNames) _NameRow(name: name),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'How it is arranged'),
                const SizedBox(height: 8),
                Text(
                  'There are 114 surahs (chapters), from Al-Fatihah to '
                  'An-Nas. After the opening, they are ordered roughly from '
                  'longest to shortest. Al-Baqarah is the longest (286 '
                  'ayahs); Al-Kawthar is the shortest (3 ayahs).',
                  style: body,
                ),
                const SizedBox(height: 12),
                Text(
                  'This Hafs text has 6,236 ayahs (verses). For paced '
                  'reading, especially in Ramadan, the mushaf is also split '
                  'into 30 juz (parts). Hublee\u2019s Juz tab follows that '
                  'division.',
                  style: body,
                ),
                const SizedBox(height: 12),
                Text(
                  'Each surah is labelled Meccan or Medinan \u2014 revealed '
                  'before or after the Hijra. That is a traditional '
                  'classification of the surah as a whole; a few ayahs in a '
                  'surah may have been revealed at a different time.',
                  style: body,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'On this page'),
                const SizedBox(height: 8),
                Text(
                  'Surah is the full list. Juz groups by the 30 parts. Type '
                  'splits Meccan and Medinan. Revelation sorts by the order '
                  'the surahs were revealed, not mushaf order.\n\n'
                  'Pin an ayah inside a surah to resume there the next time '
                  'you open it. Continue where you left off follows wherever '
                  'you last scrolled. Bookmark saves favorites. The book icon '
                  'in the app bar opens sajdah, stop signs, and tajweed.',
                  style: body,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onOpenReadingGuide,
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            label: const Text('Reading & Tajweed guide'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name});

  final ({String arabic, String english, String meaning}) name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: ArabicText(
              name.arabic,
              fontOverride: ArabicFontOption.amiri,
              fontSize: 20,
              align: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.english,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name.meaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
