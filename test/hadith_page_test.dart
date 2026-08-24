/// Tests for hadith book summary lookup and the Hadith tab list.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/hadith/hadith_book_summaries.dart';
import 'package:hublee/hadith/hadith_repository.dart';
import 'package:hublee/ui/hadith_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hadithBookSummary', () {
    test('matches Nawawi 40 by title', () {
      final summary = hadithBookSummary(
        title: 'The Forty Hadith of Imam Nawawi',
        fileBaseName: 'nawawi40',
      );
      expect(summary, isNotNull);
      expect(summary, contains('foundations of Islam'));
    });

    test('does not treat Riyad as Nawawi', () {
      final summary = hadithBookSummary(
        title: 'Riyad as-Salihin',
        fileBaseName: 'riyad_salihin',
      );
      expect(summary, contains('righteous'));
      expect(summary, isNot(contains('foundations of Islam')));
    });

    test('returns null for an unknown book', () {
      expect(
        hadithBookSummary(title: 'Unknown Collection', fileBaseName: 'other'),
        isNull,
      );
    });
  });

  group('HadithPage', () {
    setUp(() {
      rootBundle.clear();
      HadithRepository.resetCache();
    });

    testWidgets('lists collections, search, and Start here', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HadithPage()));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Forties').evaluate().isNotEmpty) break;
      }

      expect(find.text('Forties'), findsWidgets);
      expect(find.text('The Forty Hadith of Imam Nawawi'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Start here'), findsOneWidget);
      expect(find.text('Nawawi'), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byType(ListView), findsWidgets);

      await tester.enterText(find.byType(SearchBar), 'Bukhari');
      await tester.pump();
      expect(find.text('Sahih al-Bukhari'), findsOneWidget);
      expect(find.text('The Forty Hadith of Imam Nawawi'), findsNothing);
      expect(find.text('Start here'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('collection chip filters the catalog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HadithPage()));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Forties').evaluate().isNotEmpty) break;
      }

      await tester.tap(find.widgetWithText(FilterChip, 'The Nine Books'));
      await tester.pump();
      expect(find.text('Sahih al-Bukhari'), findsOneWidget);
      expect(find.text('The Forty Hadith of Imam Nawawi'), findsNothing);
      expect(find.text('Start here'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
