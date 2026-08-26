/// Full list of everyday dhikrs a person can recite.
library;

import 'package:flutter/material.dart';

import '../guidance/everyday_dhikr.dart';
import '../theme/app_tokens.dart';
import 'widgets/dhikr_of_the_day_card.dart';
import 'widgets/guidance_section_body.dart';
import 'widgets/hublee_card.dart';

/// Catalog of anytime remembrances. Tap a row for wording, source, and copy.
class DhikrPage extends StatelessWidget {
  const DhikrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dhikr')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            'Short remembrances you can say at any time. Tap one to see '
            'the Arabic, meaning, and source — then copy it if you wish.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          for (final dhikr in everydayDhikrCatalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DhikrListCard(dhikr: dhikr),
            ),
        ],
      ),
    );
  }
}

class _DhikrListCard extends StatelessWidget {
  const _DhikrListCard({required this.dhikr});

  final EverydayDhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return HubleeCard(
      key: Key('dhikr-item-${dhikr.id}'),
      onTap: () =>
          showDhikrOfTheDaySheet(context, dhikr, title: dhikr.transliteration),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuidanceArabicText(dhikr.arabic, fontSize: 22),
          const SizedBox(height: 6),
          Text(
            dhikr.transliteration,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dhikr.english,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dhikr.source,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
