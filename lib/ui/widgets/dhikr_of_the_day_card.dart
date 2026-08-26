/// Home-tab card and sheet for the daily everyday dhikr.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../guidance/everyday_dhikr.dart';
import '../../services/settings_controller.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';
import 'hublee_marks.dart';
import 'passage_actions.dart';

/// Gradient card matching ayah/hadith of the day. Tap opens the wording.
class DhikrOfTheDayCard extends StatelessWidget {
  const DhikrOfTheDayCard({super.key, required this.dhikr});

  final EverydayDhikr dhikr;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dhikr of the day, ${dhikr.transliteration}',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.featureCard,
        child: InkWell(
          onTap: () => showDhikrOfTheDaySheet(context, dhikr),
          borderRadius: AppRadius.featureCard,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.dhikrOfDay,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.featureCard,
              boxShadow: AppShadows.featureCardShadow(AppColors.dhikrOfDayTint),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: IslamicStarLatticePainter(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppRadius.badge,
                              boxShadow: AppShadows.badge,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Dhikr of the Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          HubleeStarMark(
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dhikr.source,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ArabicText(
                        dhikr.arabic,
                        tajweed: false,
                        fontSize: 22,
                        weight: FontWeight.bold,
                        align: TextAlign.center,
                        color: Colors.white,
                        fontOverride: ArabicFontOption.amiri,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dhikr.english,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Say throughout the day',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full wording, source, and copy actions for [dhikr].
Future<void> showDhikrOfTheDaySheet(BuildContext context, EverydayDhikr dhikr) {
  AppHaptics.selection();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      final muted = theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.45,
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dhikr of the Day',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A short remembrance you can say at any time.',
                  textAlign: TextAlign.center,
                  style: muted,
                ),
                const SizedBox(height: 16),
                ArabicText(
                  dhikr.arabic,
                  tajweed: false,
                  fontSize: 26,
                  weight: FontWeight.bold,
                  align: TextAlign.center,
                  fontOverride: ArabicFontOption.amiri,
                ),
                const SizedBox(height: 10),
                Text(
                  dhikr.transliteration,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(dhikr.english, textAlign: TextAlign.center, style: muted),
                const SizedBox(height: 16),
                Text(
                  dhikr.source,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                if (dhikr.virtue != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dhikr.virtue!,
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final text = formatPassage(
                      reference: dhikr.source,
                      arabic: dhikr.arabic,
                      english: '${dhikr.transliteration}\n${dhikr.english}',
                    );
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dhikr copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
