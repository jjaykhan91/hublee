/// Shared body for a guide section: prose, lists, timeline, ayah chips.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../guidance/guidance_models.dart';
import '../../router_paths.dart';
import '../../services/settings_controller.dart';
import 'arabic_text.dart';
import 'hublee_card.dart';

/// Renders [GuidanceSection] fields in the order Hublee uses on detail pages.
class GuidanceSectionBody extends StatelessWidget {
  const GuidanceSectionBody({super.key, required this.section});

  final GuidanceSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.subtitle != null && section.subtitle!.isNotEmpty) ...[
          Text(
            section.subtitle!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final paragraph in section.paragraphs) ...[
          Text(paragraph, style: muted),
          const SizedBox(height: 14),
        ],
        for (final group in section.groups) ...[
          Text(
            group.heading,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: muted?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Expanded(child: Text(item, style: muted)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
        for (final event in section.timeline)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HubleeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.when,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(event.body, style: muted),
                ],
              ),
            ),
          ),
        if (section.ayahs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'In the Quran',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final ayah in section.ayahs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GuidanceAyahCard(ayah: ayah),
            ),
        ],
      ],
    );
  }
}

/// Tappable ayah row that opens the surah reader.
class GuidanceAyahCard extends StatelessWidget {
  const GuidanceAyahCard({super.key, required this.ayah});

  final GuidanceAyahRef ayah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HubleeCard(
      onTap: () => context.push(AppRoute.surah(ayah.surahId, ayah: ayah.ayah)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ayah.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (ayah.why != null && ayah.why!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ayah.why!,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Arabic for guides and du'as: Amiri, never tajweed, respects zoom.
class GuidanceArabicText extends StatelessWidget {
  const GuidanceArabicText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.align = TextAlign.right,
    this.color,
  });

  final String text;
  final double fontSize;
  final TextAlign align;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ArabicText(
      text,
      tajweed: false,
      fontOverride: ArabicFontOption.amiri,
      fontSize: fontSize,
      align: align,
      color: color,
    );
  }
}
