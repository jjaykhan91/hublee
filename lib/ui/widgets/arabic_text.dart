import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'tajweed.dart';

class ArabicText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? weight;
  final bool tajweed; // enable only for Qur’an ayah

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize,
    this.weight,
    this.tajweed = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.arabicStyle(
      context,
      fontSize: fontSize,
      weight: weight,
    );

    final child = tajweed
        ? RichText(
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            text: TextSpan(children: tajweedSpans(context, text, style)),
          )
        : Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: style,
          );

    // Make the block sit on the right edge in an LTR layout
    return Align(alignment: Alignment.centerRight, child: child);
  }
}
