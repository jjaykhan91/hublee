/// Builds the Material 3 [ThemeData] for each appearance from the tokens in
/// `app_tokens.dart`.
///
/// Nothing here picks a colour, size, or radius of its own: light, dark, and
/// paper all go through [_buildTheme] with a different [AppPalette], so the
/// three appearances share one set of component rules. Surfaces are flat and
/// separated by a hairline border instead of a shadow.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'tajweed_extension.dart';

const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
  },
);

/// The [AppType] scale mapped onto Material's text slots.
///
/// No style sets a `fontFamily`: Arabic is always rendered through the
/// `ArabicText` widget, which resolves the reader's chosen font and its own
/// line height. Colours are filled in by the theme from the colour scheme.
const _textTheme = TextTheme(
  displayLarge: AppType.display,
  displayMedium: AppType.display,
  displaySmall: AppType.display,
  headlineLarge: AppType.display,
  headlineMedium: AppType.display,
  headlineSmall: AppType.title,
  titleLarge: AppType.title,
  titleMedium: AppType.subtitle,
  titleSmall: AppType.label,
  bodyLarge: AppType.body,
  bodyMedium: AppType.bodyCompact,
  bodySmall: AppType.caption,
  labelLarge: AppType.label,
  labelMedium: AppType.captionStrong,
  labelSmall: AppType.captionStrong,
);

/// Maps palette roles onto every [ColorScheme] slot, so Material widgets
/// and `Theme.of(context).colorScheme` agree with [AppPalette].
ColorScheme _schemeFor(AppPalette p) => ColorScheme(
  brightness: p.brightness,
  primary: p.primary,
  onPrimary: p.onPrimary,
  primaryContainer: p.primaryTint,
  onPrimaryContainer: p.onPrimaryTint,
  secondary: p.secondary,
  onSecondary: p.onSecondary,
  secondaryContainer: p.secondaryTint,
  onSecondaryContainer: p.onSecondaryTint,
  tertiary: p.accent,
  onTertiary: p.onAccent,
  tertiaryContainer: p.accentTint,
  onTertiaryContainer: p.onAccentTint,
  error: p.error,
  onError: p.onError,
  errorContainer: p.errorTint,
  onErrorContainer: p.onErrorTint,
  surface: p.surface,
  onSurface: p.ink,
  surfaceDim: p.surfaceHighest,
  surfaceBright: p.surface,
  surfaceContainerLowest: p.surface,
  surfaceContainerLow: p.surfaceLow,
  surfaceContainer: p.surfaceMid,
  surfaceContainerHigh: p.surfaceHigh,
  surfaceContainerHighest: p.surfaceHighest,
  onSurfaceVariant: p.inkMuted,
  outline: p.outline,
  outlineVariant: p.hairline,
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: p.inverseSurface,
  onInverseSurface: p.onInverseSurface,
  inversePrimary: p.inversePrimary,
  // Elevation never tints a surface; depth comes from the tonal steps.
  surfaceTint: Colors.transparent,
);

ThemeData _buildTheme(AppPalette p, TajweedTheme tajweed) {
  final scheme = _schemeFor(p);
  final isDark = p.brightness == Brightness.dark;

  const buttonMinimumSize = Size(64, AppSpacing.minTouchTarget);
  final hairline = BorderSide(color: p.hairline, width: AppStroke.hairline);
  final controlEdge = BorderSide(color: p.outline, width: AppStroke.hairline);

  OutlineInputBorder inputBorder(BorderSide side) =>
      OutlineInputBorder(borderRadius: AppRadius.input, borderSide: side);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: _textTheme,
    scaffoldBackgroundColor: p.canvas,
    iconTheme: IconThemeData(color: p.ink),
    dividerTheme: DividerThemeData(
      color: p.hairline,
      thickness: AppStroke.hairline,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: AppElevation.flat,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: hairline,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.canvas,
      foregroundColor: p.ink,
      elevation: AppElevation.flat,
      scrolledUnderElevation: AppElevation.flat,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: AppType.headline.copyWith(color: p.ink),
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : null,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: TextStyle(color: p.inkMuted),
      labelStyle: TextStyle(color: p.inkMuted),
      prefixIconColor: p.inkMuted,
      suffixIconColor: p.inkMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder(controlEdge),
      enabledBorder: inputBorder(controlEdge),
      disabledBorder: inputBorder(hairline),
      focusedBorder: inputBorder(
        BorderSide(color: p.primary, width: AppStroke.focus),
      ),
      errorBorder: inputBorder(BorderSide(color: p.error)),
      focusedErrorBorder: inputBorder(
        BorderSide(color: p.error, width: AppStroke.focus),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(AppElevation.flat),
      backgroundColor: WidgetStatePropertyAll(p.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: p.primary, width: AppStroke.focus)
            : controlEdge,
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.input),
      ),
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
        maxHeight: 56,
      ),
      textStyle: WidgetStatePropertyAll(AppType.body.copyWith(color: p.ink)),
      hintStyle: WidgetStatePropertyAll(
        AppType.body.copyWith(color: p.inkMuted),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: AppElevation.flat,
        minimumSize: buttonMinimumSize,
        textStyle: AppType.label,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: AppElevation.flat,
        backgroundColor: p.primaryTint,
        foregroundColor: p.onPrimaryTint,
        shadowColor: Colors.transparent,
        minimumSize: buttonMinimumSize,
        textStyle: AppType.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: controlEdge,
        minimumSize: buttonMinimumSize,
        textStyle: AppType.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: AppType.label),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.primaryTint,
      checkmarkColor: p.onPrimaryTint,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      pressElevation: AppElevation.flat,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BorderSide(color: p.primaryTint, width: AppStroke.hairline)
            : controlEdge,
      ),
      labelStyle: AppType.label.copyWith(
        color: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.inkMuted;
          }
          return states.contains(WidgetState.selected)
              ? p.onPrimaryTint
              : p.ink;
        }),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: p.inkMuted),
    tabBarTheme: TabBarThemeData(
      indicatorColor: p.primary,
      labelColor: p.primary,
      unselectedLabelColor: p.inkMuted,
      dividerColor: p.hairline,
      labelStyle: AppType.label.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppType.label,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.canvas,
      elevation: AppElevation.flat,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.primaryTint,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.onPrimaryTint
              : p.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppType.captionStrong.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w600,
              )
            : AppType.captionStrong.copyWith(color: p.inkMuted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.canvas,
      elevation: AppElevation.flat,
      indicatorColor: p.primaryTint,
      selectedIconTheme: IconThemeData(color: p.onPrimaryTint),
      unselectedIconTheme: IconThemeData(color: p.inkMuted),
      selectedLabelTextStyle: AppType.captionStrong.copyWith(
        color: p.ink,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AppType.captionStrong.copyWith(
        color: p.inkMuted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.inverseSurface,
      contentTextStyle: AppType.bodyCompact.copyWith(color: p.onInverseSurface),
      actionTextColor: p.inversePrimary,
      closeIconColor: p.onInverseSurface,
      elevation: AppElevation.overlay,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      modalElevation: AppElevation.flat,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      clipBehavior: Clip.antiAlias,
      dragHandleColor: p.outline,
      dragHandleSize: AppSheetHandle.size,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.overlay,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.featureCard),
      titleTextStyle: AppType.headline.copyWith(color: p.ink),
      contentTextStyle: AppType.bodyCompact.copyWith(color: p.inkMuted),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chip,
        side: hairline,
      ),
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    extensions: <ThemeExtension<dynamic>>[p, tajweed],
  );
}

// ── Public theme builders ────────────────────────────────────────

/// The light appearance: brand teal on warm off-white.
ThemeData buildLightTheme() =>
    _buildTheme(AppPalette.light, TajweedTheme.light);

/// The dark appearance: near-black surfaces with a lifted teal.
ThemeData buildDarkTheme() => _buildTheme(AppPalette.dark, TajweedTheme.dark);

/// Warm paper/sepia appearance for long reading sessions.
ThemeData buildPaperTheme() =>
    _buildTheme(AppPalette.paper, TajweedTheme.light);
