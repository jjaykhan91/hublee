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
}
