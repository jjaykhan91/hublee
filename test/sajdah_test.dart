/// Tests for the 15 Hafs sajdah ayahs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/sajdah.dart';

void main() {
  test('covers 15 distinct ayahs', () {
    expect(kSajdahAyahs, hasLength(kSajdahAyahCount));
    expect(kSajdahAyahs.toSet(), hasLength(kSajdahAyahCount));
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

  test('tilawah du\'a is vowelled and not the doubled-qaf typo', () {
    expect(kSajdahArabic, contains('\u0633\u064E\u062C\u064E\u062F\u064E'));
    expect(
      kSajdahArabic,
      isNot(contains('\u0634\u064E\u0642\u0651\u064E\u0642\u064E')),
    );
    expect(kSajdahWhatToDo, contains('qibla'));
    expect(kSajdahMeaning, contains('hearing and sight'));
  });
}
