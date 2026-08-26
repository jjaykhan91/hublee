/// Modal bottom sheet for Quran reading rules and Tajweed reference.
///
/// Covers: Sajdah (prostration), Waqf (stop) signs, and Tajweed colour rules.
/// Shown from the Quran tab app bar (book icon).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hublee/router_paths.dart';
import 'package:hublee/ui/widgets/sajdah_guide.dart';
import 'package:hublee/ui/widgets/tajweed.dart';

/// Shows a draggable modal bottom sheet with Quran reading rules
/// (sajdah, waqf/stop signs) and Tajweed colour legend.
void showQuranReadingGuideSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return _QuranReadingGuideContent(scrollController: scrollController);
      },
    ),
  );
}

class _QuranReadingGuideContent extends StatelessWidget {
  const _QuranReadingGuideContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _buildDragHandle(context),
        const SizedBox(height: 8),
        Text(
          'Quran Reading & Tajweed',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),

        // ─── Sajdah (Prostration) ───
        const _SectionHeader(
          icon: Icons.pan_tool_rounded,
          title: 'Sajdah (Prostration)',
          arabic: '\u0633\u062C\u0648\u062F',
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SajdahGuideBody(showCountIntro: true),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Waqf (Stop) Signs ───
        const _SectionHeader(
          icon: Icons.flag_rounded,
          title: 'Waqf (Stop) Signs',
          arabic:
              '\u0623\u0639\u0644\u0627\u0645 \u0627\u0644\u0648\u0642\u0641',
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WaqfRow(
                  symbol: '\u0645\u0640',
                  name: 'Waqf Lazim',
                  meaning: 'Mandatory stop. Meaning changes if you continue.',
                ),
                _WaqfRow(
                  symbol: '\u0644\u0627',
                  name: 'La Taqif',
                  meaning: 'Do not stop. Phrase is incomplete.',
                ),
                _WaqfRow(
                  symbol: '\u062C',
                  name: 'Waqf Jaiz',
                  meaning: 'Permissible to stop or continue.',
                ),
                _WaqfRow(
                  symbol: '\u0642\u0644\u0649',
                  name: 'Qeela Alayhil-Waqf',
                  meaning: 'Stopping is preferred.',
                ),
                _WaqfRow(
                  symbol: '\u0635\u0644\u0649',
                  name: 'Qeelal-Waslu',
                  meaning: 'Continuing is preferred.',
                ),
                _WaqfRow(
                  symbol: '\u0633',
                  name: 'Saktah',
                  meaning: 'Brief pause without breathing.',
                ),
                _WaqfRow(
                  symbol: '\u2234',
                  name: 'Mu\'anaqah',
                  meaning: 'Stop at one of two marked positions, not both.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Tajweed Colour Legend ───
        const _SectionHeader(
          icon: Icons.palette_rounded,
          title: 'Tajweed Colours',
          arabic:
              '\u0623\u0644\u0648\u0627\u0646 \u0627\u0644\u062A\u062C\u0648\u064A\u062F',
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TajweedLegendRow(
                  color: kNotPronouncedColor(Theme.of(context).brightness),
                  rule: 'Silent letter',
                ),
                const _TajweedLegendRow(
                  color: kNormalMaadColor,
                  rule: 'Normal madd (2)',
                ),
                const _TajweedLegendRow(
                  color: kMaadSukoonColor,
                  rule: 'Separated madd (2/4/6)',
                ),
                const _TajweedLegendRow(
                  color: kMaadConnectedColor,
                  rule: 'Connected madd (4/5)',
                ),
                const _TajweedLegendRow(
                  color: kMaadLongColor,
                  rule: 'Necessary madd (6)',
                ),
                const _TajweedLegendRow(
                  color: kGhunnahColor,
                  rule: 'Ghunnah / Ikhfa\'',
                ),
                const _TajweedLegendRow(
                  color: kQalqalaColor,
                  rule: 'Qalqala (echo)',
                ),
                const _TajweedLegendRow(
                  color: kTafkhimColor,
                  rule: 'Tafkhim (heavy)',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoute.tajweedGuide);
                    },
                    icon: const Icon(Icons.auto_stories_rounded, size: 20),
                    label: const Text('Full Tajweed Guide'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Recitation tips ───
        const _SectionHeader(
          icon: Icons.record_voice_over_rounded,
          title: 'Recitation',
          arabic: '\u0627\u0644\u062A\u0644\u0627\u0648\u0629',
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Seek refuge before reciting: A\u2018\u016Bdh\u016B bill\u0101hi '
                  'minash-shay\u1E6D\u0101nir-raj\u012Bm.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Begin with Bismillah at the start of each surah '
                  '(except At-Tawbah).',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Respect stop signs: mandatory stops (مـ) require a pause; '
                  'do not stop at \u201cLa\u201d (لا) signs.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Preserve the Quran: avoid placing it where it could be '
                  'disrespected; do not truncate Arabic mid-word.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.arabic,
  });

  final IconData icon;
  final String title;
  final String arabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                arabic,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'KFGQPCQuranicFontHafsSmart',
                  color: colorScheme.onSurfaceVariant,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaqfRow extends StatelessWidget {
  const _WaqfRow({
    required this.symbol,
    required this.name,
    required this.meaning,
  });

  final String symbol;
  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              symbol,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'KFGQPCQuranicFontHafsSmart',
              ),
              textDirection: symbol == '∴'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meaning,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TajweedLegendRow extends StatelessWidget {
  const _TajweedLegendRow({required this.color, required this.rule});

  final Color color;
  final String rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(rule, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
