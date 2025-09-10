import 'package:flutter/material.dart';
import 'tajweed.dart';

/// Arabic text renderer for Qur'anic script.
/// - Uses UthmanicHafs (declared in pubspec).
/// - Forces OpenType features (mark/mkmk) so combining marks anchor on the base.
/// - Tajweed rendering uses `tajweedSpans` with U+06DF overlay **disabled by default**.
class ArabicText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? weight;
  final bool tajweed;

  // Back-compat props used in your project
  final double? size;
  final TextAlign? align;
  final TextStyle? style;
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
    final fs = (fontSize ?? size ?? 26).toDouble();

    // IMPORTANT: no letterSpacing/wordSpacing for Qur'anic Uthmani script.
    final TextStyle resolved = (style ?? const TextStyle()).copyWith(
      fontFamily: 'UthmanicHafs',
      fontSize: fs,
      // heavier by default to match English bold request
      fontWeight: weight ?? FontWeight.w700,
      // generous but not too airy; avoids clipping harakāt
      height: 1.65,
      color: color ?? Theme.of(context).colorScheme.onSurface,

      // Force Arabic shaping/positioning so combining marks attach correctly
      fontFeatures: const <FontFeature>[
        FontFeature.enable('mark'), // GPOS mark-to-base
        FontFeature.enable('mkmk'), // GPOS mark-to-mark
        FontFeature.enable('rlig'), // required ligatures
        FontFeature.enable('calt'), // contextual alternates
      ],
    );

    // Lock line metrics to avoid jitter and clipping.
    final strut = StrutStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: fs,
      height: 1.65,
      forceStrutHeight: true,
    );

    final TextAlign resolvedAlign = align ?? TextAlign.right;

    if (!tajweed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          locale: const Locale('ar'),
          textDirection: TextDirection.rtl,
          textAlign: resolvedAlign,
          style: resolved,
          strutStyle: strut,
          maxLines: maxLines,
          overflow: overflow,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
      );
    }

    // Tajwīd: build colored spans (overlay06df disabled by default).
    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textAlign: resolvedAlign,
        text: TextSpan(
          children: tajweedSpans(
            context,
            text,
            resolved,
            overlay06df: false, // keep false to avoid stray dots
          ),
        ),
        strutStyle: strut,
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
