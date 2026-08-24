/// Tests for Arabic search folding (tashkeel stripped, alef variants folded).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/arabic_fold.dart';

void main() {
  test('الله matches ٱللَّهِ', () {
    expect(foldArabicForSearch('ٱللَّهِ'), foldArabicForSearch('الله'));
    expect(
      foldArabicForSearch('ٱللَّهِ').contains(foldArabicForSearch('الله')),
      isTrue,
    );
  });

  test('fold map keeps source offsets for highlighting', () {
    const text = 'ٱللَّهِ';
    final folded = foldArabicWithMap(text);
    expect(folded.text, foldArabicForSearch(text));
    expect(folded.sourceOffsets, isNotEmpty);
    expect(folded.sourceOffsets.first, 0);
  });
}
