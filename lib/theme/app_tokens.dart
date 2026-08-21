/// Central design tokens for layout, shadows, and spacing.
///
/// Use these constants instead of inline values so that design
/// changes propagate from a single source.
library;

import 'package:flutter/material.dart';

// ── Fonts ────────────────────────────────────────────────────────

/// Font families bundled by `pubspec.yaml`.
///
/// Every Arabic face used by the app is bundled, so Arabic rendering never
/// depends on a network fetch or on whatever font the platform substitutes.
abstract final class AppFonts {
  AppFonts._();

  /// PUA-glyph mushaf font. Renders `aya_text` only — it has **no** glyphs
  /// for standard Arabic Unicode, so any style using it needs
  /// [arabicFallback] behind it.
  static const uthmanic = 'KFGQPCQuranicFontHafsSmart';

  /// Calligraphic surah names via the `surah001`–`surah114` ligatures.
  static const surahName = 'SurahNameV4';

  /// Standard-Unicode Arabic faces (SIL OFL 1.1).
  static const amiri = 'Amiri';
  static const scheherazade = 'ScheherazadeNew';
  static const notoNaskh = 'NotoNaskhArabic';

  /// Fallback chain for Arabic text, and for Qur'anic symbols that appear
  /// inside otherwise-Latin styles.
  ///
  /// Only consulted for codepoints the primary family lacks, so it does not
  /// affect Latin rendering.
  static const arabicFallback = <String>[amiri];
}

// ── Border radius ────────────────────────────────────────────────

/// Reusable border radii for cards, chips, and sheets.
abstract final class AppRadius {
  AppRadius._();

  /// Standard card and list tile corners (16px).
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));

  /// Slightly smaller radius for chips and badges (12px).
  static const BorderRadius chip = BorderRadius.all(Radius.circular(12));

  /// Search bar and input fields (14px).
  static const BorderRadius input = BorderRadius.all(Radius.circular(14));

  /// Large feature cards e.g. Verse/Hadith of the Day (20px).
  static const BorderRadius featureCard = BorderRadius.all(Radius.circular(20));

  /// Bottom sheet top corners (24px).
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  /// Small badge/pill (8px).
  static const BorderRadius badge = BorderRadius.all(Radius.circular(8));
}

// ── Spacing ─────────────────────────────────────────────────────

/// Standard padding and gaps.
abstract final class AppSpacing {
  AppSpacing._();

  /// Page horizontal and vertical padding.
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 12, 16, 24);

  /// List content padding (e.g. search results).
  static const EdgeInsets list = EdgeInsets.fromLTRB(12, 8, 12, 24);

  /// Card inner padding.
  static const EdgeInsets card = EdgeInsets.all(16);

  /// Card inner padding (slightly smaller).
  static const EdgeInsets cardTight = EdgeInsets.all(14);

  /// Section gap between major blocks.
  static const double sectionGap = 20.0;

  /// Small gap between related items.
  static const double itemGap = 12.0;
}

// ── Shadows (3D / elevation style) ───────────────────────────────

/// Reusable box shadows for cards, badges, and sheets.
abstract final class AppShadows {
  AppShadows._();

  /// Two-layer shadow for standard cards (close + soft far).
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha1 = isDark ? 0.25 : 0.12;
    final alpha2 = isDark ? 0.35 : 0.2;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha2),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Lighter shadow for search bar / input wrapper.
  static const List<BoxShadow> input = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Small shadow for icon badges and pills.
  static const List<BoxShadow> badge = [
    BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 3)),
  ];

  /// Shadow for bottom sheet (drawn upward).
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2)),
    BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, -8)),
  ];

  /// Shadow for scrubber label.
  static const List<BoxShadow> scrubber = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(-1, 2)),
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(-3, 4)),
  ];

  /// Gradient tile (explore cards): two-layer.
  static const List<BoxShadow> gradientTile = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x38000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Feature card (Verse/Hadith of the Day) – tinted shadow.
  static List<BoxShadow> featureCardShadow(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
