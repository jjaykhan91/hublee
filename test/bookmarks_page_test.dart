/// Widget tests for [BookmarksPage] empty-state copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
import 'package:hublee/services/vocab_scope.dart';
import 'package:hublee/services/vocab_service.dart';
import 'package:hublee/ui/bookmarks_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget harness({BookmarkService? bookmarks, VocabService? vocab}) {
    return VocabScope(
      service: vocab ?? VocabService(),
      child: BookmarkScope(
        service: bookmarks ?? BookmarkService(),
        child: const MaterialApp(home: BookmarksPage()),
      ),
    );
  }

  testWidgets('empty state tells the reader to use the bookmark icon', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.text('No favorite ayahs yet'), findsOneWidget);
    expect(
      find.text('Tap the bookmark icon on any ayah or hadith to save it'),
      findsOneWidget,
    );
    expect(find.textContaining('Long-press'), findsNothing);
  });

  testWidgets('removing a bookmark offers undo that restores it', (
    tester,
  ) async {
    final service = BookmarkService();
    await service.toggleBookmark(
      Bookmark.quran(
        surahId: 1,
        ayah: 1,
        surahName: 'Al-Fatihah',
        snippet: 'In the name of Allah',
      ),
    );

    await tester.pumpWidget(harness(bookmarks: service));
    await tester.pump();
    expect(find.textContaining('Al-Fatihah'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Bookmark removed'), findsOneWidget);
    expect(find.textContaining('Al-Fatihah'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Al-Fatihah'), findsOneWidget);
  });
}
