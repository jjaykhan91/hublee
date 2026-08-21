/// Widget tests for [QuranPage] tab behaviour.
///
/// The four grouping views are kept alive so that switching tabs does not
/// silently return the reader to the top of the list. That is invisible in the
/// widget tree, so it is asserted through the behaviour it exists for: scroll
/// position surviving a round trip through another tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/ui/quran_page.dart';

/// Pumps enough frames for the chapter future to resolve and the entry
/// animations to finish.
///
/// [WidgetTester.pumpAndSettle] cannot be used while loading, because the
/// progress indicator animates indefinitely and would never settle.
Future<void> _settleQuranPage(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    // Both of these cache Futures for the session, and each test runs in its
    // own fake-async zone — a Future completed in a previous test never
    // delivers in this one, leaving the page stuck on its spinner with no
    // error to explain why. rootBundle is the one that actually bites: it
    // caches asset strings independently of our repositories.
    QuranChaptersRepository.resetCache();
    rootBundle.clear();
  });

  Widget harness() => const MaterialApp(home: QuranPage());

  testWidgets('surah list scroll position survives a tab switch', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await _settleQuranPage(tester);

    expect(
      find.text('Al-Fatihah'),
      findsOneWidget,
      reason: 'the list should start at the first surah',
    );

    // Scroll the first surah out of view.
    await tester.drag(find.text('Al-Fatihah'), const Offset(0, -1500));
    await _settleQuranPage(tester);
    expect(find.text('Al-Fatihah'), findsNothing);

    await tester.tap(find.text('Juz'));
    await _settleQuranPage(tester);
    await tester.tap(find.text('Surah'));
    await _settleQuranPage(tester);

    expect(
      find.text('Al-Fatihah'),
      findsNothing,
      reason:
          'returning to the Surah tab reset the scroll position — the view '
          'is no longer kept alive',
    );
  });

  testWidgets('every grouping tab renders', (tester) async {
    await tester.pumpWidget(harness());
    await _settleQuranPage(tester);

    for (final tab in ['Juz', 'Type', 'Revelation', 'Surah']) {
      await tester.tap(find.text(tab));
      await _settleQuranPage(tester);
      expect(tester.takeException(), isNull, reason: '$tab tab threw');
    }

    // Sections that only the grouped views draw.
    await tester.tap(find.text('Type'));
    await _settleQuranPage(tester);
    expect(find.textContaining('Meccan ('), findsOneWidget);
  });
}
