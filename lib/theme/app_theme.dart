import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme: elegant, soft, premium-feeling.
class AppTheme {
  static const _seed = Color(0xFF1E293B);

  // Arabic + Latin typography
  static TextTheme _textTheme(Brightness b) {
    final base = GoogleFonts.interTextTheme(
      b == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(letterSpacing: -0.2),
      headlineSmall: base.headlineSmall?.copyWith(letterSpacing: -0.1),
      titleLarge:   base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium:  base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge:    base.bodyLarge?.copyWith(height: 1.35),
      bodyMedium:   base.bodyMedium?.copyWith(height: 1.35),
      labelMedium:  base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  /// Arabic text style helper (Noto Naskh Arabic is readable + classic).
  static TextStyle arabicStyle(BuildContext context, {double? fontSize, FontWeight? weight}) {
    final s = Theme.of(context).textTheme.bodyLarge;
    return (s ?? const TextStyle()).copyWith(
      // Use Uthmanic Hafs everywhere for Arabic
      fontFamily: 'UthmanicHafs',
      fontSize: fontSize ?? (s?.fontSize ?? 18),
      fontWeight: weight ?? FontWeight.w500,
      height: 1.9, // Mushaf-like line height
    );
  }


  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface,
        ),
      ),
      // ✅ Flutter’s ThemeData.cardTheme expects CardThemeData
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(space: 12, thickness: 0.6),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        isDense: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    final baseLight = light();
    return baseLight.copyWith(
      colorScheme: scheme,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: baseLight.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      // keep CardThemeData, ListTileThemeData etc. from baseLight
    );
  }
}
