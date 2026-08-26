/// Widget tests for the salah hub and section pages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/ui/salah_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranArabicRepository.resetCache();
    QuranTranslationRepository.resetCache();
  });

  Future<void> pumpSalah(WidgetTester tester, {String? sectionId}) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: SalahPage(sectionId: sectionId)));
  }

  testWidgets('hub lists every guide section', (tester) async {
    await pumpSalah(tester);

    expect(find.text('Salah'), findsOneWidget);
    expect(find.text('The five daily prayers'), findsOneWidget);
    expect(find.text('Sunnah around the fard'), findsOneWidget);
    expect(find.text('Nawafil (extra prayers)'), findsOneWidget);
    expect(find.text('How to pray'), findsOneWidget);
    expect(find.text('What to recite'), findsOneWidget);
    expect(find.textContaining('not a fatwa'), findsOneWidget);
  });

  testWidgets('fard page lists Fajr through Isha and Jumu‘ah', (tester) async {
    await pumpSalah(tester, sectionId: 'fard');

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('Jumu‘ah (Friday)'), findsOneWidget);
    expect(find.textContaining('2 fard rak'), findsWidgets);
  });

  testWidgets('how-to page walks through a rak‘ah', (tester) async {
    await pumpSalah(tester, sectionId: 'how-to');

    expect(find.text('Takbirat al-ihram'), findsOneWidget);
    expect(find.text('Al-Fatiha'), findsOneWidget);
    expect(find.text('Taslim'), findsWidgets);
    expect(find.textContaining('Allahu Akbar'), findsWidgets);
  });

  testWidgets('recite page loads Al-Fatiha from bundled Quran text', (
    tester,
  ) async {
    await pumpSalah(tester, sectionId: 'recite');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Al-Fatiha'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('Open in reader'), findsOneWidget);
    expect(find.text('Tashahhud'), findsOneWidget);
    expect(find.textContaining('Bukhari 831'), findsOneWidget);
  });
}
