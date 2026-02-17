/// Reusable widget for rendering Arabic Qur'anic text.
///
/// Uses the KFGQPC Hafs Smart v8 font (declared in `pubspec.yaml`)
/// with OpenType features for correct mark placement. When
/// [tajweed] is `true`, the text is rendered as a [RichText] with
/// colour-coded tajweed spans from [tajweedSpans].
library;

import 'package:flutter/material.dart';

import 'tajweed.dart';

/// Renders Arabic text in the KFGQPC Hafs Smart font.
///
/// Key properties:
/// - [tajweed]: when `true`, colour-codes recitation rules.
/// - [fontSize] / [size]: font size in logical pixels (default 26).
/// - [weight]: font weight (default `w600`).
/// - [align]: text alignment (default `TextAlign.right` for RTL).
/// - [color]: overrides the default `onSurface` colour.
class ArabicText extends StatelessWidget {
  /// The Arabic string to render.
  final String text;

  /// Font size in logical pixels. Takes precedence over [size].
  final double? fontSize;

  /// Font weight for the Arabic text.
  final FontWeight? weight;

  /// Whether to apply tajweed colour rules.
  final bool tajweed;

  /// Alias for [fontSize] (kept for backward compatibility).
  final double? size;

  /// Text alignment (defaults to [TextAlign.right]).
  final TextAlign? align;

  /// Base style to merge into (optional override).
  final TextStyle? style;

  /// Explicit text colour; overrides the theme colour.
  final Color? color;

  final int? maxLines;
  final TextOverflow? overflow;

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
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFontSize = (fontSize ?? size ?? 26).toDouble();

    // Build the base style with the Qur'anic font and required
    // OpenType features for correct mark/ligature rendering.
    final TextStyle resolvedStyle = (style ?? const TextStyle()).copyWith(
      fontFamily: 'KFGQPCQuranicFontHafsSmart',
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
      fontFamily: 'KFGQPCQuranicFontHafsSmart',
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
