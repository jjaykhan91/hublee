/// Catalog integrity for the salah guide.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/guidance/salah_guide.dart';

bool _hasArabic(String text) => text.contains(RegExp(r'[\u0600-\u06FF]'));

bool _hasPua(String text) =>
    text.codeUnits.any((unit) => unit >= 0xE000 && unit <= 0xF8FF);

void main() {
  test('hub tiles cover every section id', () {
    expect(salahHubTiles.map((tile) => tile.id).toList(), [
      SalahSectionId.fard,
      SalahSectionId.sunnah,
      SalahSectionId.nawafil,
      SalahSectionId.howTo,
      SalahSectionId.recite,
    ]);
  });

  test('prayers have Arabic names, rak‘ahs, and how to offer them', () {
    final all = [
      ...salahFardPrayers,
      ...salahSunnahPrayers,
      ...salahNaflPrayers,
    ];
    final ids = <String>{};
    for (final prayer in all) {
      expect(ids.add(prayer.id), isTrue, reason: 'duplicate ${prayer.id}');
      expect(_hasArabic(prayer.arabicName), isTrue);
      expect(_hasPua(prayer.arabicName), isFalse);
      expect(prayer.englishName, isNotEmpty);
      expect(prayer.rakahsLabel, isNotEmpty);
      expect(prayer.when, isNotEmpty);
      expect(prayer.how, isNotEmpty);
    }
    expect(salahFardPrayers.map((p) => p.id), containsAll(['fajr', 'jumuah']));
    expect(salahSunnahPrayers.map((p) => p.id), contains('witr'));
  });

  test('recitations have sources and no PUA glyphs', () {
    final ids = <String>{};
    for (final recitation in salahRecitations) {
      expect(ids.add(recitation.id), isTrue);
      expect(_hasArabic(recitation.arabic), isTrue);
      expect(_hasPua(recitation.arabic), isFalse);
      expect(recitation.transliteration, isNotEmpty);
      expect(recitation.english, isNotEmpty);
      expect(recitation.source, isNotEmpty);
    }
    expect(salahRecitationById('tashahhud')?.source, contains('Bukhari 831'));
    expect(
      salahRecitationById('jalsa')?.note,
      contains('not in the two Sahihs'),
    );
  });

  test('how-to steps include takbir, Fatiha, and taslim', () {
    expect(salahHowToSteps, isNotEmpty);
    final titles = salahHowToSteps.map((s) => s.title).join(' ');
    expect(titles, contains('Takbirat'));
    expect(titles, contains('Al-Fatiha'));
    expect(titles, contains('Taslim'));
    expect(salahHowToSteps.any((s) => s.recitationId == 'takbir'), isTrue);
  });
}
