/// Tests for hadith book summary lookup and the Hadith tab list.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/hadith/hadith_book_summaries.dart';
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
    setUp(rootBundle.clear);

    testWidgets('lists collection headers and Nawawi 40', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HadithPage()));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Forties').evaluate().isNotEmpty) break;
      }

      expect(find.text('Forties'), findsOneWidget);
      expect(find.text('The Forty Hadith of Imam Nawawi'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
