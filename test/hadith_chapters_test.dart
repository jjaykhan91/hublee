/// Tests for hadith chapter lookup and the chapter jump sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/hadith/hadith_chapters.dart';
import 'package:hublee/hadith/hadith_repository.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/services/settings_scope.dart';
import 'package:hublee/ui/hadith_chapters_page.dart';
import 'package:hublee/ui/widgets/hadith_chapter_sheet.dart';

Hadith _h({required int chapterId}) => Hadith(chapterId: chapterId);

HadithChapter _c({required int id, required String english, String? arabic}) =>
    HadithChapter(id: id, english: english, arabic: arabic);

void main() {
  final hadiths = [_h(chapterId: 1), _h(chapterId: 1), _h(chapterId: 2)];
  final chapters = [
    _c(id: 1, english: 'Revelation', arabic: 'كتاب بدء الوحى'),
    _c(id: 2, english: 'Belief'),
  ];

  test('firstHadithIndexForChapter finds the start of each chapter', () {
    expect(firstHadithIndexForChapter(hadiths, 1), 0);
    expect(firstHadithIndexForChapter(hadiths, 2), 2);
    expect(firstHadithIndexForChapter(hadiths, 99), isNull);
  });

  test('isChapterStart is true only on the first hadith of a chapter', () {
    expect(isChapterStart(hadiths, 0), isTrue);
    expect(isChapterStart(hadiths, 1), isFalse);
    expect(isChapterStart(hadiths, 2), isTrue);
  });

  test('hadithCountForChapter counts members', () {
    expect(hadithCountForChapter(hadiths, 1), 2);
    expect(hadithCountForChapter(hadiths, 2), 1);
  });

  test('hadithIndicesForChapter lists book indices in order', () {
    expect(hadithIndicesForChapter(hadiths, 1), [0, 1]);
    expect(hadithIndicesForChapter(hadiths, 2), [2]);
    expect(hadithIndicesForChapter(hadiths, null), [0, 1, 2]);
  });

  testWidgets('chapter sheet lists titles and reports the jump index', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    int? jumped;
    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: MaterialApp(
          home: Scaffold(
            body: HadithChapterSheet(
              chapters: chapters,
              hadiths: hadiths,
              onJump: (index) => jumped = index,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Revelation'), findsOneWidget);
    expect(find.text('2 hadiths'), findsOneWidget);
    expect(find.text('Belief'), findsOneWidget);

    await tester.tap(find.text('Belief'));
    await tester.pump();
    expect(jumped, 2);
  });

  testWidgets('chapter grid lists titles and reports the tap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    HadithChapter? selected;
    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: MaterialApp(
          home: Scaffold(
            body: HadithChapterGrid(
              chapters: chapters,
              hadiths: hadiths,
              onSelect: (chapter) => selected = chapter,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('hadith-chapter-grid')), findsOneWidget);
    expect(find.text('Revelation'), findsOneWidget);
    expect(find.text('2 hadiths'), findsOneWidget);
    expect(find.text('Belief'), findsOneWidget);
    expect(find.text('1 hadith'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hadith-chapter-2')));
    await tester.pump();
    expect(selected?.id, 2);
  });
}
