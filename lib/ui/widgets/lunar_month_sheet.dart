/// Slide-up explanation of the 30-day lunar reading plan on the Quran tab.
library;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_haptics.dart';

const _sections = <({String title, String body})>[
  (
    title: 'What it is',
    body:
        'This plan comes from Sheikh Imran Hosein’s book The Qur’an '
        'and the Moon. You read the whole Quran once each lunar month, '
        'starting on the day the new crescent is sighted. Each day is made '
        'of whole surahs, so you never stop partway through a surah because '
        'a juz ends there.',
  ),
  (
    title: 'Why whole surahs',
    body:
        'The 30 juz were added later to make reading easier. The Sheikh '
        'argues that reading by surah keeps each one whole, as Allah '
        'arranged it, rather than following a later division.',
  ),
  (
    title: 'How the days are set out',
    body:
        'The long surahs come first in the mushaf and the short ones last. '
        'Days 1 to 6 are one long surah each. From Day 7, surahs are joined, '
        'and by Day 30 you read 17 short ones. The daily reading gets '
        'lighter as the moon wanes.',
  ),
  (
    title: 'Days he marks',
    body:
        'Day 1 to 6: he links them to the six days of creation.\n'
        'Day 7: Al-Anfal and At-Tawbah are joined for the first time. He '
        'points out that Al-Anfal is short, At-Tawbah is long, and At-Tawbah '
        'has no Bismillah. It closes the first week, a pause for reflection.\n'
        'Day 15: the full moon. Reaching An-Nur means half the month has '
        'passed.\n'
        'Day 29: look for the new crescent after sunset. If it is seen, the '
        'month is ending, so finish the Day 30 portion that night. If not, '
        'read it the next day. He advises against finishing early.',
  ),
  (
    title: 'Tips',
    body:
        'Start on the 1st of the hijri month, not the calendar month.\n'
        'Days 1 to 6 are the heaviest. Al-Baqarah alone is about two and a '
        'half juz, so you could split it between Fajr and ‘Isha.\n'
        'Al-Fatihah is not in the daily plan; it is shown before Day 1.',
  ),
  (
    title: 'A note on the method',
    body:
        'Reciting the Quran over a month comes from the hadith of '
        '‘Abdullah ibn ‘Amr, whom the Prophet ﷺ told to '
        'recite it in a month. The day-by-day plan and the meanings given '
        'to days 7, 15 and 29 are the Sheikh’s own reflections. Most '
        'scholars see the juz as a helpful convenience, so this is one '
        'valid way to read the Quran, not the only one.',
  ),
];

/// Opens a draggable sheet explaining the 30-day lunar reading plan.
void showLunarMonthSheet(BuildContext context) {
  AppHaptics.selection();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          final theme = Theme.of(ctx);
          return ListView(
            key: const Key('lunar-month-sheet'),
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Text(
                'Reading the Quran in a lunar month',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'One reading of the Quran per moon, in whole surahs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final section in _sections) ...[
                const SizedBox(height: 20),
                Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ],
            ],
          );
        },
      );
    },
  );
}
