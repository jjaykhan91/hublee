/// Catalog and daily-pick tests for everyday dhikr.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/guidance/everyday_dhikr.dart';
import 'package:hublee/services/daily_content_service.dart';
import 'package:hublee/ui/widgets/dhikr_of_the_day_card.dart';

void main() {
  test('catalog entries have Arabic, English, and a source', () {
    expect(everydayDhikrCatalog, isNotEmpty);
    final ids = <String>{};
    for (final dhikr in everydayDhikrCatalog) {
      expect(dhikr.id, isNotEmpty);
      expect(ids.add(dhikr.id), isTrue, reason: 'duplicate id ${dhikr.id}');
      expect(dhikr.arabic, isNotEmpty);
      expect(dhikr.transliteration, isNotEmpty);
      expect(dhikr.english, isNotEmpty);
      expect(dhikr.source, isNotEmpty);
      expect(
        dhikr.arabic.contains(RegExp(r'[\u0600-\u06FF]')),
        isTrue,
        reason: '${dhikr.id} should contain Arabic letters',
      );
      expect(
        dhikr.arabic.codeUnits.any((unit) => unit >= 0xE000 && unit <= 0xF8FF),
        isFalse,
        reason: '${dhikr.id} must not use KFGQPC PUA glyphs',
      );
    }
  });

  test('dhikrForDay rotates through the catalog and stays stable', () {
    final n = everydayDhikrCatalog.length;
    final seen = <String>{};
    for (var i = 0; i < n; i++) {
      seen.add(DailyContentService.dhikrForDay(i).id);
      expect(
        DailyContentService.dhikrForDay(i).id,
        DailyContentService.dhikrForDay(i + n).id,
      );
    }
    expect(seen, hasLength(n));
    expect(DailyContentService.dhikrOfTheDay().arabic, isNotEmpty);
  });

  test('Yunus and Hayyu extra wordings are not labelled Sahih Muslim', () {
    final yunus = everydayDhikrCatalog.firstWhere((d) => d.id == 'yunus');
    expect(yunus.source, contains('Quran 21:87'));
    expect(yunus.source.toLowerCase(), isNot(contains('muslim')));
    final hayyu = everydayDhikrCatalog.firstWhere(
      (d) => d.id == 'ya-hayyu-astaghith',
    );
    expect(hayyu.source.toLowerCase(), contains('tirmidhi'));
    expect(hayyu.virtue!.toLowerCase(), contains('not in the two sahihs'));
  });

  testWidgets('dhikr card opens the wording sheet', (tester) async {
    final dhikr = everydayDhikrCatalog.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DhikrOfTheDayCard(dhikr: dhikr)),
      ),
    );

    await tester.tap(find.text('Dhikr of the Day'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text(dhikr.source), findsWidgets);
    expect(find.text(dhikr.english), findsWidgets);
  });
}
