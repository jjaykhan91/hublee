/// Tests for the 15 Hafs sajdah ayahs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/sajdah.dart';

void main() {
  test('covers 15 distinct ayahs', () {
    expect(kSajdahAyahs, hasLength(15));
  });

  test('Ayat al-Kursi is not a sajdah', () {
    expect(isSajdahAyah(2, 255), isFalse);
  });

  test('known sajdah verses match', () {
    expect(isSajdahAyah(96, 19), isTrue);
    expect(isSajdahAyah(22, 18), isTrue);
    expect(isSajdahAyah(22, 77), isTrue);
  });

  test('detects the ۩ marker', () {
    expect(hasSajdahMarker('word \u06E9'), isTrue);
    expect(hasSajdahMarker('plain'), isFalse);
  });
}
