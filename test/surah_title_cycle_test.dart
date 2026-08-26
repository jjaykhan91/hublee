/// Unit and widget tests for cycling the reader surah title.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/models.dart';
import 'package:hublee/quran/surah_title_cycle.dart';
import 'package:hublee/ui/widgets/surah_app_bar_title.dart';

const _fatiha = ChapterMeta(
  id: 1,
  nameSimple: 'Al-Fatiha',
  nameTranslated: 'The Opener',
  nameArabic: 'الفاتحة',
  versesCount: 7,
  revelationType: 'Meccan',
);

const _baqarah = ChapterMeta(
  id: 2,
  nameSimple: 'Al-Baqarah',
  nameTranslated: 'The Cow',
  nameArabic: 'البقرة',
  versesCount: 286,
  revelationType: 'Medinan',
);

void main() {
  test('cycle order is Arabic, English, meaning, city', () {
    expect(SurahTitleCycle.arabic.next, SurahTitleCycle.english);
    expect(SurahTitleCycle.english.next, SurahTitleCycle.meaning);
    expect(SurahTitleCycle.meaning.next, SurahTitleCycle.revelationCity);
    expect(SurahTitleCycle.revelationCity.next, SurahTitleCycle.arabic);
  });

  test('display text matches the chapter', () {
    expect(SurahTitleCycle.arabic.displayText(_fatiha), isNull);
    expect(SurahTitleCycle.english.displayText(_fatiha), 'Al-Fatiha');
    expect(SurahTitleCycle.meaning.displayText(_fatiha), 'The Opener');
    expect(SurahTitleCycle.revelationCity.displayText(_fatiha), 'Mecca');
    expect(SurahTitleCycle.revelationCity.displayText(_baqarah), 'Medina');
    expect(surahNameLigature(1), 'surah001');
    expect(surahNameLigature(114), 'surah114');
  });

  test('meaning falls back to the English name when missing', () {
    const nameless = ChapterMeta(
      id: 1,
      nameSimple: 'Al-Fatiha',
      nameArabic: 'الفاتحة',
      versesCount: 7,
    );
    expect(SurahTitleCycle.meaning.displayText(nameless), 'Al-Fatiha');
  });

  testWidgets('tapping the app-bar title cycles all four labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const SurahAppBarTitle(chapter: _fatiha)),
        ),
      ),
    );

    expect(find.text('surah001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surah-app-bar-title')));
    await tester.pump();
    expect(find.text('Al-Fatiha'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surah-app-bar-title')));
    await tester.pump();
    expect(find.text('The Opener'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surah-app-bar-title')));
    await tester.pump();
    expect(find.text('Mecca'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surah-app-bar-title')));
    await tester.pump();
    expect(find.text('surah001'), findsOneWidget);
  });
}
