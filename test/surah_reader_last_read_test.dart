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
import 'package:hublee/services/srs_scope.dart';
import 'package:hublee/services/srs_service.dart';
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
            child: SrsScope(
              service: SrsService(),
              child: const MaterialApp(home: SurahReaderPage(surahId: 1)),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilReaderLoaded(tester);

    expect(find.text('ClearQuran'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final last = bookmarks.lastReadQuran;
    expect(last, isNotNull);
    expect(last!['surahId'], 1);
    expect(last['ayah'], greaterThan(1));
  });
}
