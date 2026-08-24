/// Widget tests for [HomePage] daily-card loading placeholders.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/hadith/hadith_repository.dart';
import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/services/bookmark_scope.dart';
import 'package:hublee/services/bookmark_service.dart';
import 'package:hublee/services/daily_content_service.dart';
import 'package:hublee/ui/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DailyContentService.resetCache();
    HadithRepository.resetCache();
    QuranTranslationRepository.resetCache();
    QuranArabicRepository.resetCache();
    rootBundle.clear();
  });

  Widget harness() => BookmarkScope(
    service: BookmarkService(),
    child: const MaterialApp(home: HomePage()),
  );

  testWidgets('daily cards reserve space while loading', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('verse-of-the-day-skeleton')), findsOneWidget);
    expect(find.byKey(const Key('hadith-of-the-day-skeleton')), findsOneWidget);
    expect(find.text('Ayah of the Day'), findsNothing);

    // Daily cards animate on first paint; flush those timers so the
    // test binding does not fail on dispose.
    await tester.pump(const Duration(seconds: 2));
  });
}
