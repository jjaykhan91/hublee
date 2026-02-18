/// Full-screen guide to tajweed recitation rules.
///
/// Displays colour-coded tajweed rules with descriptions, Arabic
/// examples, and pronunciation guidance. Accessible from the
/// reader settings sheet and the settings page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'widgets/tajweed.dart';

/// Comprehensive tajweed rules reference page.
class TajweedGuidePage extends StatelessWidget {
  const TajweedGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tajweed Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Introduction
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.15),
                              colorScheme.tertiary.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'What is Tajweed?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tajweed (\u062A\u062C\u0648\u064A\u062F) is the set of '
                    'rules governing the correct pronunciation of the '
                    'Quran during recitation. The word means '
                    '"to make better" or "to beautify". When enabled, '
                    'Hublee colour-codes the Arabic text following the '
                    'Madani mushaf colour scheme used by quran.com.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms),
          const SizedBox(height: 16),

          // Section: Colour Legend
          Text(
            'Colour Legend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 10),

          // ─── Noon / Tanween Rules ───
          _TajweedRuleCard(
            index: 0,
            color: kGhunnahColor,
            rule: 'Ghunnah',
            arabic: '\u063A\u064F\u0646\u0651\u064E\u0629',
            description:
                'A nasal sound from the nose lasting approximately two '
                'beats. Occurs when Noon (\u0646) or Meem (\u0645) '
                'carries a Shadda (\u0651).',
            example: 'Example: \u0645\u0650\u0646\u0651 (from) — '
                'the doubled Noon has Ghunnah',
          ),
          _TajweedRuleCard(
            index: 1,
            color: kIdghamGhunnahColor,
            rule: 'Idgham with Ghunnah',
            arabic:
                '\u0625\u062F\u0652\u063A\u064E\u0627\u0645 \u0628\u063A\u064F\u0646\u0651\u064E\u0629',
            description:
                'Merging of Noon Sakinah or Tanween into the following '
                'letter with nasalization. Occurs before the letters '
                '\u064A, \u0646, \u0645, \u0648 (Yaa, Noon, Meem, Waw). '
                'The Noon/Tanween turns grey (silent) while the receiving '
                'letter is coloured green.',
            example: 'Example: \u0645\u0650\u0646 \u0645\u064E\u0627\u0644 '
                '— the Noon turns grey, Meem turns green',
          ),
          _TajweedRuleCard(
            index: 2,
            color: const Color(0xFFCCCCCC),
            rule: 'Idgham without Ghunnah',
            arabic:
                '\u0625\u062F\u0652\u063A\u064E\u0627\u0645 \u0628\u0644\u0627 \u063A\u064F\u0646\u0651\u064E\u0629',
            description:
                'Merging without nasalization. Occurs when Noon Sakinah '
                'or Tanween is followed by \u0631 (Ra) or \u0644 (Lam). '
                'The Noon/Tanween turns grey to indicate it is not '
                'pronounced — it disappears completely.',
            example: 'Example: \u0645\u0650\u0646 \u0631\u064E\u0628\u0651 — '
                'Noon turns grey and merges into Ra',
          ),
          _TajweedRuleCard(
            index: 3,
            color: kIkhfaColor,
            rule: 'Ikhfa (Concealment)',
            arabic: '\u0625\u062E\u0652\u0641\u064E\u0627\u0621',
            description: 'The Noon Sakinah or Tanween is pronounced between '
                'Idgham and Izhar — not fully merged, not fully clear. '
                'Applies before 15 Arabic letters.',
            example:
                'Example: \u0645\u0650\u0646 \u062A\u064E\u062D\u0652\u062A '
                '— the Noon before Taa is concealed',
          ),
          _TajweedRuleCard(
            index: 4,
            color: kIqlabColor,
            rule: 'Iqlab (Conversion)',
            arabic: '\u0625\u0642\u0652\u0644\u064E\u0627\u0628',
            description:
                'When Noon Sakinah or Tanween is followed by \u0628 '
                '(Ba), the Noon sound converts into a Meem sound, '
                'held for two beats with the lips closed. '
                'The Noon turns grey (silent) and the Ba turns green.',
            example:
                'Example: \u0645\u0650\u0646 \u0628\u064E\u0639\u0652\u062F '
                '— Noon turns grey, Ba turns green',
          ),

          const SizedBox(height: 10),

          // ─── Qalqalah ───
          _TajweedRuleCard(
            index: 5,
            color: kQalqalaColor,
            rule: 'Qalqalah (Echo)',
            arabic: '\u0642\u064E\u0644\u0652\u0642\u064E\u0644\u0629',
            description:
                'An echoing or bouncing sound produced when one of the '
                'five Qalqala letters (\u0642, \u0637, \u0628, \u062C, '
                '\u062F) appears with a sukun (rest). The letter is '
                'pronounced with a slight "bounce".',
            example: 'Example: \u0627\u0642\u0652\u0631\u064E\u0623\u0652 '
                '(Read!) — Qaf with sukun has qalqalah',
          ),

          const SizedBox(height: 10),

          // ─── Meem Rules ───
          _TajweedRuleCard(
            index: 6,
            color: kMeemIkhfaColor,
            rule: 'Ikhfa Shafawi (Labial Concealment)',
            arabic:
                '\u0625\u062E\u0652\u0641\u064E\u0627\u0621 \u0634\u064E\u0641\u064E\u0648\u0650\u064A',
            description:
                'When Meem Sakinah (\u0645\u0652) is followed by \u0628 '
                '(Ba), the Meem is concealed — pronounced lightly between '
                'the lips with nasalization.',
            example:
                'Example: \u062A\u064E\u0631\u0652\u0645\u0650\u064A\u0647\u0650\u0645 '
                '\u0628\u062D\u062C\u064E\u0627\u0631\u064E\u0629 — '
                'Meem before Ba',
          ),
          _TajweedRuleCard(
            index: 7,
            color: kMeemIdghamColor,
            rule: 'Meem Idgham (Meem Merging)',
            arabic:
                '\u0625\u062F\u0652\u063A\u064E\u0627\u0645 \u0645\u0650\u064A\u0645',
            description:
                'When Meem Sakinah (\u0645\u0652) is followed by another '
                'Meem, the two merge into one prolonged Meem with '
                'Ghunnah (nasalization).',
            example:
                'Example: \u0644\u064E\u0647\u064F\u0645 \u0645\u064E\u0627 '
                '— Meem merges into the following Meem',
          ),

          const SizedBox(height: 10),

          // ─── Maad Rules ───
          _TajweedRuleCard(
            index: 8,
            color: kMaadSukoonColor,
            rule: 'Maad Sukoon (Prolongation)',
            arabic:
                '\u0645\u064E\u062F\u0651 \u0639\u064E\u0627\u0631\u0636',
            description:
                'A maad letter (Alef, Waw, Ya) followed by a letter '
                'with sukun or at the end of an ayah. The sound is '
                'prolonged 2–6 counts.',
            example: 'Example: \u0627\u0644\u0631\u064E\u062D\u0650\u064A'
                '\u0645\u0650 at end of ayah — Ya is prolonged',
          ),
          _TajweedRuleCard(
            index: 9,
            color: kMaadMunfasilColor,
            rule: 'Maad Muttasil / Munfasil',
            arabic:
                '\u0645\u064E\u062F\u0651 \u0645\u064F\u062A\u0651\u064E'
                '\u0635\u0650\u0644',
            description:
                'When a maad letter is followed by a Hamza (ء). '
                'Muttasil = within the same word (compulsory 4–5 counts). '
                'Munfasil = across two words (optional 4–5 counts).',
            example:
                'Example: \u062C\u064E\u0627\u0621\u064E (came) — Alef '
                'before Hamza',
          ),
          _TajweedRuleCard(
            index: 10,
            color: kMaadLongColor,
            rule: 'Maad 6 Harakat (Compulsory)',
            arabic:
                '\u0645\u064E\u062F\u0651 \u0644\u064E\u0627\u0632\u0650\u0645',
            description:
                'When a maad letter is followed by a letter with Shadda. '
                'This creates a compulsory 6-count prolongation.',
            example:
                'Example: \u0627\u0644\u0636\u0651\u064E\u0627\u0644\u0651\u0650\u064A\u0646 '
                '— Alef before Lam-Shadda = 6 counts',
          ),

          const SizedBox(height: 24),

          // General reading tips section
          Text(
            'Reading Tips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tipRow(
                    context,
                    Icons.speed_rounded,
                    'Start slow',
                    'Begin with slow recitation (tarteel) to master '
                        'pronunciation before increasing speed.',
                  ),
                  const SizedBox(height: 14),
                  _tipRow(
                    context,
                    Icons.hearing_rounded,
                    'Listen and repeat',
                    'Listen to a skilled reciter and repeat after them, '
                        'paying attention to where tajweed rules apply.',
                  ),
                  const SizedBox(height: 14),
                  _tipRow(
                    context,
                    Icons.color_lens_rounded,
                    'Use colour coding',
                    'Enable tajweed colours in the reader to visualise '
                        'where rules apply as you recite.',
                  ),
                  const SizedBox(height: 14),
                  _tipRow(
                    context,
                    Icons.repeat_rounded,
                    'Practice regularly',
                    'Consistent practice with short passages is more '
                        'effective than occasional long sessions.',
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 500.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Widget _tipRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A card displaying a single tajweed rule with colour, description,
/// and example.
class _TajweedRuleCard extends StatelessWidget {
  final int index;
  final Color color;
  final String rule;
  final String arabic;
  final String description;
  final String example;

  const _TajweedRuleCard({
    required this.index,
    required this.color,
    required this.rule,
    required this.arabic,
    required this.description,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rule header with colour badge
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                  ),
                  Text(
                    arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'KFGQPCQuranicFontHafsSmart',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 8),

              // Example
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  example,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 400.ms,
            delay: (60 * index).clamp(0, 600).ms,
          )
          .slideY(
            begin: 0.04,
            end: 0,
            duration: 400.ms,
            delay: (60 * index).clamp(0, 600).ms,
          ),
    );
  }
}
