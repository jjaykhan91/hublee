/// Tests for daily verse sharing the mushaf decode with search.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hublee/quran/quran_arabic_repository.dart';
import 'package:hublee/quran/quran_translation_repository.dart';
import 'package:hublee/services/daily_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DailyContentService.resetCache();
    QuranArabicRepository.resetCache();
    QuranTranslationRepository.resetCache();
  });

  test('verse of the day loads through QuranArabicRepository', () async {
    final verse = await DailyContentService.loadVerseOfTheDay();
    expect(verse.surahId, inInclusiveRange(1, 114));
    expect(verse.ayah, greaterThan(0));
    expect(verse.arabic, isNotEmpty);
    expect(verse.english, isNotEmpty);

    final cached = await DailyContentService.loadVerseOfTheDay();
    expect(cached.surahId, verse.surahId);
    expect(cached.ayah, verse.ayah);
  });
}
