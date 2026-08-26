/// Widget test that scrolling the surah reader persists last-read ayah.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_chapters_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/quran/word_by_word_repository.dart';
import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
import 'package:hublee/services/settings_controller.dart';
import 'package:hublee/services/settings_scope.dart';
import 'package:hublee/services/vocab_scope.dart';
import 'package:hublee/services/vocab_service.dart';
import 'package:hublee/ui/surah_reader_page.dart';

Future<void> _pumpUntilReaderLoaded(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
  fail('surah reader stayed on its loading spinner');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranChaptersRepository.resetCache();
    QuranArabicRepository.resetCache();
    QuranTranslationRepository.resetCache();
    WordByWordRepository.resetCache();
    rootBundle.clear();
  });

  testWidgets('scrolling updates last-read ayah after the debounce', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bookmarks = BookmarkService();
    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: BookmarkScope(
          service: bookmarks,
          child: VocabScope(
            service: VocabService(),
            child: const MaterialApp(home: SurahReaderPage(surahId: 1)),
          ),
        ),
      ),
    );
    await _pumpUntilReaderLoaded(tester);

    expect(find.text('ClearQuran'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('surah-details-header')),
      const Offset(0, -1200),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final last = bookmarks.lastReadQuran;
    expect(last, isNotNull);
    expect(last!['surahId'], 1);
    expect(last['ayah'], greaterThan(1));
  });

  testWidgets('compact phone width does not overflow the app bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(410, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: BookmarkScope(
          service: BookmarkService(),
          child: VocabScope(
            service: VocabService(),
            child: const MaterialApp(home: SurahReaderPage(surahId: 1)),
          ),
        ),
      ),
    );
    await _pumpUntilReaderLoaded(tester);

    expect(find.byTooltip('Surah info'), findsNothing);
    expect(find.byKey(const Key('surah-header-info')), findsOneWidget);
    expect(find.byTooltip('More'), findsNothing);
    expect(find.byTooltip('Quran reading & Tajweed guide'), findsNothing);
    expect(find.byKey(const Key('surah-details-header')), findsOneWidget);
    expect(find.textContaining('Surah Al-Fatihah'), findsWidgets);
    expect(find.text('Meccan'), findsOneWidget);
  });

  testWidgets('pinning an ayah stores a per-surah resume marker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bookmarks = BookmarkService();
    await tester.pumpWidget(
      SettingsScope(
        controller: SettingsController(),
        child: BookmarkScope(
          service: bookmarks,
          child: VocabScope(
            service: VocabService(),
            child: const MaterialApp(home: SurahReaderPage(surahId: 1)),
          ),
        ),
      ),
    );
    await _pumpUntilReaderLoaded(tester);

    final pinFinder = find.byKey(const Key('ayah-pin-1-1'));
    await tester.ensureVisible(pinFinder);
    await tester.tap(pinFinder);
    await tester.pump();
    expect(find.text('Pinned 1:1'), findsOneWidget);
    expect(bookmarks.isAyahPinned(1, 1), isTrue);
  });
}
