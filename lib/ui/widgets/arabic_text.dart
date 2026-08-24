/// Reusable widget for rendering Arabic Qur'anic text.
///
/// Uses the user-selected Arabic font (defaulting to KFGQPC Hafs
/// Smart v8) with OpenType features for correct mark placement.
/// When [tajweed] is `true`, the text is rendered as a [RichText]
/// with colour-coded tajweed spans from [tajweedSpans].
library;

import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../services/settings_scope.dart';
import '../../theme/app_tokens.dart';
import 'search_highlight.dart';
import 'tajweed.dart';

/// Resolves the [TextStyle] for the given [ArabicFontOption].
///
/// Every option resolves to a family bundled in the app, so Arabic rendering
/// never depends on a network fetch or a platform font.
///
/// [AppFonts.uthmanic] carries a fallback because it only covers PUA glyphs:
/// the reader switches to standard Uthmanic Unicode whenever tajweed is
/// enabled, and that text would otherwise have no glyphs at all.
TextStyle _resolveArabicFontStyle(ArabicFontOption font) {
  switch (font) {
    case ArabicFontOption.uthmanic:
      return const TextStyle(
        fontFamily: AppFonts.uthmanic,
        fontFamilyFallback: AppFonts.arabicFallback,
      );
    case ArabicFontOption.amiri:
      return const TextStyle(fontFamily: AppFonts.amiri);
    case ArabicFontOption.scheherazade:
      return const TextStyle(
        fontFamily: AppFonts.scheherazade,
        fontFamilyFallback: AppFonts.arabicFallback,
      );
    case ArabicFontOption.notoNaskh:
      return const TextStyle(
        fontFamily: AppFonts.notoNaskh,
        fontFamilyFallback: AppFonts.arabicFallback,
      );
  }
}

/// Resolves the font the user has selected, honouring [fontOverride].
///
/// Falls back to [ArabicFontOption.uthmanic] when no [SettingsScope] is in
/// scope, so Arabic still renders in previews and tests.
ArabicFontOption resolveArabicFont(
  BuildContext context, {
  ArabicFontOption? fontOverride,
}) {
  if (fontOverride != null) return fontOverride;
  try {
    return SettingsScope.of(context).arabicFont;
  } catch (_) {
    return ArabicFontOption.uthmanic;
  }
}

/// Builds the text style Hublee uses for Qur'anic Arabic.
///
/// Shared by [ArabicText] and the word-by-word reader so both render identical
/// typography — OpenType features included. Anything drawing Qur'anic Arabic
/// should come through here rather than assembling its own [TextStyle].
TextStyle arabicTextStyle(
  BuildContext context, {
  required double fontSize,
  ArabicFontOption? fontOverride,
  FontWeight? weight,
  Color? color,
  TextStyle? base,
}) {
  final font = resolveArabicFont(context, fontOverride: fontOverride);
  return (base ?? const TextStyle())
      .merge(_resolveArabicFontStyle(font))
      .copyWith(
        fontSize: fontSize,
        fontWeight: weight ?? FontWeight.w600,
        height: 2.0,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontFeatures: const <FontFeature>[
          FontFeature.enable('mark'),
          FontFeature.enable('mkmk'),
          FontFeature.enable('rlig'),
          FontFeature.enable('calt'),
        ],
      );
}

/// Strut matching [arabicTextStyle], so line height stays constant regardless
/// of which marks a line happens to contain.
///
/// Height 2.0 with [StrutStyle.forceStrutHeight] is the clearance verified
/// against dense tashkeel (e.g. 2:255) at maximum Arabic zoom. Do not lower
/// it without re-running `test/arabic_rendering_test.dart` overflow tests.
StrutStyle arabicStrutStyle(TextStyle style) => StrutStyle(
  fontFamily: style.fontFamily,
  fontFamilyFallback: style.fontFamilyFallback,
  fontSize: style.fontSize,
  height: 2.0,
  forceStrutHeight: true,
);

/// Renders Arabic text in the user-selected Arabic font.
///
/// Key properties:
/// - [tajweed]: when `true`, colour-codes recitation rules.
/// - [fontSize] / [size]: font size in logical pixels (default 26).
/// - [weight]: font weight (default `w600`).
/// - [align]: text alignment (default `TextAlign.right` for RTL).
/// - [color]: overrides the default `onSurface` colour.
/// - [fontOverride]: force a specific font, ignoring user settings.
class ArabicText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? weight;
  final bool tajweed;
  final double? size;
  final TextAlign? align;
  final TextStyle? style;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  /// When non-null, overrides the user's font setting.
  final ArabicFontOption? fontOverride;

  /// When set (and [tajweed] is off), bolds words that contain this query.
  final String? highlightQuery;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize,
    this.weight,
    this.tajweed = false,
    this.size,
    this.align,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
    this.fontOverride,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFontSize = (fontSize ?? size ?? 26).toDouble();

    final resolvedStyle = arabicTextStyle(
      context,
      fontSize: resolvedFontSize,
      fontOverride: fontOverride,
      weight: weight,
      color: color,
      base: style,
    );
    final strutStyle = arabicStrutStyle(resolvedStyle);
    final resolvedAlign = align ?? TextAlign.right;
    // Honour the requested alignment. Arabic defaults to the right edge, but a
    // centred header must actually centre rather than be pinned right.
    final alignment = switch (resolvedAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      _ => Alignment.centerRight,
    };

    // Without tajweed: plain text, or highlighted search hits.
    if (!tajweed) {
      final highlight = highlightQuery?.trim();
      final child = highlight == null || highlight.isEmpty
          ? Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: resolvedAlign,
              style: resolvedStyle,
              strutStyle: strutStyle,
              maxLines: maxLines,
              overflow: overflow,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            )
          : HighlightedSnippet(
              text,
              query: highlight,
              style: resolvedStyle,
              strutStyle: strutStyle,
              maxLines: maxLines,
              overflow: overflow ?? TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: resolvedAlign,
            );
      return Align(alignment: alignment, child: child);
    }

    // With tajweed: render as RichText with colour-coded spans.
    return Align(
      alignment: alignment,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: resolvedAlign,
        text: TextSpan(children: tajweedSpans(context, text, resolvedStyle)),
        strutStyle: strutStyle,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.visible,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}
