/// Slide-up overview of hadith for the Hadith tab.
///
/// Covers what a hadith is, how reports are classified, who narrated
/// and compiled them, and how this page is organised. Orientation
/// only — not grading of individual reports, and not fiqh.
library;

import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';

/// Kinds of hadith a new reader will meet in these books.
const _kHadithTypes = <({String arabic, String english, String meaning})>[
  (
    arabic:
        '\u0627\u0644\u0652\u0642\u064E\u0648\u0652\u0644\u0650\u064A\u0651',
    english: 'Saying',
    meaning: 'His words (qawli)',
  ),
  (
    arabic:
        '\u0627\u0644\u0652\u0641\u0650\u0639\u0652\u0644\u0650\u064A\u0651',
    english: 'Action',
    meaning: 'What he did (fi\u2018li)',
  ),
  (
    arabic:
        '\u0627\u0644\u062A\u0651\u064E\u0642\u0652\u0631\u0650\u064A\u0631'
        '\u0650\u064A\u0651',
    english: 'Approval',
    meaning: 'What he allowed by remaining silent (taqriri)',
  ),
  (
    arabic:
        '\u0627\u0644\u0652\u0642\u064F\u062F\u0652\u0633\u0650\u064A\u0651',
    english: 'Sacred',
    meaning:
        'Allah\u2019s meaning in the Prophet\u2019s wording \u2014 '
        'not Quran (qudsi)',
  ),
];

/// Well-known grades. Hublee does not invent a grade per report.
const _kHadithGrades = <({String arabic, String english, String meaning})>[
  (
    arabic: '\u0635\u064E\u062D\u0650\u064A\u062D',
    english: 'Sahih',
    meaning: 'Authentic chain and wording',
  ),
  (
    arabic: '\u062D\u064E\u0633\u064E\u0646',
    english: 'Hasan',
    meaning: 'Good \u2014 sound, a little less strong than sahih',
  ),
  (
    arabic: '\u0636\u064E\u0639\u0650\u064A\u0641',
    english: 'Da\u2018if',
    meaning: 'Weak chain; studied, not treated as proof on its own',
  ),
];

/// Compilers of the nine books bundled in Hublee, Kutub al-Sittah first.
const _kCompilers = <({String name, String work, String died})>[
  (name: 'Imam al-Bukhari', work: 'Sahih al-Bukhari', died: 'd. 256 AH'),
  (name: 'Imam Muslim', work: 'Sahih Muslim', died: 'd. 261 AH'),
  (name: 'Imam Abu Dawud', work: 'Sunan Abi Dawud', died: 'd. 275 AH'),
  (name: 'Imam al-Tirmidhi', work: 'Jami\u2018 al-Tirmidhi', died: 'd. 279 AH'),
  (
    name: 'Imam al-Nasa\u2019i',
    work: 'Sunan al-Nasa\u2019i',
    died: 'd. 303 AH',
  ),
  (name: 'Imam Ibn Majah', work: 'Sunan Ibn Majah', died: 'd. 273 AH'),
  (name: 'Imam Malik', work: 'al-Muwatta', died: 'd. 179 AH'),
  (name: 'Imam Ahmad ibn Hanbal', work: 'Musnad Ahmad', died: 'd. 241 AH'),
  (name: 'Imam al-Darimi', work: 'Sunan al-Darimi', died: 'd. 255 AH'),
];

/// Opens a draggable sheet with a short orientation to hadith.
void showHadithOverviewSheet(BuildContext context) {
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
          return _HadithOverviewBody(scrollController: scrollController);
        },
      );
    },
  );
}

class _HadithOverviewBody extends StatelessWidget {
  const _HadithOverviewBody({required this.scrollController});

  final ScrollController scrollController;

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
          '\u0627\u0644\u0652\u062D\u064E\u062F\u0650\u064A\u062B',
          fontOverride: ArabicFontOption.amiri,
          fontSize: 28,
          align: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'About Hadith',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A short orientation before you open a book.',
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
                  'Hadiths are the recorded sayings, actions, and approvals '
                  'of Prophet Muhammad (peace be upon him). Alongside the '
                  'Quran they are the main record of his Sunnah \u2014 how '
                  'he taught, worshipped, and lived.',
                  style: body,
                ),
                const SizedBox(height: 12),
                Text(
                  'Each report has two parts. The isnad is the chain of '
                  'people who passed it on. The matn is the wording itself. '
                  'Scholars judge a hadith by both: a beautiful text with a '
                  'broken chain is not treated as proof.',
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
                _sectionTitle(context, 'Types'),
                const SizedBox(height: 8),
                Text(
                  'Most reports are nabawi \u2014 from the Prophet (peace '
                  'be upon him). A hadith qudsi carries a meaning from '
                  'Allah in the Prophet\u2019s wording; it is not Quran.',
                  style: body,
                ),
                const SizedBox(height: 14),
                for (final item in _kHadithTypes) _TermRow(item: item),
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
                _sectionTitle(context, 'How they are graded'),
                const SizedBox(height: 8),
                Text(
                  'Later scholars classified reports by the strength of '
                  'the chain. Hublee does not invent a grade for each '
                  'hadith. A report from Sahih al-Bukhari or Sahih Muslim '
                  'is received as authentic; other books mix strengths.',
                  style: body,
                ),
                const SizedBox(height: 14),
                for (final item in _kHadithGrades) _TermRow(item: item),
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
                _sectionTitle(context, 'How they were gathered'),
                const SizedBox(height: 8),
                Text(
                  'The Companions (may Allah be pleased with them) '
                  'memorised what they heard and saw. Their students, the '
                  'Successors, collected those reports. In the second and '
                  'third centuries after the Hijra, travelling scholars '
                  'compared chains, named reliable narrators, and wrote '
                  'the books still read today. That discipline is the '
                  'science of hadith.',
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
                _sectionTitle(context, 'Major compilers'),
                const SizedBox(height: 8),
                Text(
                  'Kutub al-Sittah \u2014 the six books \u2014 are Bukhari, '
                  'Muslim, Abu Dawud, al-Tirmidhi, al-Nasa\u2019i, and Ibn '
                  'Majah. Hublee\u2019s Nine Books add Malik, Ahmad, and '
                  'al-Darimi.',
                  style: body,
                ),
                const SizedBox(height: 14),
                for (final compiler in _kCompilers)
                  _CompilerRow(compiler: compiler),
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
                _sectionTitle(context, 'Famous narrators'),
                const SizedBox(height: 8),
                Text(
                  'Among the Companions most often quoted (may Allah be '
                  'pleased with them) are Abu Hurairah, Aisha, Abdullah '
                  'ibn Umar, Anas ibn Malik, Abdullah ibn Abbas, and '
                  'Jabir ibn Abdullah. Their names appear as the first '
                  'link in many chains.',
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
                  'Start here is three short 40-hadith sets: Imam '
                  'al-Nawawi (d. 676 AH), Forty Hadith Qudsi, and Shah '
                  'Waliullah. The Nine Books are the major compilations. '
                  'Other Books are later selections \u2014 Riyad '
                  'as-Salihin, al-Adab al-Mufrad, the Shamail, Mishkat '
                  'al-Masabih, and Bulugh al-Maram.\n\n'
                  'Search finds a book by name. Each row\u2019s info icon '
                  'opens a short summary of that book. Continue reading '
                  'resumes where you left off. Bookmark saves favorites.',
                  style: body,
                ),
              ],
            ),
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

class _TermRow extends StatelessWidget {
  const _TermRow({required this.item});

  final ({String arabic, String english, String meaning}) item;

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
              item.arabic,
              fontOverride: ArabicFontOption.amiri,
              fontSize: 18,
              align: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.english,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.meaning,
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

class _CompilerRow extends StatelessWidget {
  const _CompilerRow({required this.compiler});

  final ({String name, String work, String died}) compiler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compiler.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${compiler.work} \u00b7 ${compiler.died}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
