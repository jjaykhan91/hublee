/// Widget tests for global search stale-query handling.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/hadith_search_service.dart';
import 'package:hublee/services/quran_search_service.dart';
import 'package:hublee/services/search_models.dart';
import 'package:hublee/ui/widgets/search_highlight.dart';
import 'package:hublee/ui/global_search_page.dart';

class _GatedQuranSearch extends QuranSearchService {
  final Map<String, Completer<List<QuranSearchHit>>> gates = {};

  @override
  Future<void> warmIndex() async {}

  @override
  Future<List<QuranSearchHit>> search(String query, {int limit = 150}) {
    return (gates[query] ??= Completer<List<QuranSearchHit>>()).future;
  }
}

class _EmptyHadithSearch extends HadithSearchService {
  @override
  Future<void> warmIndex() async {}

  @override
  Future<List<HadithSearchHit>> search(String query, {int limit = 100}) async {
    return const [];
  }
}

class _FixedQuranSearch extends QuranSearchService {
  @override
  Future<void> warmIndex() async {}

  @override
  Future<List<QuranSearchHit>> search(String query, {int limit = 150}) async {
    return const [
      QuranSearchHit(
        surahId: 2,
        ayah: 87,
        surahName: 'Al-Baqarah',
        snippet: 'We gave Jesus the Gospel',
      ),
    ];
  }
}

class _FixedHadithSearch extends HadithSearchService {
  @override
  Future<void> warmIndex() async {}

  @override
  Future<List<HadithSearchHit>> search(String query, {int limit = 100}) async {
    return const [
      HadithSearchHit(
        collectionId: 'forties',
        bookFile: 'nawawi40.json',
        bookTitle: 'Nawawi 40',
        hadithIndex: 0,
        snippet: 'Jesus son of Mary',
      ),
    ];
  }
}

void main() {
  testWidgets('late results from an older query are dropped', (tester) async {
    final quran = _GatedQuranSearch();
    final hadith = _EmptyHadithSearch();

    await tester.pumpWidget(
      MaterialApp(
        home: SearchPage(quranSearch: quran, hadithSearch: hadith),
      ),
    );

    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 300));

    quran.gates['old']!.complete([
      const QuranSearchHit(
        surahId: 1,
        ayah: 1,
        surahName: 'Al-Fatiha',
        snippet: 'old hit',
      ),
    ]);
    await tester.pump();
    expect(find.text('Al-Fatiha • Ayah 1'), findsNothing);

    quran.gates['new']!.complete([
      const QuranSearchHit(
        surahId: 2,
        ayah: 255,
        surahName: 'Al-Baqarah',
        snippet: 'new hit',
      ),
    ]);
    await tester.pump();
    expect(find.text('Al-Baqarah • Ayah 255'), findsOneWidget);
    expect(find.text('Al-Fatiha • Ayah 1'), findsNothing);
    expect(find.byType(HighlightedSnippet), findsOneWidget);
  });

  testWidgets('idle copy differs from zero hits', (tester) async {
    final quran = _GatedQuranSearch();
    final hadith = _EmptyHadithSearch();

    await tester.pumpWidget(
      MaterialApp(
        home: SearchPage(quranSearch: quran, hadithSearch: hadith),
      ),
    );

    expect(find.text('Search across Quran and Hadith'), findsOneWidget);
    expect(find.textContaining('2:255'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyzzy');
    await tester.pump(const Duration(milliseconds: 300));
    quran.gates['xyzzy']!.complete(const []);
    await tester.pump();

    expect(find.text('Search across Quran and Hadith'), findsNothing);
    expect(find.text('No verses or hadiths match “xyzzy”'), findsOneWidget);
  });

  testWidgets('Hadith chip shows hadith hits without scrolling Quran', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPage(
          quranSearch: _FixedQuranSearch(),
          hadithSearch: _FixedHadithSearch(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'jesus');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Quran (1)'), findsWidgets);
    expect(find.text('Hadith (1)'), findsWidgets);
    expect(find.text('Al-Baqarah • Ayah 87'), findsOneWidget);
    expect(find.text('Nawawi 40 • Hadith 1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Hadith (1)'));
    await tester.pump();

    expect(find.text('Al-Baqarah • Ayah 87'), findsNothing);
    expect(find.text('Nawawi 40 • Hadith 1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Quran (1)'));
    await tester.pump();

    expect(find.text('Al-Baqarah • Ayah 87'), findsOneWidget);
    expect(find.text('Nawawi 40 • Hadith 1'), findsNothing);
  });
}
