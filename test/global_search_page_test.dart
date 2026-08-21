/// Widget tests for global search stale-query handling.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/services/hadith_search_service.dart';
import 'package:hublee/services/quran_search_service.dart';
import 'package:hublee/services/search_models.dart';
import 'package:hublee/ui/global_search_page.dart';

class _GatedQuranSearch extends QuranSearchService {
  final Map<String, Completer<List<QuranSearchHit>>> gates = {};

  @override
  Future<List<QuranSearchHit>> search(String query, {int limit = 150}) {
    return (gates[query] ??= Completer<List<QuranSearchHit>>()).future;
  }
}

class _EmptyHadithSearch extends HadithSearchService {
  @override
  Future<List<HadithSearchHit>> search(String query, {int limit = 100}) async {
    return const [];
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
  });
}
