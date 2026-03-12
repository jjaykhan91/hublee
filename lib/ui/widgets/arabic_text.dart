/// Reusable widget for rendering Arabic Qur'anic text.
///
/// Uses the user-selected Arabic font (defaulting to KFGQPC Hafs
/// Smart v8) with OpenType features for correct mark placement.
/// When [v4FontFamily] is set, that font is used (V4 font-based
/// tajweed). Otherwise plain text is rendered with no colour coding.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/settings_controller.dart';
import '../../services/settings_scope.dart';

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
/// - [fontSize] / [size]: font size in logical pixels (default 26).
/// - [weight]: font weight (default `w600`).
/// - [align]: text alignment (default `TextAlign.right` for RTL).
/// - [color]: overrides the default `onSurface` colour.
/// - [fontOverride]: force a specific font, ignoring user settings.
/// - [v4FontFamily]: when set, use QPC V4 page font (tajweed in font).
class ArabicText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? weight;
  final double? size;
  final TextAlign? align;
  final TextStyle? style;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  /// When non-null, overrides the user's font setting.
  final ArabicFontOption? fontOverride;

  /// When non-null, use this font family (e.g. QPC V4 page font).
  final String? v4FontFamily;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize,
    this.weight,
    this.size,
    this.align,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
    this.fontOverride,
    this.v4FontFamily,
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

    // When V4 font is set, use it and do not apply software tajweed.
    final useV4Font = v4FontFamily != null && v4FontFamily!.isNotEmpty;
    final effectiveFontStyle = useV4Font
        ? TextStyle(fontFamily: v4FontFamily)
        : _resolveArabicFontStyle(font);

    final TextStyle resolvedStyle =
        (style ?? const TextStyle()).merge(effectiveFontStyle).copyWith(
      fontSize: resolvedFontSize,
      fontWeight: weight ?? FontWeight.w600,
      height: 2.0,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: useV4Font
          ? null
          : const <FontFeature>[
              FontFeature.enable('mark'),
              FontFeature.enable('mkmk'),
              FontFeature.enable('rlig'),
              FontFeature.enable('calt'),
            ],
    );

    final strutStyle = StrutStyle(
      fontFamily: effectiveFontStyle.fontFamily,
      fontSize: resolvedFontSize,
      height: 2.0,
      forceStrutHeight: true,
    );

    final resolvedAlign = align ?? TextAlign.right;

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
}
