import 'package:flutter/material.dart';
import 'tajweed.dart';

/// Arabic text renderer for Qur'anic script (Hafs Smart v8).
/// - Uses KFGQPC Hafs Smart v8 font (declared in pubspec).
/// - Forces useful OpenType features.
/// - If tajweed=true, uses tajweedSpans(...) with U+06DF fallback overlay.
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

    // IMPORTANT: do not set letterSpacing/wordSpacing for Qur'anic script.
    final TextStyle resolved = (style ?? const TextStyle()).copyWith(
      // 👇 Make sure this matches the family name in pubspec.yaml
      fontFamily: 'KFGQPCQuranicFontHafsSmart',
      fontSize: fs,
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

    final strut = StrutStyle(
      fontFamily: 'KFGQPCQuranicFontHafsSmart',
      fontSize: fs,
      height: 2.0,
      forceStrutHeight: true,
    );

    final TextAlign resolvedAlign = align ?? TextAlign.right;

    if (!tajweed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
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

    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: resolvedAlign,
        text: TextSpan(children: tajweedSpans(context, text, resolved)),
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
