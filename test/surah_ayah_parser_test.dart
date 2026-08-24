/// Tests for `2:255`-style search jumps.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/surah_ayah_parser.dart';

void main() {
  test('parses colon, dot, and space', () {
    expect(tryParseSurahAyah('2:255')?.surahId, 2);
    expect(tryParseSurahAyah('2:255')?.ayah, 255);
    expect(tryParseSurahAyah('2.255')?.ayah, 255);
    expect(tryParseSurahAyah('2 255')?.ayah, 255);
  });

  test('rejects junk and out-of-range surahs', () {
    expect(tryParseSurahAyah('mercy'), isNull);
    expect(tryParseSurahAyah('0:1'), isNull);
    expect(tryParseSurahAyah('115:1'), isNull);
    expect(tryParseSurahAyah('2'), isNull);
  });

  test('ayahExistsInChapter rejects 2:999 against 286 verses', () {
    final parsed = tryParseSurahAyah('2:999');
    expect(parsed?.surahId, 2);
    expect(parsed?.ayah, 999);
    expect(ayahExistsInChapter(parsed!.ayah, 286), isFalse);
    expect(ayahExistsInChapter(255, 286), isTrue);
    expect(ayahExistsInChapter(286, 286), isTrue);
    expect(ayahExistsInChapter(0, 286), isFalse);
  });
}
