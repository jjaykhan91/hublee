/// Renders the verse as one flowing line of Arabic (quran.com style).
/// Tap a word to select it; the selected word is highlighted and the
/// translation is shown in a fixed bar (via onWordSelected).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../quran/word_by_word_repository.dart';
import '../../services/settings_controller.dart';
import '../../services/settings_scope.dart';

/// Light teal for selected-word highlight.
const _kWordHighlightTeal = Color(0xFF4DB6AC);

/// Displays the verse as one flowing line of Arabic (quran.com style).
/// Each word is tappable; tap to select (highlight in teal) and report
/// via [onWordSelected]. Tap same word again to clear.
class TappableArabicWords extends StatefulWidget {
  const TappableArabicWords({
    super.key,
    required this.words,
    required this.fontSize,
    this.fontWeight = FontWeight.bold,
    this.v4FontFamily,
    this.color,
    this.selectedWordPosition,
    this.onWordSelected,
  });

  final List<WordByWordItem> words;
  final double fontSize;
  final FontWeight fontWeight;
  final String? v4FontFamily;
  final Color? color;
  final int? selectedWordPosition;
  /// Called when the user taps a word (passes the word) or taps the same word again (passes null).
  final ValueChanged<WordByWordItem?>? onWordSelected;

  @override
  State<TappableArabicWords> createState() => _TappableArabicWordsState();
}

class _TappableArabicWordsState extends State<TappableArabicWords> {
  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    if (words.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final resolvedColor = widget.color ?? theme.colorScheme.onSurface;
    ArabicFontOption font;
    try {
      font = SettingsScope.of(context).arabicFont;
    } catch (_) {
      font = ArabicFontOption.uthmanic;
    }
    final baseStyle = _arabicTextStyle(context, font, resolvedColor);

    // One flowing line of Arabic (quran.com style): each word is a tappable TextSpan.
    // Only the selected word is highlighted in teal; no per-word colors, no underline.
    final spans = <InlineSpan>[];
    for (final w in words) {
      final isSelected = widget.selectedWordPosition == w.position;
      final style = baseStyle.copyWith(
        color: isSelected ? _kWordHighlightTeal : resolvedColor,
      );
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          final same = widget.selectedWordPosition == w.position;
          widget.onWordSelected?.call(same ? null : w);
        };
      spans.add(TextSpan(
        text: w.arabic,
        style: style,
        recognizer: recognizer,
      ));
      // Space between words (RTL: space after each word).
      spans.add(TextSpan(text: ' ', style: baseStyle));
    }
    if (spans.isNotEmpty) spans.removeLast(); // trailing space

    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        text: TextSpan(style: baseStyle, children: spans),
      ),
    );
  }

  TextStyle _arabicTextStyle(
    BuildContext context,
    ArabicFontOption font,
    Color textColor,
  ) {
    final base = font == ArabicFontOption.uthmanic
        ? const TextStyle(fontFamily: 'KFGQPCQuranicFontHafsSmart')
        : (font == ArabicFontOption.amiri
            ? GoogleFonts.amiri()
            : (font == ArabicFontOption.scheherazade
                ? GoogleFonts.scheherazadeNew()
                : GoogleFonts.notoNaskhArabic()));
    return (widget.v4FontFamily != null && widget.v4FontFamily!.isNotEmpty
            ? TextStyle(fontFamily: widget.v4FontFamily)
            : base)
        .copyWith(
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
      color: textColor,
      height: 2.0,
    );
  }

}
