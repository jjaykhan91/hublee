import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tajweed_extension.dart';

// ===== Dark palette tuned for phones =====
const _ink        = Color(0xFF0B0F14); // canvas
const _surface1   = Color(0xFF11161C); // base surface
const _surface2   = Color(0xFF151B22); // elevated/tiles
const _outline    = Color(0xFF233042); // soft border
const _onSurface  = Color(0xFFE7ECF2); // main text
const _onSurface2 = Color(0xFFB8C2CF); // secondary
const _muted      = Color(0xFF97A6B5); // hints / tertiary
const _primary    = Color(0xFF8AB4FF); // calm blue
const _onPrimary  = Color(0xFF0A1220);
const _secondary  = Color(0xFF7DD3FC);
const _error      = Color(0xFFFF6B6B);

final _lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));

final _darkScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: _primary,
  onPrimary: _onPrimary,
  primaryContainer: Color(0xFF2B3B55),
  onPrimaryContainer: _onSurface,
  secondary: _secondary,
  onSecondary: _onSurface,
  secondaryContainer: Color(0xFF1D2A36),
  onSecondaryContainer: _onSurface,
  tertiary: Color(0xFFB5A7F5),
  onTertiary: _onSurface,
  tertiaryContainer: Color(0xFF292342),
  onTertiaryContainer: _onSurface,
  error: _error,
  onError: _onSurface,
  errorContainer: Color(0xFF3A1E1E),
  onErrorContainer: _onSurface,
  background: _ink,
  onBackground: _onSurface,
  surface: _surface1,
  onSurface: _onSurface,
  surfaceVariant: _surface2,
  onSurfaceVariant: _onSurface2,
  outline: _outline,
  outlineVariant: Color(0xFF1C2532),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFE9EEF5),
  onInverseSurface: Color(0xFF0E1420),
  inversePrimary: Color(0xFF2E6BEA),
);

// Force UthmanicHafs on Arabic-oriented sizes
TextTheme _arabicTextTweaks(TextTheme base) {
  return base.copyWith(
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: 'UthmanicHafs',
      height: 2.0,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: 'UthmanicHafs',
      height: 2.0,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: 'UthmanicHafs',
      fontWeight: FontWeight.w700,
    ),
  );
}

// Add UthmanicHafs as a fallback so English can render Qur’anic symbols.
TextTheme _withFallback(TextTheme base) {
  const ff = ['UthmanicHafs'];
  TextStyle? add(TextStyle? s) => s?.copyWith(fontFamilyFallback: ff);
  return base.copyWith(
    displayLarge:  add(base.displayLarge),
    displayMedium: add(base.displayMedium),
    displaySmall:  add(base.displaySmall),
    headlineLarge: add(base.headlineLarge),
    headlineMedium:add(base.headlineMedium),
    headlineSmall: add(base.headlineSmall),
    titleLarge:    add(base.titleLarge),
    titleMedium:   add(base.titleMedium),
    titleSmall:    add(base.titleSmall),
    bodyLarge:     add(base.bodyLarge),
    bodyMedium:    add(base.bodyMedium),
    bodySmall:     add(base.bodySmall),
    labelLarge:    add(base.labelLarge),
    labelMedium:   add(base.labelMedium),
    labelSmall:    add(base.labelSmall),
  );
}

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final text = _withFallback(_arabicTextTweaks(base.textTheme));

  return base.copyWith(
    colorScheme: _lightScheme,
    textTheme: text,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    cardTheme: const CardThemeData(
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: _lightScheme.surface,
      foregroundColor: _lightScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      hintStyle: TextStyle(color: _muted),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[TajweedTheme.light],
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final text = _withFallback(_arabicTextTweaks(base.textTheme)).apply(
    bodyColor: _onSurface,
    displayColor: _onSurface,
  );

  return base.copyWith(
    colorScheme: _darkScheme,
    textTheme: text,
    scaffoldBackgroundColor: _ink,
    canvasColor: _ink,

    appBarTheme: const AppBarTheme(
      backgroundColor: _ink,
      foregroundColor: _onSurface,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    cardTheme: const CardThemeData(
      color: _surface2,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: _outline, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surface2,
      hintStyle: TextStyle(color: _muted),
      labelStyle: TextStyle(color: _onSurface2),
      prefixIconColor: _onSurface2,
      suffixIconColor: _onSurface2,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _primary, width: 1.4),
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[TajweedTheme.dark],
  );
}
