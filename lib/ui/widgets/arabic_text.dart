import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'tajweed.dart';

/// Arabic text renderer for Qur'anic script.
/// - Uses UthmanicHafs (declared in pubspec).
/// - Forces OpenType features (mark/mkmk) so combining marks anchor on the base.
/// - If tajweed=true, uses tajweedSpans(...) from tajweed.dart (which contains a
///   code-only fallback to render U+06DF correctly even on buggy fonts).
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
      fontWeight: weight ?? FontWeight.w500,
      height: 2.0, // generous line-height to avoid clipping diacritics
      color: color ?? Theme.of(context).colorScheme.onSurface,

      // ✅ Force Arabic shaping/positioning so combining marks (e.g. U+06DF) attach.
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

    // Tajwīd: build colored spans (with built-in U+06DF overlay fallback).
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
