/// Exact-word vs substring ranking for English search queries.
library;

/// True when [needle] appears as a whole word in [haystack].
///
/// Case-insensitive. "mercy" matches "Show mercy" but not "merciful".
bool englishExactWordMatch(String haystack, String needle) {
  final trimmed = needle.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(
    '\\b${RegExp.escape(trimmed)}\\b',
    caseSensitive: false,
  ).hasMatch(haystack);
}

/// A short excerpt of [text] around the match at [matchIndex], cut at
/// word boundaries and marked with an ellipsis where text was dropped.
///
/// Keeps about [before] characters ahead of the match and [after] behind
/// it, then widens to whole words so a snippet never starts "…t bear".
/// Punctuation left at the cut, as in "…. Had", is dropped.
String searchExcerpt(
  String text,
  int matchIndex,
  int matchLength, {
  int before = 40,
  int after = 60,
}) {
  var start = (matchIndex - before).clamp(0, text.length);
  var end = (matchIndex + matchLength + after).clamp(0, text.length);

  // Back up to the start of the word the cut landed in.
  while (start > 0 && !_isBreak(text.codeUnitAt(start - 1))) {
    start--;
  }
  // Run on to the end of the word the cut landed in.
  while (end < text.length && !_isBreak(text.codeUnitAt(end))) {
    end++;
  }

  var excerpt = text.substring(start, end);
  if (start > 0) {
    excerpt = excerpt.replaceFirst(RegExp(r'^[\s.,;:!?—-]+'), '');
  }
  excerpt = excerpt.trim();
  if (start > 0) excerpt = '…$excerpt';
  if (end < text.length) excerpt = '$excerpt…';
  return excerpt;
}

bool _isBreak(int codeUnit) =>
    codeUnit == 0x20 || codeUnit == 0x0A || codeUnit == 0x09;
