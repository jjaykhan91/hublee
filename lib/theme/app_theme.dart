/// Builds the Material 3 light and dark [ThemeData] for Hublee.
///
/// Palette colours are hand-tuned for AMOLED-friendly dark mode
/// and a clean, accessible light mode. Reading styles use a generous line
/// height, and every style carries a bundled Arabic fallback family so
/// Qur'anic symbols render inside Latin text.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'tajweed_extension.dart';

// ── Dark-mode palette ────────────────────────────────────────────
const _darkCanvas = Color(0xFF0B0F14);
const _darkSurface = Color(0xFF11161C);
const _darkSurfaceElevated = Color(0xFF151B22);
const _darkOutline = Color(0xFF233042);
const _darkOnSurface = Color(0xFFE7ECF2);
const _darkOnSurfaceSecondary = Color(0xFFB8C2CF);
const _darkMuted = Color(0xFF97A6B5);
const _darkPrimary = Color(0xFF8AB4FF);
const _darkOnPrimary = Color(0xFF0A1220);
const _darkSecondary = Color(0xFF7DD3FC);
const _darkError = Color(0xFFFF6B6B);

/// Light colour scheme seeded from a vivid blue with richer
/// secondary and tertiary tones.
final _lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF2563EB),
  secondary: const Color(0xFF0891B2),
  tertiary: const Color(0xFF7C3AED),
);

/// Custom dark colour scheme with precise hand-picked values.
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _darkPrimary,
  onPrimary: _darkOnPrimary,
  primaryContainer: Color(0xFF2B3B55),
  onPrimaryContainer: _darkOnSurface,
  secondary: _darkSecondary,
  onSecondary: _darkOnSurface,
  secondaryContainer: Color(0xFF1D2A36),
  onSecondaryContainer: _darkOnSurface,
  tertiary: Color(0xFFB5A7F5),
  onTertiary: _darkOnSurface,
  tertiaryContainer: Color(0xFF292342),
  onTertiaryContainer: _darkOnSurface,
  error: _darkError,
  onError: _darkOnSurface,
  errorContainer: Color(0xFF3A1E1E),
  onErrorContainer: _darkOnSurface,
  surface: _darkSurface,
  onSurface: _darkOnSurface,
  surfaceContainerHighest: _darkSurfaceElevated,
  onSurfaceVariant: _darkOnSurfaceSecondary,
  outline: _darkOutline,
  outlineVariant: Color(0xFF1C2532),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFE9EEF5),
  onInverseSurface: Color(0xFF0E1420),
  inversePrimary: Color(0xFF2E6BEA),
);

// ── Arabic text helpers ──────────────────────────────────────────

/// Applies a generous line height to the text styles commonly used for
/// long-form reading.
///
/// This deliberately sets no `fontFamily`. Arabic is always rendered through
/// the `ArabicText` widget, which resolves the user's selected font itself —
/// forcing an Arabic family here would also restyle every English body
/// string in the app.
TextTheme _applyReadingLineHeightToTextTheme(TextTheme base) {
  return base.copyWith(
    bodyLarge: base.bodyLarge?.copyWith(height: 2.0),
    bodyMedium: base.bodyMedium?.copyWith(height: 2.0),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Adds a bundled Arabic face as a fallback family so that any style can
/// render Qur'anic symbols and honorifics (ﷺ, ۩) even when its primary font
/// is a Latin typeface.
///
/// A fallback is only consulted for codepoints the primary family lacks, so
/// Latin text is unaffected.
TextTheme _addArabicFontFallback(TextTheme base) {
  TextStyle? withFallback(TextStyle? style) =>
      style?.copyWith(fontFamilyFallback: AppFonts.arabicFallback);

  return base.copyWith(
    displayLarge: withFallback(base.displayLarge),
    displayMedium: withFallback(base.displayMedium),
    displaySmall: withFallback(base.displaySmall),
    headlineLarge: withFallback(base.headlineLarge),
    headlineMedium: withFallback(base.headlineMedium),
    headlineSmall: withFallback(base.headlineSmall),
    titleLarge: withFallback(base.titleLarge),
    titleMedium: withFallback(base.titleMedium),
    titleSmall: withFallback(base.titleSmall),
    bodyLarge: withFallback(base.bodyLarge),
    bodyMedium: withFallback(base.bodyMedium),
    bodySmall: withFallback(base.bodySmall),
    labelLarge: withFallback(base.labelLarge),
    labelMedium: withFallback(base.labelMedium),
    labelSmall: withFallback(base.labelSmall),
  );
}

// ── Public theme builders ────────────────────────────────────────

/// Builds the light [ThemeData] with Material 3 colour scheme,
/// Arabic text tweaks, and the [TajweedTheme] extension.
ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = _addArabicFontFallback(
    _applyReadingLineHeightToTextTheme(base.textTheme),
  );

  return base.copyWith(
    colorScheme: _lightScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.surface,
      foregroundColor: _lightScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _lightScheme.onSurface,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      hintStyle: TextStyle(color: _darkMuted),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      height: 68,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: <ThemeExtension<dynamic>>[TajweedTheme.light],
  );
}

/// Builds the dark [ThemeData] with an AMOLED-friendly palette,
/// Arabic text tweaks, and the [TajweedTheme] extension.
ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = _addArabicFontFallback(
    _applyReadingLineHeightToTextTheme(base.textTheme),
  ).apply(bodyColor: _darkOnSurface, displayColor: _darkOnSurface);

  return base.copyWith(
    colorScheme: _darkScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: _darkCanvas,
    canvasColor: _darkCanvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkCanvas,
      foregroundColor: _darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black26,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _darkOnSurface,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: _darkSurfaceElevated,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: _darkOutline, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      height: 68,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceElevated,
      hintStyle: TextStyle(color: _darkMuted),
      labelStyle: TextStyle(color: _darkOnSurfaceSecondary),
      prefixIconColor: _darkOnSurfaceSecondary,
      suffixIconColor: _darkOnSurfaceSecondary,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _darkOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _darkPrimary, width: 1.4),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: <ThemeExtension<dynamic>>[TajweedTheme.dark],
  );
}
