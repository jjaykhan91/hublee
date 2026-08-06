/// Splits Qur'anic Arabic into the *words* that word-by-word translation
/// data indexes.
///
/// This is deliberately a pure, dependency-free function: the build-time
/// tool that generates the gloss assets and the reader that renders them
/// both call it, so the two can never disagree about where a word starts.
///
/// Two details make this more than `text.split(' ')`:
///
/// 1. **Annotation marks are not words.** quran.com's Uthmani text emits
///    waqf (pause) signs, sajdah marks and the rub-el-hizb rosette as
///    standalone whitespace-delimited tokens. Word-by-word data does not
///    count them. They are folded onto a neighbouring word rather than
///    dropped, because Qur'anic text must never lose a character.
/// 2. **Ranges are exhaustive.** The returned words tile the whole string
///    with no gaps, so any character offset maps to exactly one word. The
///    reader relies on that to attach tajweed colours to words.
library;

/// One word of Qur'anic text.
///
/// [start] and [end] describe a half-open range into the source string.
/// Consecutive words share a boundary — the whitespace between two words
/// belongs to the earlier one — so the ranges tile the source exactly.
class ArabicWord {
  /// The word as it should be shown on its own, without surrounding spaces.
  final String text;

  /// Inclusive start offset into the source string.
  final int start;

  /// Exclusive end offset into the source string.
  final int end;

  const ArabicWord({
    required this.text,
    required this.start,
    required this.end,
  });

  @override
  String toString() => 'ArabicWord($start..$end, "$text")';
}

/// Code points that are Qur'anic annotation rather than letters: pause
/// marks, sajdah, rub-el-hizb, end-of-ayah and its digits, plus
/// bidirectional controls. A token built only from these is not a word.
bool _isAnnotationCodePoint(int cp) =>
    (cp >= 0x0600 && cp <= 0x0605) || // Arabic number/year signs
    (cp >= 0x0660 && cp <= 0x0669) || // Arabic-Indic digits (follow U+06DD)
    (cp >= 0x06D6 && cp <= 0x06ED) || // waqf marks, sajdah, rub, end-of-ayah
    cp == 0x08E2 || // disputed end of ayah
    (cp >= 0x200B && cp <= 0x200F) || // zero-width + directional marks
    cp == 0x061C; // Arabic letter mark

bool _isAnnotationOnly(String token) {
  var sawAnnotation = false;
  for (final cp in token.runes) {
    if (!_isAnnotationCodePoint(cp)) return false;
    sawAnnotation = true;
  }
  return sawAnnotation;
}

/// A whitespace-delimited token and where it sits in the source.
class _Token {
  final String text;
  final int start;
  final int end;
  const _Token(this.text, this.start, this.end);
}

List<_Token> _tokenize(String text) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < text.length) {
    while (i < text.length && _isWhitespace(text.codeUnitAt(i))) {
      i++;
    }
    if (i >= text.length) break;
    final start = i;
    while (i < text.length && !_isWhitespace(text.codeUnitAt(i))) {
      i++;
    }
    tokens.add(_Token(text.substring(start, i), start, i));
  }
  return tokens;
}

bool _isWhitespace(int cu) =>
    cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D || cu == 0xA0;

/// Splits [text] into words, folding annotation-only tokens into a
/// neighbouring word so that no character is lost.
///
/// An annotation that appears *before* any word (a leading rub-el-hizb, for
/// example) folds forwards onto the word that follows it; every other
/// annotation folds backwards onto the word it trails.
///
/// Returns an empty list for text with no words.
List<ArabicWord> segmentArabicWords(String text) {
  final tokens = _tokenize(text);
  if (tokens.isEmpty) return const [];

  // Group token indices into words.
  final groups = <List<int>>[];
  final pendingPrefix = <int>[];
  for (var i = 0; i < tokens.length; i++) {
    if (_isAnnotationOnly(tokens[i].text)) {
      if (groups.isEmpty) {
        pendingPrefix.add(i);
      } else {
        groups.last.add(i);
      }
      continue;
    }
    groups.add([...pendingPrefix, i]);
    pendingPrefix.clear();
  }
  // Text consisting only of annotation still yields one word, so callers
  // never silently drop content.
  if (groups.isEmpty && pendingPrefix.isNotEmpty) {
    groups.add(pendingPrefix.toList());
  }

  final words = <ArabicWord>[];
  for (var g = 0; g < groups.length; g++) {
    final group = groups[g];
    // Ranges tile the source: start at the previous word's end (0 for the
    // first) and run up to the next word's first token.
    final start = g == 0 ? 0 : words.last.end;
    final end = g == groups.length - 1
        ? text.length
        : tokens[groups[g + 1].first].start;
    final display = text
        .substring(tokens[group.first].start, tokens[group.last].end)
        .trim();
    words.add(ArabicWord(text: display, start: start, end: end));
  }
  return words;
}

/// Returns the index of the word containing [offset], or `null` when the
/// offset falls outside [words].
///
/// [words] must come from [segmentArabicWords] on the same string, so the
/// ranges are contiguous and sorted.
int? wordIndexAtOffset(List<ArabicWord> words, int offset) {
  var low = 0;
  var high = words.length - 1;
  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final word = words[mid];
    if (offset < word.start) {
      high = mid - 1;
    } else if (offset >= word.end) {
      low = mid + 1;
    } else {
      return mid;
    }
  }
  return null;
}
