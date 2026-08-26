/// Sajdah chip on ayah cards and the sheet that explains tilawah
/// prostration: what to do, and the du'a to recite.
library;

import 'package:flutter/material.dart';

import '../../quran/sajdah.dart';
import '../../services/settings_controller.dart';
import '../../theme/app_tokens.dart';
import 'app_haptics.dart';
import 'arabic_text.dart';

/// Opens the sajdah how-to sheet (what to do and what to recite).
void showSajdahSheet(BuildContext context) {
  AppHaptics.selection();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (ctx) => const _SajdahSheet(),
  );
}

/// Compact tappable badge for a sajdah ayah. Opens [showSajdahSheet].
class SajdahChip extends StatelessWidget {
  const SajdahChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fill = colorScheme.tertiaryContainer;
    final ink = colorScheme.onTertiaryContainer;
    final border = StadiumBorder(
      side: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.4)),
    );

    return Tooltip(
      message: 'Prostration is recommended. Tap to see what to do.',
      child: Material(
        color: fill,
        elevation: 0,
        shape: border,
        child: InkWell(
          key: const Key('sajdah-chip'),
          customBorder: border,
          onTap: () => showSajdahSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u06E9',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ink,
                    fontFamilyFallback: AppFonts.arabicFallback,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sajdah',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
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

/// Shared "what to do / what to recite" copy. Used by the ayah sheet
/// and the Quran reading guide so both stay in sync.
class SajdahGuideBody extends StatelessWidget {
  const SajdahGuideBody({super.key, this.showCountIntro = false});

  /// When true, prepends the 15-ayah overview (reading guide only).
  final bool showCountIntro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCountIntro) ...[
          Text(kSajdahCountIntro, style: body),
          const SizedBox(height: 14),
        ],
        Text(
          'What to do',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(kSajdahWhatToDo, style: body),
        const SizedBox(height: 16),
        Text(
          'What to recite (in prostration)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const ArabicText(
          kSajdahArabic,
          fontOverride: ArabicFontOption.amiri,
          fontSize: 26,
          align: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Transliteration: $kSajdahTransliteration',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.5,
            color: colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Meaning: $kSajdahMeaning',
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _SajdahSheet extends StatelessWidget {
  const _SajdahSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = colorScheme.onTertiaryContainer;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.tertiary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '\u06E9',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontFamilyFallback: AppFonts.arabicFallback,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sajdah (Prostration)',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recommended when you recite or hear this ayah.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SajdahGuideBody(),
          ],
        ),
      ),
    );
  }
}
