/// Flutter preview of an Android home-screen widget look.
library;

import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../services/widget_look.dart';
import '../../theme/app_tokens.dart';
import 'arabic_text.dart';

/// Sample copy so Settings can show a look without loading assets.
class WidgetPreviewCopy {
  const WidgetPreviewCopy({
    required this.kicker,
    required this.arabic,
    required this.english,
    required this.ref,
  });

  final String kicker;
  final String arabic;
  final String english;
  final String ref;
}

/// Colours that match the native widget drawables.
class WidgetLookPalette {
  const WidgetLookPalette({
    required this.background,
    required this.onBackground,
    required this.kicker,
    required this.muted,
  });

  final Color background;
  final Color onBackground;
  final Color kicker;
  final Color muted;

  static WidgetLookPalette of(HomeWidgetKind kind, WidgetLookTheme theme) {
    if (theme == WidgetLookTheme.light) {
      return const WidgetLookPalette(
        background: Color(0xFFF8FAFC),
        onBackground: Color(0xFF0F172A),
        kicker: Color(0xFF2563EB),
        muted: Color(0xFF475569),
      );
    }
    if (theme == WidgetLookTheme.dark) {
      return const WidgetLookPalette(
        background: Color(0xFF11161C),
        onBackground: Color(0xFFE7ECF2),
        kicker: Color(0xFF8AB4FF),
        muted: Color(0xFFB8C2CF),
      );
    }
    if (theme == WidgetLookTheme.paper) {
      return const WidgetLookPalette(
        background: Color(0xFFF4EDE0),
        onBackground: Color(0xFF3F2F1F),
        kicker: Color(0xFF8B5E34),
        muted: Color(0xFF6B5344),
      );
    }
    return switch (kind) {
      HomeWidgetKind.hadith => const WidgetLookPalette(
        background: Color(0xFF065F46),
        onBackground: Colors.white,
        kicker: Color(0xFFA7F3D0),
        muted: Color(0xFFD1FAE5),
      ),
      HomeWidgetKind.arabicWord => const WidgetLookPalette(
        background: Color(0xFF0B4D5C),
        onBackground: Colors.white,
        kicker: Color(0xFF7DD3FC),
        muted: Color(0xFFD6EEF5),
      ),
      HomeWidgetKind.ayah ||
      HomeWidgetKind.quranWord => const WidgetLookPalette(
        background: Color(0xFF312E81),
        onBackground: Colors.white,
        kicker: Color(0xFFC7D2FE),
        muted: Color(0xFFE0E7FF),
      ),
    };
  }
}

/// In-app preview of a launcher widget.
class HomeScreenWidgetPreview extends StatelessWidget {
  const HomeScreenWidgetPreview({
    super.key,
    required this.kind,
    required this.look,
    required this.copy,
  });

  final HomeWidgetKind kind;
  final WidgetLook look;
  final WidgetPreviewCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = WidgetLookPalette.of(kind, look.theme);
    final arabicSize = switch (look.size) {
      WidgetLookSize.compact => 18.0,
      WidgetLookSize.comfortable => 22.0,
      WidgetLookSize.large => 26.0,
    };
    final englishSize = switch (look.size) {
      WidgetLookSize.compact => 12.0,
      WidgetLookSize.comfortable => 13.0,
      WidgetLookSize.large => 15.0,
    };

    return Material(
      color: palette.background,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.kicker.toUpperCase(),
              style: TextStyle(
                color: palette.kicker,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            ArabicText(
              copy.arabic,
              tajweed: false,
              fontOverride: ArabicFontOption.amiri,
              fontSize: arabicSize,
              align: TextAlign.right,
              color: palette.onBackground,
              maxLines: look.size == WidgetLookSize.compact ? 3 : 5,
              overflow: TextOverflow.ellipsis,
            ),
            if (look.showTranslation && copy.english.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                copy.english,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: englishSize,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              copy.ref,
              style: TextStyle(
                color: palette.kicker,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
