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
    expect(find.byKey(const Key('hublee-wordmark')), findsOneWidget);
    expect(find.byKey(const Key('hublee-meaning-card')), findsOneWidget);
    expect(find.textContaining('my rope'), findsWidgets);
    expect(find.textContaining('Quran and the Sunnah'), findsOneWidget);
    expect(find.text('Quran'), findsNothing);
    expect(find.text('Hadith'), findsNothing);
    expect(find.text('Continue Quran'), findsNothing);
    expect(find.text('Continue Hadith'), findsNothing);
    expect(find.byKey(const Key('home-card-allah')), findsOneWidget);
    expect(find.byKey(const Key('home-card-prophet')), findsOneWidget);
    expect(find.byKey(const Key('home-card-dhikr')), findsOneWidget);
    expect(find.byKey(const Key('home-card-salah')), findsOneWidget);
    expect(find.byKey(const Key('home-card-duas')), findsOneWidget);
    expect(find.text('Allah'), findsOneWidget);
    expect(find.text('Dhikr'), findsOneWidget);
    expect(find.text('Salah'), findsOneWidget);
    expect(find.textContaining('Duas from the Quran'), findsOneWidget);
    expect(find.text('Dhikr of the Day'), findsOneWidget);
    expect(find.byKey(const Key('dhikr-of-the-day-card')), findsOneWidget);

    // Daily cards animate on first paint; flush those timers so the
    // test binding does not fail on dispose.
    await tester.pump(const Duration(seconds: 2));
  });
}
