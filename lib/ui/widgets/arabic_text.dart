/// Reusable widget for rendering Arabic Qur'anic text.
///
/// Uses the user-selected Arabic font (defaulting to KFGQPC Hafs
/// Smart v8) with OpenType features for correct mark placement.
/// When [tajweed] is `true`, the text is rendered as a [RichText]
/// with colour-coded tajweed spans from [tajweedSpans].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/settings_controller.dart';
import '../../services/settings_scope.dart';
import 'tajweed.dart';

/// Resolves the [TextStyle] for the given [ArabicFontOption].
///
/// For the bundled Uthmanic font, returns a style with its family
/// name directly. For Google Fonts options, returns the matching
/// `GoogleFonts` text style.
TextStyle _resolveArabicFontStyle(ArabicFontOption font) {
  switch (font) {
    case ArabicFontOption.uthmanic:
      return const TextStyle(fontFamily: 'KFGQPCQuranicFontHafsSmart');
    case ArabicFontOption.amiri:
      return GoogleFonts.amiri();
    case ArabicFontOption.scheherazade:
      return GoogleFonts.scheherazadeNew();
    case ArabicFontOption.notoNaskh:
      return GoogleFonts.notoNaskhArabic();
  }
}

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
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFontSize = (fontSize ?? size ?? 26).toDouble();

    // Resolve which font to use: override > user setting > default.
    ArabicFontOption font;
    if (fontOverride != null) {
      font = fontOverride!;
    } else {
      try {
        font = SettingsScope.of(context).arabicFont;
      } catch (_) {
        font = ArabicFontOption.uthmanic;
      }
    }

    final baseFontStyle = _resolveArabicFontStyle(font);

    // Build the base style with the resolved font and required
    // OpenType features for correct mark/ligature rendering.
    final TextStyle resolvedStyle =
        (style ?? const TextStyle()).merge(baseFontStyle).copyWith(
      fontSize: resolvedFontSize,
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

    // Strut style ensures consistent line height across different
    // character compositions.
    final strutStyle = StrutStyle(
      fontFamily: baseFontStyle.fontFamily,
      fontSize: resolvedFontSize,
      height: 2.0,
      forceStrutHeight: true,
    );

    final resolvedAlign = align ?? TextAlign.right;

    // Without tajweed: render as a simple Text widget.
    if (!tajweed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
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
        ),
      );
    }

    // With tajweed: render as RichText with colour-coded spans.
    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: resolvedAlign,
        text: TextSpan(
          children: tajweedSpans(context, text, resolvedStyle),
        ),
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
