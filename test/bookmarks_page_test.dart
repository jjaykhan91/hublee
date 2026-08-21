/// Widget tests for [BookmarksPage] empty-state copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
import 'package:hublee/ui/bookmarks_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty state tells the reader to use the bookmark icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      BookmarkScope(
        service: BookmarkService(),
        child: const MaterialApp(home: BookmarksPage()),
      ),
    );

    expect(find.text('No bookmarks yet'), findsOneWidget);
    expect(
      find.text('Tap the bookmark icon on any ayah or hadith to save it'),
      findsOneWidget,
    );
    expect(find.textContaining('Long-press'), findsNothing);
  });
}
