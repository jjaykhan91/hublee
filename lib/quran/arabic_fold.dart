/// Shared Arabic folding for search matching and snippet highlighting.
///
/// Drops tashkeel/tatweel and folds alef variants so a query like `الله`
/// matches `ٱللَّهِ`. Display text is never modified — only the comparison
/// form is folded. Highlighting keeps the original slices via a parallel
/// offset map.
library;

/// Combining marks and tatweel ignored when comparing Arabic queries.
bool isSkippedArabicMark(int rune) {
  if (rune >= 0x064B && rune <= 0x065F) return true;
  if (rune == 0x0670 || rune == 0x0640) return true;
  if (rune >= 0x06D6 && rune <= 0x06ED) return true;
  return false;
}

/// Maps alef-madda, alef-hamza, and alef-wasla to plain alef.
int foldArabicAlef(int rune) {
  if (rune == 0x0622 || rune == 0x0623 || rune == 0x0625 || rune == 0x0671) {
    return 0x0627;
  }
  return rune;
}

/// Lowercased Arabic with tashkeel removed and alef variants folded.
String foldArabicForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (isSkippedArabicMark(rune)) continue;
    final mapped = foldArabicAlef(rune);
    buffer.write(String.fromCharCode(mapped).toLowerCase());
  }
  return buffer.toString();
}

/// Folded text plus a map back to source offsets for highlighting.
class FoldedArabic {
  const FoldedArabic(this.text, this.sourceOffsets);

  final String text;

  /// `sourceOffsets[i]` is the start offset in the source of folded
  /// character [i].
  final List<int> sourceOffsets;
}

/// Same folding as [foldArabicForSearch], with offsets for highlight slices.
FoldedArabic foldArabicWithMap(String input) {
  final buffer = StringBuffer();
  final orig = <int>[];
  var offset = 0;
  for (final rune in input.runes) {
    final raw = String.fromCharCode(rune);
    final length = raw.length;
    if (isSkippedArabicMark(rune)) {
      offset += length;
      continue;
    }
    final mapped = foldArabicAlef(rune);
    final lower = String.fromCharCode(mapped).toLowerCase();
    for (var i = 0; i < lower.length; i++) {
      buffer.write(lower[i]);
      orig.add(offset);
    }
    offset += length;
  }
  return FoldedArabic(buffer.toString(), orig);
}
