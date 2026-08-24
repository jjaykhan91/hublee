/// Bold the words in a search snippet that contain the query.
library;

import 'package:flutter/material.dart';

import '../../quran/arabic_fold.dart';

/// Letters, numbers, and combining marks (tashkeel) count as part of a word
/// so a match is not split from its diacritics.
final _wordChar = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);

/// One run of snippet text, either a query hit or surrounding context.
typedef HighlightSegment = ({String text, bool match});

/// Splits [text] so every word that contains a [query] term is a match.
///
/// Matching is case-insensitive. Arabic tashkeel is ignored for matching
/// but kept in the returned slices. Multi-word queries highlight each term.
List<HighlightSegment> splitQueryHighlights(String text, String query) {
  final terms = query
      .trim()
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
  if (text.isEmpty || terms.isEmpty) {
    return text.isEmpty
        ? const <HighlightSegment>[]
        : [(text: text, match: false)];
  }

  final folded = foldArabicWithMap(text);
  if (folded.text.isEmpty) return [(text: text, match: false)];

  final ranges = <({int start, int end})>[];
  for (final term in terms) {
    final needle = foldArabicWithMap(term).text;
    if (needle.isEmpty) continue;
    var from = 0;
    while (from < folded.text.length) {
      final index = folded.text.indexOf(needle, from);
      if (index < 0) break;
      var start = folded.sourceOffsets[index];
      final lastFolded = index + needle.length - 1;
      var end = lastFolded + 1 < folded.sourceOffsets.length
          ? folded.sourceOffsets[lastFolded + 1]
          : text.length;
      while (start > 0 && _isWordCharAt(text, start - 1)) {
        start--;
      }
      while (end < text.length && _isWordCharAt(text, end)) {
        end++;
      }
      ranges.add((start: start, end: end));
      from = index + needle.length;
    }
  }
  if (ranges.isEmpty) return [(text: text, match: false)];

  ranges.sort((a, b) => a.start.compareTo(b.start));
  final merged = <({int start, int end})>[ranges.first];
  for (var i = 1; i < ranges.length; i++) {
    final next = ranges[i];
    final last = merged.last;
    if (next.start <= last.end) {
      merged[merged.length - 1] = (
        start: last.start,
        end: next.end > last.end ? next.end : last.end,
      );
    } else {
      merged.add(next);
    }
  }

  final parts = <HighlightSegment>[];
  var cursor = 0;
  for (final range in merged) {
    if (range.start > cursor) {
      parts.add((text: text.substring(cursor, range.start), match: false));
    }
    parts.add((text: text.substring(range.start, range.end), match: true));
    cursor = range.end;
  }
  if (cursor < text.length) {
    parts.add((text: text.substring(cursor), match: false));
  }
  return parts;
}

bool _isWordCharAt(String text, int index) {
  if (index < 0 || index >= text.length) return false;
  var end = index + 1;
  if (end < text.length) {
    final unit = text.codeUnitAt(index);
    final next = text.codeUnitAt(end);
    if (unit >= 0xD800 && unit <= 0xDBFF && next >= 0xDC00 && next <= 0xDFFF) {
      end++;
    }
  }
  return _wordChar.hasMatch(text.substring(index, end));
}

/// Snippet text with query hits in bold (and the theme primary colour).
class HighlightedSnippet extends StatelessWidget {
  const HighlightedSnippet(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.matchStyle,
    this.maxLines = 3,
    this.overflow = TextOverflow.ellipsis,
    this.textDirection,
    this.textAlign,
    this.strutStyle,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? matchStyle;
  final int? maxLines;
  final TextOverflow overflow;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final hit =
        matchStyle ??
        base.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        );
    final spans = [
      for (final part in splitQueryHighlights(text, query))
        TextSpan(text: part.text, style: part.match ? hit : null),
    ];

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      textAlign: textAlign,
      strutStyle: strutStyle,
    );
  }
}
