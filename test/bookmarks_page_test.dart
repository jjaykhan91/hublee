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

    expect(find.text('No saved ayahs yet'), findsOneWidget);
    expect(
      find.text('Tap the bookmark icon on any ayah to save it here'),
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

  testWidgets('Notes lists ayah and hadith notes and edits one', (
    tester,
  ) async {
    final service = BookmarkService();
    await service.saveNote(
      target: Bookmark.quran(surahId: 2, ayah: 255, surahName: 'Al-Baqarah'),
      text: 'Ayat al-Kursi before sleep',
    );
    await service.saveNote(
      target: Bookmark.hadith(
        collectionId: 'forties',
        bookFile: 'nawawi40.json',
        bookTitle: 'Nawawi 40',
        hadithIndex: 0,
        idInBook: 1,
      ),
      text: 'Intentions first',
    );

    await tester.pumpWidget(harness(bookmarks: service));
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Al-Baqarah 2:255'), findsOneWidget);
    expect(find.text('Ayat al-Kursi before sleep'), findsOneWidget);
    expect(find.text('Nawawi 40 · #1'), findsOneWidget);
    expect(find.text('Intentions first'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('saved-hadith:forties:nawawi40.json:0')),
        matching: find.byTooltip('Edit note'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-field')), 'Niyyah');
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle();

    expect(find.text('Niyyah'), findsOneWidget);
    expect(find.text('Intentions first'), findsNothing);
  });

  testWidgets('Notes empty state points to the note icon', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
  });
}
