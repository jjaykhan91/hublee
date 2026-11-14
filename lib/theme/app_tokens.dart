/// Central design tokens: colour roles, type scale, spacing, radius,
/// elevation, and motion.
///
/// This file is the single source for every appearance. `app_theme.dart`
/// builds each [ThemeData] from it, and widgets read anything Material has
/// no slot for through [AppPalette.of]. Use these constants instead of
/// inline values so a design change is made in one place.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

// ── Colour roles ─────────────────────────────────────────────────

/// Every colour role for one appearance: light, dark, or paper.
///
/// The [ColorScheme] and all component themes are derived from one of the
/// three constants below, so a role is only ever defined here. The palette
/// is also a [ThemeExtension]: read roles Material has no slot for (the
/// page [canvas], [hairline] borders, [meccan] and [medinan] text) with
/// `AppPalette.of(context)`.
///
/// Every text role meets WCAG AA (4.5:1) on the surfaces it is used on and
/// [outline] meets 3:1; `test/app_palette_test.dart` enforces this.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceMid,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.hairline,
    required this.primary,
    required this.onPrimary,
    required this.primaryTint,
    required this.onPrimaryTint,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryTint,
    required this.onSecondaryTint,
    required this.accent,
    required this.onAccent,
    required this.accentTint,
    required this.onAccentTint,
    required this.meccan,
    required this.medinan,
    required this.error,
    required this.onError,
    required this.errorTint,
    required this.onErrorTint,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  final Brightness brightness;

  /// Page background behind cards and lists.
  final Color canvas;

  /// Cards, sheets, dialogs, and menus.
  final Color surface;

  /// Tonal steps for fills that sit on [surface] or [canvas], from the
  /// faintest ([surfaceLow]) to the strongest ([surfaceHighest]).
  final Color surfaceLow;
  final Color surfaceMid;
  final Color surfaceHigh;
  final Color surfaceHighest;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text and icons.
  final Color inkMuted;

  /// Borders that mark a control's edge (text fields, outlined buttons).
  /// At least 3:1 against [canvas] and [surface].
  final Color outline;

  /// Decorative separators: card borders and dividers.
  final Color hairline;

  /// Brand colour: actions, links, and selected states.
  final Color primary;
  final Color onPrimary;

  /// Quiet brand fill for selected chips, the nav indicator, and tonal
  /// buttons.
  final Color primaryTint;
  final Color onPrimaryTint;

  final Color secondary;
  final Color onSecondary;
  final Color secondaryTint;
  final Color onSecondaryTint;

  /// The single warm accent (gold).
  final Color accent;
  final Color onAccent;
  final Color accentTint;
  final Color onAccentTint;

  /// Text-safe colours for the Meccan and Medinan labels.
  final Color meccan;
  final Color medinan;

  final Color error;
  final Color onError;
  final Color errorTint;
  final Color onErrorTint;

  /// Snackbars and tooltips.
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  /// Brand teal on warm off-white.
  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFFAF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFF6F3EE),
    surfaceMid: Color(0xFFF1EEE8),
    surfaceHigh: Color(0xFFEDEAE3),
    surfaceHighest: Color(0xFFE9E6DF),
    ink: Color(0xFF1B2326),
    inkMuted: Color(0xFF55626A),
    outline: Color(0xFF7C878C),
    hairline: Color(0xFFDEDAD2),
    primary: Color(0xFF0B4D5C),
    onPrimary: Color(0xFFFFFFFF),
    primaryTint: Color(0xFFE3EEF0),
    onPrimaryTint: Color(0xFF0A3540),
    secondary: Color(0xFF3B626C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryTint: Color(0xFFDDE9EC),
    onSecondaryTint: Color(0xFF0A3540),
    accent: Color(0xFF8A5A12),
    onAccent: Color(0xFFFFFFFF),
    accentTint: Color(0xFFF6EBD3),
    onAccentTint: Color(0xFF5A3A08),
    meccan: Color(0xFF8A5A12),
    medinan: Color(0xFF1F6B47),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorTint: Color(0xFFF9DEDC),
    onErrorTint: Color(0xFF7A1611),
    inverseSurface: Color(0xFF2A3336),
    onInverseSurface: Color(0xFFF2F4F3),
    inversePrimary: Color(0xFF7CC7D6),
  );

  /// Near-black with a hint of the brand teal.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF0B1113),
    surface: Color(0xFF131B1E),
    surfaceLow: Color(0xFF10171A),
    surfaceMid: Color(0xFF172125),
    surfaceHigh: Color(0xFF1C272B),
    surfaceHighest: Color(0xFF212D32),
    ink: Color(0xFFE6ECEA),
    inkMuted: Color(0xFFA3B0B3),
    outline: Color(0xFF6A7B80),
    hairline: Color(0xFF2B383C),
    primary: Color(0xFF7CC7D6),
    onPrimary: Color(0xFF06262E),
    primaryTint: Color(0xFF12323A),
    onPrimaryTint: Color(0xFFBFE6EE),
    secondary: Color(0xFFA9CDD4),
    onSecondary: Color(0xFF06262E),
    secondaryTint: Color(0xFF1D353B),
    onSecondaryTint: Color(0xFFCFE9EE),
    accent: Color(0xFFE0B56A),
    onAccent: Color(0xFF3A2804),
    accentTint: Color(0xFF3D2F12),
    onAccentTint: Color(0xFFF3DDB0),
    meccan: Color(0xFFE0B56A),
    medinan: Color(0xFF7FD1A3),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorTint: Color(0xFF5C1A16),
    onErrorTint: Color(0xFFF9DEDC),
    inverseSurface: Color(0xFFE6ECEA),
    onInverseSurface: Color(0xFF1B2326),
    inversePrimary: Color(0xFF0B4D5C),
  );

  /// Warm sepia for long reading sessions.
  static const paper = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF3E6C9),
    surface: Color(0xFFFBF6EC),
    surfaceLow: Color(0xFFF7EEDB),
    surfaceMid: Color(0xFFEFE1C2),
    surfaceHigh: Color(0xFFEADBBA),
    surfaceHighest: Color(0xFFE4D5B3),
    ink: Color(0xFF2A2118),
    inkMuted: Color(0xFF5F4D3A),
    outline: Color(0xFF86745C),
    hairline: Color(0xFFDCCBA6),
    primary: Color(0xFF6B4423),
    onPrimary: Color(0xFFFFFFFF),
    primaryTint: Color(0xFFEAD9B5),
    onPrimaryTint: Color(0xFF4A3018),
    secondary: Color(0xFF5F4D3A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryTint: Color(0xFFE8D5AC),
    onSecondaryTint: Color(0xFF4A3018),
    accent: Color(0xFF7A4E0E),
    onAccent: Color(0xFFFFFFFF),
    accentTint: Color(0xFFEAD9B5),
    onAccentTint: Color(0xFF4A3018),
    meccan: Color(0xFF7A4E0E),
    medinan: Color(0xFF1F5E3F),
    error: Color(0xFF9B1F18),
    onError: Color(0xFFFFFFFF),
    errorTint: Color(0xFFF3D3CB),
    onErrorTint: Color(0xFF7A1611),
    inverseSurface: Color(0xFF3A2E22),
    onInverseSurface: Color(0xFFFBF6EC),
    inversePrimary: Color(0xFFE3B98A),
  );

  /// The active palette, falling back to [light] or [dark] by brightness
  /// when a bare [ThemeData] is in use (some widget tests).
  static AppPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  /// Palettes are fixed constants, so there is nothing to override.
  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceLow: mix(surfaceLow, other.surfaceLow),
      surfaceMid: mix(surfaceMid, other.surfaceMid),
      surfaceHigh: mix(surfaceHigh, other.surfaceHigh),
      surfaceHighest: mix(surfaceHighest, other.surfaceHighest),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      outline: mix(outline, other.outline),
      hairline: mix(hairline, other.hairline),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryTint: mix(primaryTint, other.primaryTint),
      onPrimaryTint: mix(onPrimaryTint, other.onPrimaryTint),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      secondaryTint: mix(secondaryTint, other.secondaryTint),
      onSecondaryTint: mix(onSecondaryTint, other.onSecondaryTint),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentTint: mix(accentTint, other.accentTint),
      onAccentTint: mix(onAccentTint, other.onAccentTint),
      meccan: mix(meccan, other.meccan),
      medinan: mix(medinan, other.medinan),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
      errorTint: mix(errorTint, other.errorTint),
      onErrorTint: mix(onErrorTint, other.onErrorTint),
      inverseSurface: mix(inverseSurface, other.inverseSurface),
      onInverseSurface: mix(onInverseSurface, other.onInverseSurface),
      inversePrimary: mix(inversePrimary, other.inversePrimary),
    );
  }
}

// ── Type scale ───────────────────────────────────────────────────

/// The Latin type scale: six sizes (28, 22, 18, 16, 14, 12) on the
/// platform font.
///
/// `app_theme.dart` maps these onto the Material [TextTheme], so pages keep
/// using `Theme.of(context).textTheme`. Every step carries the bundled
/// Arabic fallback, so Qur'anic symbols and honorifics render inside Latin
/// text.
abstract final class AppType {
  AppType._();

  /// 28/34: page heroes.
  static const display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 22/28: sheet and page titles.
  static const title = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 18/24: app bar and dialog titles.
  static const headline = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 16/24 semibold: card and section titles.
  static const subtitle = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 16/24: running text.
  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 14/21: secondary running text, at the same 1.5 reading line height.
  static const bodyCompact = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 14/20: buttons, chips, and tile titles.
  static const label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 12/16: captions and supporting text.
  static const caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: AppFonts.arabicFallback,
  );

  /// 12/16 medium: badges, overlines, and nav labels.
  static const captionStrong = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: AppFonts.arabicFallback,
  );
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

  /// Large feature cards e.g. Ayah/Hadith/Dhikr of the Day (20px).
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

  /// Extra pixels of list to build off-screen for smoother flings.
  static const double cacheExtent = 480;

  /// [ListView.scrollCacheExtent] for catalog, search, and dictionary lists.
  static const ScrollCacheExtent listCache = ScrollCacheExtent.pixels(
    cacheExtent,
  );

  /// Minimum tappable size (Material accessibility guideline).
  static const double minTouchTarget = 48.0;

  /// The spacing scale. Prefer a step over a one-off number.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ── Elevation and strokes ────────────────────────────────────────

/// Elevation steps. Surfaces are flat and separated by an
/// [AppStroke.hairline] border; only things that float over content are
/// raised.
abstract final class AppElevation {
  AppElevation._();

  /// Cards, app bars, the nav bar, and buttons.
  static const double flat = 0;

  /// Menus, dialogs, and snackbars.
  static const double overlay = 3;
}

/// Border widths.
abstract final class AppStroke {
  AppStroke._();

  /// Card borders and dividers.
  static const double hairline = 1;

  /// Focused text fields.
  static const double focus = 1.5;
}

/// The grab handle at the top of every bottom sheet.
abstract final class AppSheetHandle {
  AppSheetHandle._();

  static const Size size = Size(40, 4);
}

// ── Motion ───────────────────────────────────────────────────────

/// Durations and curves, plus the reduced-motion switch.
abstract final class AppMotion {
  AppMotion._();

  /// State changes: a chip selecting, an icon swapping.
  static const Duration fast = Duration(milliseconds: 120);

  /// Most transitions.
  static const Duration base = Duration(milliseconds: 200);

  /// Content entering a page.
  static const Duration slow = Duration(milliseconds: 320);

  /// Delay between consecutive items in a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Longest total stagger, so a long page never waits to appear.
  static const Duration staggerCap = Duration(milliseconds: 400);

  static const Curve curve = Curves.easeOutCubic;

  /// Whether the system "remove animations" setting is on.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when the reader asked for reduced motion.
  static Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
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

// ── Feature palettes ─────────────────────────────────────────────

/// Product-surface colours that are not derived from [ColorScheme]
/// because they identify a card (ayah, hadith, or dhikr of the day)
/// rather than following the seed.
abstract final class AppColors {
  AppColors._();

  static const verseOfDay = [
    Color(0xFF312E81),
    Color(0xFF4338CA),
    Color(0xFF6366F1),
  ];
  static const verseOfDayTint = Color(0xFF4338CA);

  static const hadithOfDay = [
    Color(0xFF065F46),
    Color(0xFF047857),
    Color(0xFF10B981),
  ];
  static const hadithOfDayTint = Color(0xFF047857);

  static const dhikrOfDay = [
    Color(0xFF4C1D95),
    Color(0xFF6D28D9),
    Color(0xFF8B5CF6),
  ];
  static const dhikrOfDayTint = Color(0xFF6D28D9);

  /// Warm amber used on Meccan surah cards.
  static const meccanAccent = Color(0xFFD4A054);

  /// Cool green used on Medinan surah cards.
  static const medinanAccent = Color(0xFF4CAF7D);

  static const meccanCardGradient = [Color(0xFF3D2E1E), Color(0xFF2A1F14)];
  static const medinanCardGradient = [Color(0xFF1A3529), Color(0xFF0F211A)];

  /// Cream text over the dark surah-card background images.
  static const surahCardOnImage = Color(0xFFF5F0E8);
}
