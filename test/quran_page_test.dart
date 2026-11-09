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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
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
    SharedPreferences.setMockInitialValues({});
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
    expect(find.byTooltip('About the Quran'), findsOneWidget);
    expect(find.byTooltip('Quran reading & Tajweed guide'), findsOneWidget);

    // Scroll the first surah out of view.
    await tester.drag(find.text('Al-Fatihah'), const Offset(0, -1500));
    await _settleQuranPage(tester);
    expect(find.text('Al-Fatihah'), findsNothing);

    await tester.tap(find.text('30 Days'));
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

    for (final tab in ['30 Days', 'Type', 'Revelation', 'Surah']) {
      await tester.tap(find.text(tab));
      await _settleQuranPage(tester);
      expect(tester.takeException(), isNull, reason: '$tab tab threw');
    }

    // Sections that only the grouped views draw.
    await tester.tap(find.text('Type'));
    await _settleQuranPage(tester);
    expect(find.textContaining('Meccan ('), findsOneWidget);
  });

  testWidgets('surah cards show reading position and bookmarks', (
    tester,
  ) async {
    final bookmarks = BookmarkService();
    await bookmarks.load();
    await bookmarks.saveLastReadQuran(
      surahId: 1,
      ayah: 5,
      surahName: 'Al-Fatihah',
    );
    await bookmarks.saveLastReadQuran(
      surahId: 2,
      ayah: 255,
      surahName: 'Al-Baqarah',
    );
    for (final ayah in [7, 3]) {
      await bookmarks.toggleBookmark(
        Bookmark.quran(surahId: 1, ayah: ayah, surahName: 'Al-Fatihah'),
      );
    }

    await tester.pumpWidget(
      BookmarkScope(
        service: bookmarks,
        child: const MaterialApp(home: QuranPage()),
      ),
    );
    await _settleQuranPage(tester);

    expect(find.text('Continue where you left off'), findsOneWidget);
    expect(find.textContaining('2:255'), findsOneWidget);
    expect(find.text('Ayah 5 / 7'), findsOneWidget);
    expect(find.text('Ayah 255 / 286'), findsOneWidget);
    expect(find.byKey(const Key('surah-progress-1')), findsOneWidget);
    expect(find.byKey(const Key('surah-bookmarks-2')), findsNothing);
    expect(find.byIcon(Icons.push_pin_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('surah-bookmarks-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Al-Fatihah · 2 bookmarks'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Ayah 3'));
    final second = tester.getTopLeft(find.text('Ayah 7'));
    expect(first.dy, lessThan(second.dy));
  });

  testWidgets('30 Days lists whole surahs by day and explains itself', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await _settleQuranPage(tester);

    await tester.tap(find.text('30 Days'));
    await _settleQuranPage(tester);

    expect(find.text('The Quran in a lunar month'), findsOneWidget);
    expect(find.text('The opening, before Day 1'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.textContaining('286 ayahs'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lunar-month-info')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Reading the Quran in a lunar month'), findsOneWidget);
    expect(find.text('Why whole surahs'), findsOneWidget);
  });

  testWidgets('about the Quran sheet opens from the app bar', (tester) async {
    await tester.pumpWidget(harness());
    await _settleQuranPage(tester);

    await tester.tap(find.byTooltip('About the Quran'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('About the Quran'), findsWidgets);
    expect(find.text('What it is'), findsOneWidget);
    expect(find.textContaining('twenty-three years'), findsOneWidget);
    expect(find.text('Names'), findsOneWidget);
  });
}
